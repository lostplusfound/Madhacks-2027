"""Download and convert a bounded CubiCasa5K subset without fetching the full ZIP."""

import argparse
import hashlib
import io
import json
import math
import random
import re
import shutil
import sys
import xml.etree.ElementTree as ET
import zlib
from collections import Counter
from pathlib import Path, PurePosixPath
from zipfile import ZipFile

import requests
from PIL import Image, ImageDraw
from requests.adapters import HTTPAdapter
from shapely import set_precision
from shapely.geometry import Polygon, box
from shapely.ops import triangulate, unary_union
from urllib3.util.retry import Retry

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from madmaps_extraction.contract import validate

ARCHIVE_URL = "https://zenodo.org/api/records/2613548/files/cubicasa5k.zip/content"
ARCHIVE_SIZE = 5469495706
CONVERTER = "cubicasa5k-svg-v1"
IDENTITY = (1, 0, 0, 1, 0, 0)
NUMBER = r"[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?"
NS = "{http://www.w3.org/2000/svg}"
NON_WALKABLE = {
    "Outdoor",
    "OpenToBelow",
    "Below150cm",
    "SwimmingPool",
    "Wall",
    "Undefined",
}
CATEGORIES = {
    "Bath": "bathroom",
    "Bathroom": "bathroom",
    "Toilet": "bathroom",
    "Office": "office",
    "Kitchen": "food",
    "Dining": "food",
    "Elevator": "elevator",
    "StairWell": "stairs",
    "Library": "studySpace",
}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, allow_nan=False) + "\n")


def multiply(a, b):
    """SVG affine composition a @ b, in SVG's six-number convention."""
    return (
        a[0] * b[0] + a[2] * b[1],
        a[1] * b[0] + a[3] * b[1],
        a[0] * b[2] + a[2] * b[3],
        a[1] * b[2] + a[3] * b[3],
        a[0] * b[4] + a[2] * b[5] + a[4],
        a[1] * b[4] + a[3] * b[5] + a[5],
    )


def transform(value):
    result = IDENTITY
    if not value:
        return result
    pattern = r"([A-Za-z]+)\s*\(([^)]*)\)"
    if re.sub(pattern, "", value).strip(" ,\t\n"):
        raise ValueError("Unsupported SVG transform syntax")
    for name, text in re.findall(pattern, value):
        numbers = [float(n) for n in re.findall(NUMBER, text)]
        if name == "matrix" and len(numbers) == 6:
            part = tuple(numbers)
        elif name == "translate" and 1 <= len(numbers) <= 2:
            part = (1, 0, 0, 1, numbers[0], numbers[1] if len(numbers) == 2 else 0)
        elif name == "scale" and 1 <= len(numbers) <= 2:
            part = (numbers[0], 0, 0, numbers[-1], 0, 0)
        elif name == "rotate" and len(numbers) in {1, 3}:
            theta = math.radians(numbers[0])
            part = (
                math.cos(theta),
                math.sin(theta),
                -math.sin(theta),
                math.cos(theta),
                0,
                0,
            )
            if len(numbers) == 3:
                x, y = numbers[1:]
                part = multiply(
                    multiply((1, 0, 0, 1, x, y), part), (1, 0, 0, 1, -x, -y)
                )
        elif name in {"skewX", "skewY"} and len(numbers) == 1:
            tangent = math.tan(math.radians(numbers[0]))
            part = (
                (1, 0, tangent, 1, 0, 0)
                if name == "skewX"
                else (1, tangent, 0, 1, 0, 0)
            )
        else:
            raise ValueError(f"Unsupported SVG transform: {name}")
        result = multiply(result, part)
    return result


