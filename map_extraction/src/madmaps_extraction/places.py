"""Minimal floor-plan image plus room/amenity pins. No geometry generation."""

import base64
import hashlib
import json
import math
import time
from pathlib import Path

from .contract import SCHEMA, load_json
from .preprocess import preprocess

CATEGORIES = SCHEMA["properties"]["rooms"]["items"]["properties"]["category"]["enum"]
MAX_PLACES = 96


def places_prompt():
    return (
        "Locate clearly visible named/numbered rooms and amenities on this floor plan. "
        'Return JSON only: {"places":[{"label":"201","category":"other","point":[500,300]}]}. '
        "A point is the center of the printed room label or amenity symbol, not a room boundary. "
        "Use an integer grid from 0 to 1000 over the COMPLETE image: x=0 left, x=1000 right, y=0 top, y=1000 bottom. "
        "Preserve room numbers and written names. For clear unlabelled symbols use Restroom, Elevator, or Stairs. "
        "Do not invent room numbers, connections or unreadable text. Ignore dimensions, legends and furniture. "
        "Include toilets/WC, stairs, elevators, entrances/exits and accessible amenities. "
        "Use bathroom for toilets, elevator for lifts, stairs for stairwells, and other for a room with unknown purpose. "
        "Allowed categories: " + ",".join(CATEGORIES) + ". "
        "Do not output walls, doors, polygons, paths, explanations or markdown. "
        f"Return at most {MAX_PLACES} places; return an empty array if none are visible."
    )


def places_schema():
    return {
        "type": "object",
        "additionalProperties": False,
        "required": ["places"],
        "properties": {
            "places": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": ["label", "category", "point"],
                    "properties": {
                        "label": {"type": "string"},
                        "category": {"type": "string", "enum": CATEGORIES},
                        "point": {"type": "array", "items": {"type": "number"}},
                    },
                },
            }
        },
    }


def parse_places(value, metadata):
    if (
        not isinstance(value, dict)
        or set(value) != {"places"}
        or not isinstance(value["places"], list)
    ):
        raise ValueError("Expected a places array")
    if len(value["places"]) > MAX_PLACES:
        raise ValueError("Too many places; use a smaller floor-plan section")
    result, seen = [], set()
    for row in value["places"]:
        if not isinstance(row, dict) or set(row) != {"label", "category", "point"}:
            raise ValueError("Each place needs label, category and point")
        label, category, point = row["label"], row["category"], row["point"]
        if (
            not isinstance(label, str)
            or not 1 <= len(label.strip()) <= 80
            or category not in CATEGORIES
        ):
            raise ValueError("Invalid place label or category")
        if (
            not isinstance(point, list)
            or len(point) != 2
            or any(
                isinstance(v, bool)
                or not isinstance(v, (int, float))
                or not math.isfinite(v)
                or not 0 <= v <= 1000
                for v in point
            )
        ):
            raise ValueError("Place coordinates must be within the image grid")
        key = (label.strip(), category, *point)
        if key in seen:
            continue
        seen.add(key)
        result.append(
            {
                "id": f"place-{len(result) + 1}",
                "label": label.strip(),
                "category": category,
                "x": round(point[0] * metadata["width"] / 1000, 2),
                "y": round(point[1] * metadata["height"] / 1000, 2),
                "source": "model",
            }
        )
    return result


def find_places(metadata, settings, *, client=None):
    if settings.get("api_format") != "chat" or not settings.get("endpoint"):
        raise ValueError(
            "Configure an image-capable chat model to find places automatically"
        )
    if client is None:
        from databricks.sdk import WorkspaceClient
        from databricks.sdk.config import Config

        client = WorkspaceClient(
            config=Config(
                profile=settings.get("profile"),
                host=settings.get("host"),
                http_timeout_seconds=45,
                retry_timeout_seconds=0,
            )
        )
    prompt = places_prompt()
    raw = client.api_client.do(
        "POST",
        "/serving-endpoints/chat/completions",
        body={
            "model": settings["endpoint"],
            "temperature": 0,
            "max_tokens": 2048,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": "data:image/png;base64,"
                                + base64.b64encode(
                                    Path(metadata["image"]).read_bytes()
                                ).decode()
                            },
                        },
                    ],
                }
            ],
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": "floor_plan_places",
                    "strict": True,
                    "schema": places_schema(),
                },
            },
        },
    )
    choices = raw.get("choices", [])
    if len(choices) != 1 or choices[0].get("finish_reason") in {"length", "max_tokens"}:
        raise ValueError(
            "Place detection was incomplete; try a smaller floor-plan section"
        )
    content = choices[0].get("message", {}).get("content")
    if isinstance(content, list):
        content = "".join(
            block["text"] for block in content if block.get("type") == "text"
        )
    if not isinstance(content, str):
        raise TypeError("Model did not return place data")
    value = json.loads(content)
    pins = parse_places(value, metadata)
    return (
        pins,
        raw,
        {
            "model": settings["endpoint"],
            "prompt_sha256": hashlib.sha256(prompt.encode()).hexdigest(),
            "model_coordinate_frame": "normalized-0-1000",
            "usage": raw.get("usage"),
        },
    )


def execute_places(request, directory, root, settings, *, client=None):
    started = time.perf_counter()
    mode = request.get("mode", "manual")
    if mode not in {"manual", "demo", "databricks"}:
        raise ValueError("Unknown place extraction mode")
    sample = mode == "demo" or request.get("sample_plan") is True
    if sample:
        source = root / "examples/amenities.png"
    else:
        data = base64.b64decode(request["file_base64"], validate=True)
        extension = Path(request["file_name"]).suffix.lower()
        if not 0 < len(data) <= 8 * 1024 * 1024 or extension not in {
            ".png",
            ".jpg",
            ".jpeg",
            ".pdf",
        }:
            raise ValueError("Choose a PNG, JPEG or PDF of at most 8 MB")
        source = directory / f"upload{extension}"
        source.write_bytes(data)
    metadata = preprocess(
        source, directory / "preprocessed", page=int(request.get("page", 0))
    )
    inference_started = time.perf_counter()
    places, provenance = [], {"source": mode}
    if mode == "databricks":
        places, raw, provenance = find_places(metadata, settings, client=client)
        (directory / "raw_response.json").write_text(json.dumps(raw, indent=2))
    elif mode == "demo":
        truth = load_json(root / "examples/amenities-ground-truth.json")
        for room in truth["rooms"]:
            left, top, right, bottom = room["bbox"]
            places.append(
                {
                    "id": room["id"],
                    "label": room["label"],
                    "category": room["category"],
                    "x": (left + right) / 2,
                    "y": (top + bottom) / 2,
                    "source": "example",
                }
            )
    payload = {
        "profile": "places",
        "places": places,
        "synthetic": sample,
        "inference_mode": mode,
        "plan_base64": base64.b64encode(Path(metadata["image"]).read_bytes()).decode(),
        "result": {
            "status": "needsReview",
            "metadata": metadata,
            "provenance": provenance,
            "timings_s": {
                "extraction": time.perf_counter() - inference_started,
                "total": time.perf_counter() - started,
            },
        },
    }
    (directory / "places.json").write_text(
        json.dumps(
            {
                "width": metadata["width"],
                "height": metadata["height"],
                "coordinate_origin": "top-left",
                "coordinate_units": "pixels",
                "places": places,
            },
            indent=2,
        )
    )
    return payload
