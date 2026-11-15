"""Synthetic harness check only. Never use this as evidence of VLM accuracy."""

import json
from pathlib import Path

from PIL import Image, ImageDraw


def main():
    root = Path(__file__).parent
    image = Image.new("RGB", (400, 240), "white")
    draw = ImageDraw.Draw(image)
    draw.rectangle((190, 0, 210, 80), fill="black")
    draw.rectangle((190, 160, 210, 240), fill="black")
    draw.text((40, 100), "Room A", fill="black")
    draw.text((280, 100), "Room B", fill="black")
    image.save(root / "plan.png")
    extraction = {
        "schema_version": 1,
        "width": 400,
        "height": 240,
        "coordinate_origin": "top-left",
        "coordinate_units": "pixels",
        "rooms": [
            {
                "id": "room-a",
                "label": "Room A",
                "category": "classroom",
                "bbox": [10, 10, 180, 230],
                "confidence": 1,
            },
            {
                "id": "room-b",
                "label": "Room B",
                "category": "classroom",
                "bbox": [220, 10, 390, 230],
                "confidence": 1,
            },
        ],
        "walls": [
            {
                "id": "wall-top",
                "polygon": [[190, 0], [210, 0], [210, 80], [190, 80]],
                "confidence": 1,
            },
            {
                "id": "wall-bottom",
                "polygon": [[190, 160], [210, 160], [210, 240], [190, 240]],
                "confidence": 1,
            },
        ],
        "doors": [
            {"id": "door-a", "room_id": "room-a", "point": [160, 120], "confidence": 1},
            {"id": "door-b", "room_id": "room-b", "point": [240, 120], "confidence": 1},
        ],
        "walkable_areas": [
            {
                "id": "hall",
                "polygon": [[20, 90], [380, 90], [380, 150], [20, 150]],
                "confidence": 1,
            }
        ],
    }
    (root / "recorded.json").write_text(json.dumps(extraction, indent=2) + "\n")
    # Separate file so annotations and candidate output can evolve independently.
    (root / "ground_truth.json").write_text(json.dumps(extraction, indent=2) + "\n")


if __name__ == "__main__":
    main()