def polygon_for(element, parent_matrix, bounds):
    direct = [n for n in element if n.tag == NS + "polygon"]
    if len(direct) != 1:
        raise ValueError("Annotation must have exactly one direct polygon")
    node = direct[0]
    values = [float(n) for n in re.findall(NUMBER, node.get("points", ""))]
    if len(values) < 6 or len(values) % 2:
        raise ValueError("Malformed SVG polygon")
    a, b, c, d, e, f = multiply(parent_matrix, transform(node.get("transform")))
    shape = Polygon(
        [
            (a * x + c * y + e, b * x + d * y + f)
            for x, y in zip(values[::2], values[1::2])
        ]
    )
    if not shape.is_valid or shape.area <= 0:
        raise ValueError("Invalid source polygon")
    if not bounds.buffer(2).covers(shape):
        raise ValueError("Source polygon exceeds image bounds by more than 2 pixels")
    shape = set_precision(shape.intersection(bounds), 0.01)
    if shape.geom_type != "Polygon" or shape.is_empty:
        raise ValueError("Source polygon collapsed after clipping")
    return shape


def simple_polygons(shape):
    """Represent holes with exact polygon pieces, never by filling them in."""
    if shape.is_empty:
        return []
    if shape.geom_type == "Polygon":
        if not shape.interiors:
            return [shape] if shape.area > 0 else []
        pieces = []
        for triangle in triangulate(shape):
            part = set_precision(triangle.intersection(shape), 0.01)
            if part.geom_type == "Polygon" and part.interiors:
                raise ValueError(
                    "Could not split polygon holes without changing geometry"
                )
            pieces.extend(simple_polygons(part))
        if not math.isclose(sum(p.area for p in pieces), shape.area, abs_tol=0.1):
            raise ValueError("Hole decomposition changed polygon area")
        return pieces
    if hasattr(shape, "geoms"):
        return [part for item in shape.geoms for part in simple_polygons(item)]
    return []


def area_rows(shapes, prefix):
    return [
        {
            "id": f"{prefix}-{i}",
            "polygon": [
                [round(x, 2), round(y, 2)] for x, y in shape.exterior.coords[:-1]
            ],
            "confidence": 1.0,
        }
        for i, shape in enumerate(shapes)
    ]


