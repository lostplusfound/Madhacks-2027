"""Synthetic amenity-detection smoke case, independent of numbered rooms."""

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).parent
image = Image.new("RGB", (600, 300), "white")
draw = ImageDraw.Draw(image)
font = ImageFont.load_default(size=22)
features = [
    ("restroom", "WC", "bathroom", [20, 30, 180, 270]),
    ("lift", "Elevator", "elevator", [220, 30, 380, 270]),
    ("stairwell", "Stairs", "stairs", [420, 30, 580, 270]),
]
for _, label, _, bounds in features:
    draw.rectangle(bounds, outline="black", width=3)
    draw.text((bounds[0] + 15, 45), label, fill="black", font=font)
# Restroom figures, lift direction arrows, and stair treads.
for x in (65, 125):
    draw.ellipse((x - 8, 100, x + 8, 116), fill="black")
    draw.rectangle((x - 5, 120, x + 5, 155), fill="black")
    draw.line((x - 5, 155, x - 9, 180), fill="black", width=4)
    draw.line((x + 5, 155, x + 9, 180), fill="black", width=4)
for x, direction in ((270, -1), (330, 1)):
    draw.line((x, 120, x, 190), fill="black", width=3)
    y = 120 if direction == -1 else 190
    draw.line(
        (x - 12, y - direction * 12, x, y, x + 12, y - direction * 12),
        fill="black",
        width=3,
    )
for n in range(6):
    draw.line((450, 110 + n * 19, 550, 110 + n * 19), fill="black", width=2)
image.save(root / "amenities.png")
truth = {
    "schema_version": 1,
    "width": 600,
    "height": 300,
    "coordinate_origin": "top-left",
    "coordinate_units": "pixels",
    "rooms": [
        {
            "id": id,
            "label": label,
            "category": category,
            "bbox": bounds,
            "rotation_deg": 0,
            "confidence": 1,
        }
        for id, label, category, bounds in features
    ],
    "walls": [],
    "doors": [],
    "walkable_areas": [],
}
(root / "amenities-ground-truth.json").write_text(json.dumps(truth, indent=2) + "\n")
