"""Conservative single-floor roadmap; no automatic door carving or wall repair."""

import math

from scipy.spatial import KDTree
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union


def build_graph(
    extraction,
    scale,
    *,
    graph_id,
    building_id,
    floor_id,
    floor_number=1,
    spacing=40,
    clearance_m=0.1,
    max_nodes=2500,
):
    if isinstance(floor_number, bool) or not isinstance(floor_number, int):
        raise TypeError("floor_number must be an integer")
    if isinstance(max_nodes, bool) or not isinstance(max_nodes, int) or max_nodes < 1:
        raise ValueError("max_nodes must be a positive integer")
    if (
        not math.isfinite(spacing)
        or spacing <= 0
        or not math.isfinite(clearance_m)
        or clearance_m < 0
    ):
        raise ValueError("Grid spacing must be positive; clearance must be nonnegative")
    width, height = extraction["width"], extraction["height"]
    clearance = clearance_m / scale
    walls = unary_union([Polygon(w["polygon"]) for w in extraction["walls"]])
    walkable = unary_union(
        [Polygon(a["polygon"]) for a in extraction["walkable_areas"]]
    )
    # Buffer both floor and obstacles to enforce physical clearance.
    safe = walkable.intersection(box(0, 0, width, height).buffer(-clearance))
    safe = safe.difference(walls.buffer(clearance) if clearance else walls)
    issues, nodes, door_nodes = [], [], {}

    def add_node(point, kind, location=None):
        if len(nodes) >= max_nodes:
            raise ValueError(
                "Roadmap exceeds max_nodes; increase spacing or split floor"
            )
        node_id = f"n{len(nodes)}"
        node = {
            "nodeId": node_id,
            "floorId": floor_id,
            "x": float(point[0]),
            "y": float(point[1]),
            "kind": kind,
        }
        if location:
            node["locationId"] = location
        nodes.append(node)
        return node_id

    for door in extraction["doors"]:
        if safe.contains(Point(door["point"])):
            door_nodes[door["id"]] = add_node(
                door["point"], "approach", door["room_id"]
            )
        else:
            issues.append(f"Door {door['id']} is outside safe walkable space")
    # Bound work before scanning the grid; large images must choose a coarser grid.
    if math.ceil(width / spacing) * math.ceil(height / spacing) > 1000000:
        raise ValueError("Grid exceeds one million samples; increase spacing")
    for yi in range(1, math.ceil(height / spacing)):
        for xi in range(1, math.ceil(width / spacing)):
            point = (xi * spacing, yi * spacing)
            if safe.contains(Point(point)):
                add_node(point, "junction")
    edges, adjacency = [], {n["nodeId"]: set() for n in nodes}
    coordinates = [(n["x"], n["y"]) for n in nodes]
    if coordinates:
        tree = KDTree(coordinates)
        for i, j in sorted(tree.query_pairs(spacing * 1.5)):
            if coordinates[i] == coordinates[j]:
                continue
            segment = LineString([coordinates[i], coordinates[j]])
            if safe.covers(segment) and not walls.intersects(segment):
                a, b = nodes[i]["nodeId"], nodes[j]["nodeId"]
                edges.append(
                    {
                        "edgeId": f"e{len(edges)}",
                        "fromNodeId": a,
                        "toNodeId": b,
                        "type": "walk",
                        "bidirectional": True,
                    }
                )
                adjacency[a].add(b)
                adjacency[b].add(a)
    remaining, components = set(adjacency), 0
    while remaining:
        components += 1
        stack = [remaining.pop()]
        while stack:
            for other in adjacency[stack.pop()] & remaining:
                remaining.remove(other)
                stack.append(other)
    if not nodes:
        issues.append("No navigation nodes generated")
    if components > 1:
        issues.append(f"Roadmap has {components} disconnected components")
    if len(nodes) > 1 and any(not a for a in adjacency.values()):
        issues.append("Roadmap contains isolated nodes")
    locations = []
    for room in extraction["rooms"]:
        doors = [
            d
            for d in extraction["doors"]
            if d["room_id"] == room["id"] and d["id"] in door_nodes
        ]
        location = {
            "locationId": room["id"],
            "floorId": floor_id,
            "name": room["label"],
            "category": room["category"],
        }
        if doors:
            location["routeNodeId"] = door_nodes[doors[0]["id"]]
        else:
            issues.append(f"Room {room['id']} has no usable approach door")
        locations.append(location)
    graph = {
        "graphId": graph_id,
        "buildingId": building_id,
        "name": graph_id,
        "floors": [
            {
                "floorId": floor_id,
                "floorNumber": floor_number,
                "width": width,
                "height": height,
                "metersPerUnit": scale,
            }
        ],
        "nodes": nodes,
        "edges": edges,
        "locations": locations,
        "walls": [
            {
                "wallId": w["id"],
                "floorId": floor_id,
                "vertices": [{"x": x, "y": y} for x, y in w["polygon"]],
            }
            for w in extraction["walls"]
        ],
    }
    return graph, {
        "issues": issues,
        "components": components,
        "wall_crossings": 0,
        "candidate_valid": not issues,
        "requires_human_review": True,
    }
