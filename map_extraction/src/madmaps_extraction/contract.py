import json
import math
from importlib.resources import files

from jsonschema import Draft202012Validator
from shapely.geometry import Point, Polygon, box

from .geometry import room_polygon

SCHEMA = json.loads(
    files("madmaps_extraction").joinpath("extraction.schema.json").read_text()
)


def load_json(path):
    def reject(value):
        raise ValueError(f"Non-finite JSON value: {value}")

    with open(path) as source:
        return json.load(source, parse_constant=reject)


def validate(extraction, metadata=None):
    # jsonschema's number type alone allows Python NaN; explicitly reject it.
    json.dumps(extraction, allow_nan=False)
    Draft202012Validator(SCHEMA).validate(extraction)
    width, height = extraction["width"], extraction["height"]
    if metadata and (width, height) != (metadata["width"], metadata["height"]):
        raise ValueError("Model dimensions differ from canonical image dimensions")
    bounds = box(0, 0, width, height)
    for group in ("rooms", "walls", "doors", "walkable_areas"):
        ids = [item["id"] for item in extraction[group]]
        if len(set(ids)) != len(ids):
            raise ValueError(f"Duplicate {group} IDs")
    room_ids = {r["id"] for r in extraction["rooms"]}
    for room in extraction["rooms"]:
        if not room["label"].strip():
            raise ValueError(f"Blank room label: {room['id']}")
        x1, y1, x2, y2 = room["bbox"]
        if not (x1 < x2 and y1 < y2) or not bounds.buffer(1e-7).covers(
            room_polygon(room)
        ):
            raise ValueError(f"Invalid room bbox: {room['id']}")
    for group in ("walls", "walkable_areas"):
        for item in extraction[group]:
            shape = Polygon(item["polygon"])
            if not shape.is_valid or shape.area <= 0 or not bounds.covers(shape):
                raise ValueError(f"Invalid {group} polygon: {item['id']}")
    for door in extraction["doors"]:
        if door["room_id"] not in room_ids or not bounds.contains(Point(door["point"])):
            raise ValueError(f"Invalid door room reference or position: {door['id']}")
    return extraction


def calibrate(calibration, width, height):
    points = calibration["points"]
    if len(points) != 2 or any(len(p) != 2 for p in points):
        raise ValueError("Calibration requires two pixel points")
    if not all(
        isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)
        for p in points
        for v in p
    ):
        raise ValueError("Calibration points must be finite numbers")
    if any(not (0 <= p[0] <= width and 0 <= p[1] <= height) for p in points):
        raise ValueError("Calibration points outside canonical image")
    distance = calibration["distance_m"]
    if (
        isinstance(distance, bool)
        or not isinstance(distance, (int, float))
        or not math.isfinite(distance)
        or distance <= 0
    ):
        raise ValueError("Calibration distance must be positive and finite")
    pixels = math.dist(*points)
    if pixels <= 0:
        raise ValueError("Calibration points must be distinct")
    scale = distance / pixels
    if not math.isfinite(scale) or scale <= 0:
        raise ValueError("Calibration produces a non-finite or zero scale")
    return scale
