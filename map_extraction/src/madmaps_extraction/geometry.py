"""Canonical pixel geometry shared by validation and benchmarking."""

import math

from shapely.geometry import Polygon


def room_vertices(room):
    """bbox is the unrotated rectangle; rotate clockwise about its center."""
    left, top, right, bottom = room["bbox"]
    cx, cy = (left + right) / 2, (top + bottom) / 2
    angle = math.radians(room.get("rotation_deg", 0))
    cosine, sine = math.cos(angle), math.sin(angle)
    return [
        [
            cx + (x - cx) * cosine - (y - cy) * sine,
            cy + (x - cx) * sine + (y - cy) * cosine,
        ]
        for x, y in ((left, top), (right, top), (right, bottom), (left, bottom))
    ]


def room_polygon(room):
    return Polygon(room_vertices(room))