def convert(svg_bytes, image_size):
    """Convert public geometry; labels are semantic classes, not OCR transcripts."""
    if b"<!DOCTYPE" in svg_bytes.upper() or b"<!ENTITY" in svg_bytes.upper():
        raise ValueError("SVG entities are unsupported")
    root = ET.fromstring(svg_bytes)
    width, height = image_size
    viewport = [float(n) for n in re.findall(NUMBER, root.get("viewBox", ""))]
    if len(viewport) != 4 or viewport[2] <= 0 or viewport[3] <= 0:
        raise ValueError("SVG needs a valid viewBox")
    # The publisher's House loader rasterizes SVG numbers directly into the
    # F1_scaled.png frame. SVG canvas dimensions often omit raster margins;
    # stretching the viewBox to the PNG would misalign walls and doorways.
    if viewport[:2] != [0, 0]:
        raise ValueError("Unsupported nonzero CubiCasa SVG origin")
    frame = IDENTITY
    bounds = box(0, 0, width, height)
    parents = {child: parent for parent in root.iter() for child in parent}

    def matrix_for(node):
        chain = []
        while node is not None:
            chain.append(node)
            node = parents.get(node)
        matrix = frame
        for parent in reversed(chain):
            matrix = multiply(matrix, transform(parent.get("transform")))
        return matrix

    floors = [n for n in root.iter() if "Floorplan" in n.get("class", "").split()]
    if len(floors) != 1:
        raise ValueError("Expected exactly one annotated floor")
    spaces, structural, openings = [], [], []
    labels = Counter()
    for node in root.iter(NS + "g"):
        classes = node.get("class", "").split()
        kind = node.get("id")
        if "Space" in classes:
            index = classes.index("Space")
            if index + 1 >= len(classes):
                raise ValueError("Space has no semantic class")
            label = classes[index + 1]
            spaces.append((label, polygon_for(node, matrix_for(node), bounds)))
            labels[label] += 1
        elif kind in {"Wall", "Railing", "Column"}:
            structural.append(polygon_for(node, matrix_for(node), bounds))
        elif kind == "Door":
            openings.append(polygon_for(node, matrix_for(node), bounds))
    if len(spaces) < 2 or not structural or not openings:
        raise ValueError("Trial requires at least two spaces, a wall and a door")
    doors = []
    adjacency = []
    for index, opening in enumerate(openings):
        # Link only annotated spaces touching the opening; never choose an arbitrary nearest room.
        linked = [
            i for i, (_, shape) in enumerate(spaces) if shape.distance(opening) <= 2
        ]
        if not 1 <= len(linked) <= 2:
            raise ValueError(
                "Door does not have one or two unambiguous adjacent spaces"
            )
        center = opening.centroid
        if not bounds.contains(center):
            raise ValueError("Door center lies on image boundary")
        for room in linked:
            doors.append(
                {
                    "id": f"door-{index}-room-{room}",
                    "room_id": f"room-{room}",
                    "point": [round(center.x, 2), round(center.y, 2)],
                    "confidence": 1.0,
                }
            )
        adjacency.append({"opening": index, "rooms": linked})
    openings_shape = unary_union(openings)
    solid = set_precision(unary_union(structural).difference(openings_shape), 0.01)
    walkable = set_precision(
        unary_union(
            [shape for label, shape in spaces if label not in NON_WALKABLE]
        ).difference(solid),
        0.01,
    )
    target = {
        "schema_version": 1,
        "width": width,
        "height": height,
        "coordinate_origin": "top-left",
        "coordinate_units": "pixels",
        "rooms": [
            {
                "id": f"room-{i}",
                "label": re.sub(r"(?<=[a-z])(?=[A-Z])", " ", label),
                "category": CATEGORIES.get(label, "other"),
                "bbox": list(shape.bounds),
                "confidence": 1.0,
            }
            for i, (label, shape) in enumerate(spaces)
        ],
        "walls": area_rows(simple_polygons(solid), "wall"),
        "doors": doors,
        "walkable_areas": area_rows(simple_polygons(walkable), "walkable"),
    }
    validate(target, {"width": width, "height": height})
    if not target["walls"] or not target["walkable_areas"]:
        raise ValueError("Converted trial has no walls or interior space")
    return target, {
        "space_classes": dict(labels),
        "source_openings": len(openings),
        "door_adjacency": adjacency,
    }


class RangeReader(io.RawIOBase):
    """Seekable public HTTP ZIP reader; refuse servers that ignore byte ranges."""

    def __init__(self, url=ARCHIVE_URL, size=ARCHIVE_SIZE):
        self.url, self.size, self.position = url, size, 0
        self.downloaded_bytes = 0
        self.cache_start, self.cache = 0, b""
        self.session = requests.Session()
        self.session.mount(
            "https://",
            HTTPAdapter(
                max_retries=Retry(
                    total=3,
                    backoff_factor=1,
                    status_forcelist=[429, 500, 502, 503, 504],
                )
            ),
        )

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        position = offset + (
            0 if whence == 0 else self.position if whence == 1 else self.size
        )
        if position < 0:
            raise ValueError("Negative ZIP offset")
        self.position = position
        return position

    def read(self, size=-1):
        size = (
            self.size - self.position
            if size < 0
            else min(size, self.size - self.position)
        )
        if size <= 0:
            return b""
        if size > 64 * 1024 * 1024:
            raise ValueError("Refusing an unbounded public ZIP read")
        start = self.position
        if not (
            self.cache_start <= start
            and start + size <= self.cache_start + len(self.cache)
        ):
            end = min(self.size - 1, start + max(size, 256 * 1024) - 1)
            with self.session.get(
                self.url,
                params={"madmaps_range": f"{start}-{end}"},
                headers={
                    "Range": f"bytes={start}-{end}",
                    "Accept-Encoding": "identity",
                },
                timeout=(15, 60),
                stream=True,
            ) as response:
                response.raise_for_status()
                expected = f"bytes {start}-{end}/{self.size}"
                if (
                    response.status_code != 206
                    or response.headers.get("Content-Range") != expected
                ):
                    raise ValueError(
                        "Dataset server did not honor the requested byte range"
                    )
                data = response.raw.read(end - start + 2, decode_content=False)
                if len(data) != end - start + 1:
                    raise ValueError("Truncated dataset byte range")
            self.cache_start, self.cache = start, data
            self.downloaded_bytes += len(data)
        self.position += size
        offset = start - self.cache_start
        return self.cache[offset : offset + size]

    def close(self):
        self.session.close()
        super().close()


