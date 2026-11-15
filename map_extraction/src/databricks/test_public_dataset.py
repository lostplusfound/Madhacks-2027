"""Geometry and provenance regression tests; fixtures here are synthetic only."""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock

from madmaps_extraction.training import load_reviewed_dataset
from PIL import Image
from shapely.geometry import Point, Polygon, box
from shapely.ops import unary_union

from public_dataset import RangeReader, convert, sha256, simple_polygons, write_json


def fixture_svg(*, left="Bedroom", transform="", canvas="100 100"):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {canvas}">
      <g class="Floorplan" transform="{transform}">
        <g class="Space {left}"><polygon points="0,0 45,0 45,100 0,100"/></g>
        <g class="Space Kitchen"><polygon points="55,0 100,0 100,100 55,100"/></g>
        <g id="Wall"><polygon points="45,0 55,0 55,100 45,100"/></g>
        <g id="Door"><polygon points="45,40 55,40 55,60 45,60"/></g>
      </g></svg>'''.encode()


class GeometryTests(unittest.TestCase):
    def test_door_opening_is_removed_and_links_both_rooms(self):
        target, notes = convert(fixture_svg(), (100, 100))
        wall = unary_union([Polygon(row["polygon"]) for row in target["walls"]])
        self.assertFalse(wall.covers(Point(50, 50)))
        self.assertTrue(wall.covers(Point(50, 20)))
        self.assertAlmostEqual(wall.area, 800)
        self.assertEqual(notes["source_openings"], 1)
        self.assertEqual({d["room_id"] for d in target["doors"]}, {"room-0", "room-1"})

    def test_svg_canvas_is_not_stretched_to_raster_margins(self):
        target, _ = convert(fixture_svg(canvas="80 90"), (120, 130))
        self.assertEqual(target["rooms"][0]["bbox"], [0, 0, 45, 100])
        self.assertEqual(target["width"], 120)

    def test_ancestor_transforms_are_applied(self):
        target, _ = convert(
            fixture_svg(transform="translate(5 10) scale(0.5)"), (100, 100)
        )
        self.assertEqual(target["rooms"][0]["bbox"], [5, 10, 27.5, 60])
        self.assertEqual(target["doors"][0]["point"], [30, 35])

    def test_outdoor_is_not_walkable(self):
        target, _ = convert(fixture_svg(left="Outdoor"), (100, 100))
        walkable = unary_union(
            [Polygon(row["polygon"]) for row in target["walkable_areas"]]
        )
        self.assertFalse(walkable.covers(Point(20, 50)))
        self.assertTrue(walkable.covers(Point(75, 50)))

    def test_holes_are_preserved_in_simple_polygon_export(self):
        source = box(0, 0, 100, 100).difference(box(20, 20, 40, 40))
        pieces = simple_polygons(source)
        self.assertTrue(all(not part.interiors for part in pieces))
        self.assertLess(unary_union(pieces).symmetric_difference(source).area, 0.01)

    def test_ambiguous_or_unlinked_door_is_rejected(self):
        svg = fixture_svg().replace(
            b"45,40 55,40 55,60 45,60", b"48,40 52,40 52,60 48,60"
        )
        with self.assertRaisesRegex(ValueError, "adjacent"):
            convert(svg, (100, 100))

    def test_invalid_source_geometry_is_not_silently_repaired(self):
        svg = fixture_svg().replace(b"0,0 45,0 45,100 0,100", b"0,0 45,100 45,0 0,100")
        with self.assertRaisesRegex(ValueError, "Invalid source polygon"):
            convert(svg, (100, 100))

    def test_server_cannot_force_full_archive_download(self):
        reader = RangeReader("https://example.invalid/archive.zip", 100)
        response = Mock(status_code=200, headers={})
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        reader.session.get = Mock(return_value=response)
        with self.assertRaisesRegex(ValueError, "byte range"):
            reader.read(10)
        response.raw.read.assert_not_called()
        reader.close()


class PublicLoaderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.rows = []
        for index, split in enumerate(("train", "validation", "test")):
            folder = self.root / split
            folder.mkdir()
            image = Image.new("RGB", (100, 100), (index * 40, 0, 0))
            image.save(folder / "image.png")
            svg = fixture_svg(left=("Bedroom", "LivingRoom", "Office")[index])
            (folder / "model.svg").write_bytes(svg)
            target, _ = convert(svg, image.size)
            write_json(folder / "target.json", target)
            self.rows.append(
                {
                    "split": split,
                    "group": "plan-" + split,
                    "reviewed": False,
                    "image": split + "/image.png",
                    "target": split + "/target.json",
                    "source_annotation": split + "/model.svg",
                    "image_sha256": sha256((folder / "image.png").read_bytes()),
                    "image_pixel_sha256": sha256(image.tobytes()),
                    "source_sha256": sha256(svg),
                    "target_sha256": sha256((folder / "target.json").read_bytes()),
                    "annotation_provenance": {
                        "kind": "public_dataset",
                        "dataset": "CubiCasa5K",
                        "converter": "cubicasa5k-svg-v1",
                        "source_url": "https://doi.org/10.5281/zenodo.2613548",
                        "license": "CC-BY-NC-SA-4.0",
                        "original_split": split,
                    },
                }
            )
        self.save()

    def save(self):
        self.manifest = self.root / "manifest.json"
        write_json(
            self.manifest,
            {
                "annotation_policy": "public_dataset_auto_conversion",
                "examples": self.rows,
            },
        )

    def test_public_annotations_require_explicit_opt_in(self):
        with self.assertRaisesRegex(ValueError, "allow-public-annotations"):
            load_reviewed_dataset(self.manifest)
        partitions = load_reviewed_dataset(self.manifest, allow_public_annotations=True)
        self.assertEqual([len(rows) for rows in partitions.values()], [1, 1, 1])
        self.assertFalse(partitions["train"][0]["reviewed"])

    def test_unreviewed_private_example_cannot_use_public_flag(self):
        del self.rows[0]["annotation_provenance"]
        self.save()
        with self.assertRaisesRegex(ValueError, "provenance"):
            load_reviewed_dataset(self.manifest, allow_public_annotations=True)

    def test_target_tampering_is_rejected(self):
        path = self.root / self.rows[0]["target"]
        target = json.loads(path.read_text())
        target["rooms"][0]["label"] = "Wrong label"
        write_json(path, target)
        with self.assertRaisesRegex(ValueError, "target checksum"):
            load_reviewed_dataset(self.manifest, allow_public_annotations=True)

    def test_source_tampering_is_rejected(self):
        (self.root / self.rows[0]["source_annotation"]).write_text("changed")
        with self.assertRaisesRegex(ValueError, "source annotation checksum"):
            load_reviewed_dataset(self.manifest, allow_public_annotations=True)

    def test_reencoded_duplicate_pixels_across_splits_are_rejected(self):
        source = self.root / self.rows[0]["image"]
        destination = self.root / self.rows[1]["image"]
        with Image.open(source) as image:
            image.save(destination, compress_level=0)
            self.rows[1]["image_pixel_sha256"] = sha256(image.convert("RGB").tobytes())
        self.rows[1]["image_sha256"] = sha256(destination.read_bytes())
        self.save()
        with self.assertRaisesRegex(ValueError, "pixel leakage"):
            load_reviewed_dataset(self.manifest, allow_public_annotations=True)


if __name__ == "__main__":
    unittest.main()