def overlay(image_path, target, output):
    with Image.open(image_path) as source:
        image = source.convert("RGBA")
    layer = Image.new("RGBA", image.size)
    draw = ImageDraw.Draw(layer)
    for area in target["walkable_areas"]:
        draw.polygon([tuple(p) for p in area["polygon"]], fill=(20, 180, 80, 45))
    for area in target["walls"]:
        draw.polygon([tuple(p) for p in area["polygon"]], fill=(230, 35, 40, 125))
    for room in target["rooms"]:
        draw.rectangle(room["bbox"], outline=(30, 90, 250, 230), width=2)
        draw.text(tuple(room["bbox"][:2]), room["label"], fill=(0, 40, 180, 255))
    for door in target["doors"]:
        x, y = door["point"]
        draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(255, 140, 0, 255))
    Image.alpha_composite(image, layer).convert("RGB").save(output)


def contact_sheet(root, records):
    selected = [
        row
        for split in ("train", "validation", "test")
        for row in [r for r in records if r["split"] == split][:4]
    ]
    sheet = Image.new("RGB", (4 * 360, math.ceil(len(selected) / 4) * 300), "#eeeeee")
    draw = ImageDraw.Draw(sheet)
    for index, row in enumerate(selected):
        x, y = (index % 4) * 360, (index // 4) * 300
        with Image.open(root / row["overlay"]) as source:
            thumbnail = source.convert("RGB")
            thumbnail.thumbnail((350, 270))
            sheet.paste(thumbnail, (x + (360 - thumbnail.width) // 2, y + 25))
        draw.text((x + 5, y + 6), f"{row['split']}: {row['source_plan']}", fill="black")
    sheet.save(root / "preview.jpg", quality=92)


LIMITATIONS = [
    "Experimental automatic conversion; no MadMaps human review has been performed.",
    "Room labels are source semantic classes, not verified text transcriptions.",
    "Source-plan IDs and official dataset splits are preserved; building-level independence is not established by the source metadata.",
    "Walkable areas are indoor space footprints minus annotated structural obstacles; furniture, clearances, accessibility and actual traversability are not certified.",
    "Door footprints are subtracted from structural polygons; each source opening is linked to one or two touching annotated spaces within 2 pixels.",
    "Source SVG coordinates are used directly in F1_scaled.png, following the publisher's loader; the SVG canvas is not stretched to the raster. Geometry is quantized to 0.01 pixels; only up to 2 pixels of boundary overflow is clipped.",
    "Unsupported, invalid, ambiguous, duplicate and overly complex plans are excluded and retained in the rejection ledger; this subset is biased toward convertible plans.",
    "This residential dataset does not establish campus navigation accuracy. No graph or scale calibration is supplied.",
    "ZIP member CRCs and per-file SHA-256 are verified/recorded; the complete archive MD5 cannot be verified with a partial download.",
]


def validate_subset(root):
    manifest = json.loads((root / "manifest.json").read_text())
    seen_ids, seen_images, seen_pixels, seen_sources = set(), set(), set(), set()
    counts = Counter()
    features = Counter()
    for row in manifest["examples"]:
        if (
            row.get("reviewed") is not False
            or row["annotation_provenance"]["converter"] != CONVERTER
        ):
            raise ValueError(
                "Public annotations must be explicitly marked as unreviewed conversions"
            )
        paths = {}
        for key in ("image", "target", "source_annotation"):
            path = (root / row[key]).resolve()
            if not path.is_relative_to(root.resolve()):
                raise ValueError("Dataset path escapes root")
            paths[key] = path
        if sha256(paths["image"].read_bytes()) != row["image_sha256"]:
            raise ValueError("Image checksum mismatch")
        if sha256(paths["target"].read_bytes()) != row["target_sha256"]:
            raise ValueError("Target checksum mismatch")
        if sha256(paths["source_annotation"].read_bytes()) != row["source_sha256"]:
            raise ValueError("Source annotation checksum mismatch")
        with Image.open(paths["image"]) as image:
            pixel_hash = sha256(image.convert("RGB").tobytes())
            target = validate(
                json.loads(paths["target"].read_text()),
                {"width": image.width, "height": image.height},
            )
        if pixel_hash != row["image_pixel_sha256"]:
            raise ValueError("Pixel checksum mismatch")
        for seen, key in (
            (seen_ids, row["group"]),
            (seen_images, row["image_sha256"]),
            (seen_pixels, pixel_hash),
            (seen_sources, row["source_sha256"]),
        ):
            if key in seen:
                raise ValueError("Duplicate plan/image/annotation in prepared subset")
            seen.add(key)
        counts[row["split"]] += 1
        for key in ("rooms", "walls", "doors", "walkable_areas"):
            features[key] += len(target[key])
    if any(counts[split] == 0 for split in ("train", "validation", "test")):
        raise ValueError("All three official splits must have accepted examples")
    return {
        "valid": True,
        "examples": sum(counts.values()),
        "splits": dict(counts),
        "features": dict(features),
        "manually_reviewed_examples": 0,
    }


def prepare(args):
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=False)
    (output / "examples").mkdir()
    (output / "source_splits").mkdir()
    records, rejected = [], []
    metadata = requests.get("https://zenodo.org/api/records/2613548", timeout=(15, 60))
    metadata.raise_for_status()
    write_json(output / "zenodo-record.json", metadata.json())
    expected_archive = metadata.json()["files"][0]
    if (
        expected_archive["size"] != ARCHIVE_SIZE
        or expected_archive["checksum"] != "md5:0ce0b203d1e3c125b51087b219bd23b9"
    ):
        raise ValueError(
            "Publisher archive metadata changed; inspect it before proceeding"
        )
    write_json(
        output / "provenance.json",
        {
            "dataset": "CubiCasa5K",
            "version": "1.0",
            "doi": "10.5281/zenodo.2613548",
            "creators": metadata.json()["metadata"]["creators"],
            "download_url": ARCHIVE_URL,
            "archive_bytes": ARCHIVE_SIZE,
            "published_archive_md5": "0ce0b203d1e3c125b51087b219bd23b9",
            "whole_archive_checksum_verified": False,
            "zenodo_license": metadata.json()["metadata"]["license"]["id"],
            "repository_license": "CC-BY-NC-4.0",
            "repository_license_url": "https://github.com/CubiCasa/CubiCasa5k/blob/master/LICENSE",
            "subset_terms": "CC-BY-NC-SA-4.0; preserve both publisher notices",
            "converter": CONVERTER,
            "converter_sha256": sha256(Path(__file__).read_bytes()),
            "seed": args.seed,
            "max_target_characters": args.max_target_chars,
            "limitations": LIMITATIONS,
        },
    )
    (output / "LICENSE-NOTICE.txt").write_text(
        "CubiCasa5K v1.0, Ahti Kalervo, Juha Ylioinas, Markus Haikio, Antti Karhu, Juho Kannala (2019).\n"
        "Source: https://doi.org/10.5281/zenodo.2613548\n"
        "Zenodo dataset metadata: CC BY-NC-SA 4.0, https://creativecommons.org/licenses/by-nc-sa/4.0/\n"
        "Publisher repository: CC BY-NC 4.0, https://github.com/CubiCasa/CubiCasa5k/blob/master/LICENSE\n"
        "This automatically converted noncommercial experimental subset retains both notices and uses CC BY-NC-SA 4.0 terms.\n"
        "Changes: selected plans, converted SVG geometry to MadMaps JSON, generated overlays and manifests. Original scaled PNG/SVG files are unchanged.\n"
    )
    wanted = {"train": args.train, "validation": args.validation, "test": args.test}
    split_files = {"train": "train", "validation": "val", "test": "test"}
    seen = {key: set() for key in ("plan", "image", "pixels", "annotation")}
    shutil.copyfile(Path(__file__), output / "converter-source.py")
    with (
        Path(args.archive).open("rb") if args.archive else RangeReader() as reader,
        ZipFile(reader) as archive,
    ):
        members = set(archive.namelist())
        split_paths, official_plan_ids = {}, {}
        for split, source_split in split_files.items():
            data = archive.read(f"cubicasa5k/{source_split}.txt")
            (output / "source_splits" / f"{source_split}.txt").write_bytes(data)
            split_paths[split] = [
                line.strip().strip("/")
                for line in data.decode().splitlines()
                if line.strip()
            ]
            for relative in split_paths[split]:
                path = PurePosixPath(relative)
                if path.is_absolute() or ".." in path.parts or len(path.parts) != 2:
                    raise ValueError("Unsafe dataset split path")
                plan_id = path.name
                if plan_id in official_plan_ids and official_plan_ids[plan_id] != split:
                    raise ValueError(
                        "Official dataset has source-plan leakage across splits"
                    )
                official_plan_ids[plan_id] = split
        for split, requested in wanted.items():
            candidates = split_paths[split].copy()
            random.Random(f"{args.seed}:{split}").shuffle(candidates)
            accepted = 0
            for relative in candidates:
                if accepted >= requested:
                    break
                folder = "cubicasa5k/" + relative
                sample_id = relative.replace("/", "-")
                destination = output / "examples" / sample_id
                destination.mkdir(exist_ok=False)
                try:
                    required = [folder + "/F1_scaled.png", folder + "/model.svg"]
                    if not all(name in members for name in required):
                        raise ValueError("Plan is missing scaled PNG or SVG annotation")
                    for name, filename in zip(required, ("image.png", "model.svg")):
                        info = archive.getinfo(name)
                        if info.file_size > 32 * 1024 * 1024:
                            raise ValueError("Unexpectedly large dataset member")
                        cached = (
                            Path(args.cache) / "examples" / sample_id / filename
                            if args.cache
                            else None
                        )
                        data = (
                            cached.read_bytes()
                            if cached and cached.is_file()
                            else archive.read(name)
                        )
                        if len(data) != info.file_size or zlib.crc32(data) != info.CRC:
                            raise ValueError("Public ZIP member CRC mismatch")
                        (destination / filename).write_bytes(data)
                    image_data = (destination / "image.png").read_bytes()
                    svg_data = (destination / "model.svg").read_bytes()
                    with Image.open(io.BytesIO(image_data)) as image:
                        dimensions = image.size
                        pixel_hash = sha256(image.convert("RGB").tobytes())
                    fingerprints = {
                        "plan": PurePosixPath(relative).name,
                        "image": sha256(image_data),
                        "pixels": pixel_hash,
                        "annotation": sha256(svg_data),
                    }
                    if any(value in seen[key] for key, value in fingerprints.items()):
                        raise ValueError("Duplicate source plan, annotation or image")
                    target, notes = convert(svg_data, dimensions)
                    target_text = json.dumps(
                        target, separators=(",", ":"), allow_nan=False
                    )
                    if len(target_text) > args.max_target_chars:
                        raise ValueError("Target exceeds bounded trial complexity")
                    (destination / "target.json").write_text(target_text + "\n")
                    write_json(destination / "conversion.json", notes)
                    overlay(
                        destination / "image.png", target, destination / "overlay.png"
                    )
                    prefix = destination.relative_to(output).as_posix()
                    row = {
                        "id": sample_id,
                        "image": prefix + "/image.png",
                        "target": prefix + "/target.json",
                        "source_annotation": prefix + "/model.svg",
                        "overlay": prefix + "/overlay.png",
                        "split": split,
                        "group": "cubicasa5k-plan-" + fingerprints["plan"],
                        "source_plan": relative,
                        "source_sha256": fingerprints["annotation"],
                        "image_sha256": fingerprints["image"],
                        "image_pixel_sha256": pixel_hash,
                        "target_sha256": sha256(
                            (destination / "target.json").read_bytes()
                        ),
                        "reviewed": False,
                        "synthetic": False,
                        "annotation_provenance": {
                            "kind": "public_dataset",
                            "dataset": "CubiCasa5K",
                            "converter": CONVERTER,
                            "source_url": "https://doi.org/10.5281/zenodo.2613548",
                            "license": "CC-BY-NC-SA-4.0",
                            "original_split": source_split,
                        },
                    }
                    for key, value in fingerprints.items():
                        seen[key].add(value)
                    records.append(row)
                    accepted += 1
                    print(f"{split}: {accepted}/{requested} {relative}", flush=True)
                except (ValueError, ET.ParseError) as error:
                    rejected.append(
                        {
                            "source_plan": relative,
                            "split": split,
                            "reason": str(error),
                            "raw_directory": destination.relative_to(output).as_posix(),
                        }
                    )
                    print(f"skip {relative}: {error}", flush=True)
                write_json(
                    output / "manifest.json",
                    {
                        "schema_version": 1,
                        "annotation_policy": "public_dataset_auto_conversion",
                        "examples": records,
                    },
                )
                write_json(output / "rejections.json", rejected)
            if accepted != requested:
                raise ValueError(f"Not enough convertible examples in {split}")
        downloaded = getattr(reader, "downloaded_bytes", None)
    report = validate_subset(output)
    report.update(
        rejected_examples=len(rejected),
        rejection_reasons=dict(Counter(row["reason"] for row in rejected)),
        downloaded_bytes=downloaded,
        manifest_sha256=sha256((output / "manifest.json").read_bytes()),
        limitations=LIMITATIONS,
    )
    write_json(output / "validation.json", report)
    contact_sheet(output, records)
    # Keep review overlays portable; exclude raw rejected candidates.
    with ZipFile(output / "madmaps-public-dataset.zip", "w", compression=8) as archive:
        for name in (
            "manifest.json",
            "provenance.json",
            "zenodo-record.json",
            "LICENSE-NOTICE.txt",
            "validation.json",
            "rejections.json",
            "converter-source.py",
            "preview.jpg",
        ):
            archive.write(output / name, name)
        for path in sorted((output / "source_splits").glob("*.txt")):
            archive.write(path, path.relative_to(output))
        for row in records:
            for key in ("image", "target", "source_annotation", "overlay"):
                archive.write(output / row[key], row[key])
            conversion = PurePosixPath(row["target"]).parent / "conversion.json"
            archive.write(output / str(conversion), str(conversion))
    print(json.dumps(report, indent=2))
    print("Dataset ZIP:", output / "madmaps-public-dataset.zip")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True)
    parser.add_argument("--archive", help="Optional existing complete public ZIP")
    parser.add_argument(
        "--cache",
        help="Reuse downloaded members after verifying their original ZIP CRCs",
    )
    parser.add_argument("--train", type=int, default=64)
    parser.add_argument("--validation", type=int, default=8)
    parser.add_argument("--test", type=int, default=8)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--max-target-chars", type=int, default=16000)
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    if args.validate_only:
        print(json.dumps(validate_subset(Path(args.output).resolve()), indent=2))
    else:
        if (
            any(n < 1 or n > 4200 for n in (args.train, args.validation, args.test))
            or args.max_target_chars < 100
        ):
            parser.error("Choose positive bounded split sizes and target length")
        prepare(args)


if __name__ == "__main__":
    main()
