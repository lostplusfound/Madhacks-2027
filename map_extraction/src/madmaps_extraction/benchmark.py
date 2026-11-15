"""Spatial one-to-one matching; failed runs stay in the denominator."""

import heapq
import math
import statistics
from pathlib import Path

import numpy as np
from scipy.optimize import linear_sum_assignment
from shapely.geometry import LineString, Polygon
from shapely.ops import unary_union

from .contract import load_json, validate
from .geometry import room_polygon
from .pipeline import run, write_json


def match(scores, threshold):
    scores = np.asarray(scores, dtype=float)
    if scores.size == 0:
        return []
    # Maximize number of above-threshold matches first, then match quality.
    valid = scores >= threshold
    rewards = valid * (min(scores.shape) + 1 + scores)
    rows, cols = linear_sum_assignment(rewards, maximize=True)
    return [(int(i), int(j)) for i, j in zip(rows, cols) if valid[i, j]]


def detection(predicted, expected, similarity, threshold):
    scores = [[similarity(a, b) for b in expected] for a in predicted]
    pairs = match(scores, threshold)
    tp = len(pairs)
    # No positives and no predictions is a correct empty result.
    precision = tp / len(predicted) if predicted else float(not expected)
    recall = tp / len(expected) if expected else float(not predicted)
    return {
        "tp": tp,
        "fp": len(predicted) - tp,
        "fn": len(expected) - tp,
        "precision": precision,
        "recall": recall,
        "f1": 2 * precision * recall / (precision + recall)
        if precision + recall
        else 0,
        "matched_similarity_mean": statistics.mean(scores[i][j] for i, j in pairs)
        if pairs
        else None,
    }, pairs


def iou(a, b):
    union = a.union(b).area
    return a.intersection(b).area / union if union else 0


def normalize_text(value):
    return " ".join(value.casefold().split())


def shortest(adjacency, start, target):
    distances, queue = {start: 0}, [(0, start)]
    while queue:
        distance, node = heapq.heappop(queue)
        if distance > distances[node]:
            continue
        if node == target:
            return distance
        for other, cost in adjacency[node]:
            candidate = distance + cost
            if candidate < distances.get(other, math.inf):
                distances[other] = candidate
                heapq.heappush(queue, (candidate, other))
    return None


def navigation_metrics(graph, truth, routes, tolerance):
    nodes = {n["nodeId"]: n for n in graph["nodes"]}
    adjacency = {n: [] for n in nodes}
    truth_walls = unary_union([Polygon(w["polygon"]) for w in truth["walls"]])
    crossings = 0
    scale = graph["floors"][0]["metersPerUnit"]
    for edge in graph["edges"]:
        a, b = nodes[edge["fromNodeId"]], nodes[edge["toNodeId"]]
        segment = LineString([(a["x"], a["y"]), (b["x"], b["y"])])
        unsafe = segment.intersects(truth_walls)
        crossings += int(unsafe)
        # Never credit a route through a ground-truth wall as successful.
        if not unsafe:
            cost = segment.length * scale
            adjacency[a["nodeId"]].append((b["nodeId"], cost))
            if edge["bidirectional"]:
                adjacency[b["nodeId"]].append((a["nodeId"], cost))
    outcomes = []
    for route in routes:
        endpoints = []
        for point in (route["start"], route["end"]):
            near = min(
                nodes,
                key=lambda n: math.dist(point, (nodes[n]["x"], nodes[n]["y"])),
                default=None,
            )
            if (
                near is None
                or math.dist(point, (nodes[near]["x"], nodes[near]["y"])) > tolerance
            ):
                endpoints.append(None)
            else:
                # Snapping must not jump through a wall either.
                distance = math.dist(point, (nodes[near]["x"], nodes[near]["y"]))
                if distance and LineString(
                    [point, (nodes[near]["x"], nodes[near]["y"])]
                ).intersects(truth_walls):
                    near = None
                endpoints.append(near)
        covered = None not in endpoints
        length = shortest(adjacency, *endpoints) if covered else None
        expected = route.get("reachable", True)
        correct = covered and ((length is not None) == expected)
        expected_length = route.get("distance_m")
        outcomes.append(
            {
                "covered": covered,
                "correct": correct,
                "distance_m": length,
                "relative_distance_error": abs(length - expected_length)
                / expected_length
                if length is not None
                and expected_length is not None
                and expected_length > 0
                else None,
            }
        )
    return {
        "ground_truth_wall_crossings": crossings,
        "ground_truth_wall_crossing_rate": crossings / len(graph["edges"])
        if graph["edges"]
        else None,
        "reference_route_success": sum(o["correct"] for o in outcomes) / len(outcomes)
        if outcomes
        else None,
        "routes": outcomes,
    }


def score(predicted, truth, *, iou_threshold=0.5, door_tolerance_px=10):
    rooms, pairs = detection(
        predicted["rooms"],
        truth["rooms"],
        lambda a, b: iou(room_polygon(a), room_polygon(b)),
        iou_threshold,
    )
    correct = sum(
        normalize_text(predicted["rooms"][i]["label"])
        == normalize_text(truth["rooms"][j]["label"])
        for i, j in pairs
    )
    rooms["matched_text_accuracy"] = correct / len(pairs) if pairs else None
    rooms["text_recall"] = correct / len(truth["rooms"]) if truth["rooms"] else None
    rooms["matched_category_accuracy"] = (
        sum(
            predicted["rooms"][i]["category"] == truth["rooms"][j]["category"]
            for i, j in pairs
        )
        / len(pairs)
        if pairs
        else None
    )
    categories = sorted(
        {"bathroom", "elevator", "stairs"}
        | {
            room["category"]
            for extraction in (predicted, truth)
            for room in extraction["rooms"]
        }
    )
    features = {}
    for category in categories:
        observed = [room for room in predicted["rooms"] if room["category"] == category]
        expected = [room for room in truth["rooms"] if room["category"] == category]
        metrics, _ = detection(
            observed,
            expected,
            lambda a, b: iou(room_polygon(a), room_polygon(b)),
            iou_threshold,
        )
        if not observed and not expected:
            metrics.update(precision=None, recall=None, f1=None)
        features[category] = metrics
    walls, _ = detection(
        predicted["walls"],
        truth["walls"],
        lambda a, b: iou(Polygon(a["polygon"]), Polygon(b["polygon"])),
        iou_threshold,
    )
    areas, _ = detection(
        predicted["walkable_areas"],
        truth["walkable_areas"],
        lambda a, b: iou(Polygon(a["polygon"]), Polygon(b["polygon"])),
        iou_threshold,
    )
    # Tolerance-gated matching prioritizes maximum valid cardinality.
    doors, door_pairs = detection(
        predicted["doors"],
        truth["doors"],
        lambda a, b: max(
            0, 1 - math.dist(a["point"], b["point"]) / (2 * door_tolerance_px)
        ),
        0.5,
    )
    doors["matched_position_error_px"] = (
        statistics.mean(
            math.dist(predicted["doors"][i]["point"], truth["doors"][j]["point"])
            for i, j in door_pairs
        )
        if door_pairs
        else None
    )
    return {
        "rooms": rooms,
        "walls": walls,
        "doors": doors,
        "walkable_areas": areas,
        "features_by_category": features,
    }


def benchmark(manifest_path, output_dir, *, repeats=1, overrides=None):
    if repeats < 1:
        raise ValueError("repeats must be positive")
    if (Path(output_dir) / "benchmark.json").exists():
        raise FileExistsError(
            "Choose a new output directory to preserve benchmark history"
        )
    manifest_path = Path(manifest_path).resolve()
    manifest = load_json(manifest_path)
    cases = manifest["cases"]
    if not cases or len({c["id"] for c in cases}) != len(cases):
        raise ValueError("Benchmark requires nonempty cases with unique IDs")
    iou_threshold = manifest.get("iou_threshold", 0.5)
    tolerance = manifest.get("door_tolerance_px", 10)
    if not 0 < iou_threshold <= 1 or tolerance <= 0:
        raise ValueError("Invalid matching thresholds")
    rows = []
    for case in cases:
        # Invalid ground truth is a benchmark configuration error, not a model failure.
        truth = validate(load_json(manifest_path.parent / case["ground_truth"]))
        expected_scale = case.get("expected_meters_per_unit")
        if expected_scale is not None and (
            not math.isfinite(expected_scale) or expected_scale <= 0
        ):
            raise ValueError("Ground-truth scale must be positive and finite")
        config_path = manifest_path.parent / case["config"]
        config = load_json(config_path)
        for key in ("input", "recorded_output"):
            if key in config:
                config[key] = str((config_path.parent / config[key]).resolve())
        config.update(overrides or {})
        config["output_dir"] = str(Path(output_dir).resolve() / "runs")
        for repeat in range(repeats):
            result = run(config)
            row = {
                "case_id": case["id"],
                "repeat": repeat,
                "run": result,
                "evaluation_failed": False,
                "metrics": None,
            }
            if result["status"] != "failed":
                root = Path(result["artifact_dir"])
                predicted = load_json(root / "extraction.json")
                if (predicted["width"], predicted["height"]) != (
                    truth["width"],
                    truth["height"],
                ):
                    row["evaluation_failed"] = True
                    row["evaluation_error"] = (
                        "Ground-truth and predicted coordinate frames differ"
                    )
                else:
                    metrics = score(
                        predicted,
                        truth,
                        iou_threshold=iou_threshold,
                        door_tolerance_px=tolerance,
                    )
                    scale = result.get("meters_per_unit")
                    metrics["scale_relative_error"] = (
                        abs(scale - expected_scale) / expected_scale
                        if scale is not None and expected_scale
                        else None
                    )
                    graph_path = root / "graph_candidate.json"
                    metrics["navigation"] = (
                        navigation_metrics(
                            load_json(graph_path),
                            truth,
                            case.get("routes", []),
                            tolerance,
                        )
                        if graph_path.exists()
                        else None
                    )
                    row["metrics"] = metrics
            rows.append(row)
    failed = sum(r["run"]["status"] == "failed" or r["evaluation_failed"] for r in rows)
    summary = {
        "runs": len(rows),
        "failures": failed,
        "failure_rate": failed / len(rows),
        "candidate_valid_rate": sum(
            r["run"].get("validation", {}).get("candidate_valid", False)
            and not r["evaluation_failed"]
            for r in rows
        )
        / len(rows),
        "latency_total_p50_s": float(
            np.percentile([r["run"]["timings_s"]["total"] for r in rows], 50)
        ),
        "latency_total_p95_s": float(
            np.percentile([r["run"]["timings_s"]["total"] for r in rows], 95)
        ),
        "evaluated_runs": sum(r["metrics"] is not None for r in rows),
        "quality_aggregation": "micro counts over evaluated runs; inspect failure_rate alongside quality",
        "iou_threshold": iou_threshold,
        "door_tolerance_px": tolerance,
    }
    extraction_latencies = [
        r["run"]["timings_s"]["extraction"]
        for r in rows
        if "extraction" in r["run"]["timings_s"]
    ]
    for percentile in (50, 95):
        summary[f"latency_extraction_p{percentile}_s"] = (
            float(np.percentile(extraction_latencies, percentile))
            if extraction_latencies
            else None
        )
    summary["inference_retries"] = sum(
        max(
            0,
            r["run"].get(
                "inference_attempts", r["run"].get("provenance", {}).get("attempts", 0)
            )
            - 1,
        )
        for r in rows
    )
    for group in ("rooms", "walls", "doors", "walkable_areas"):
        counts = {
            k: sum(r["metrics"][group][k] for r in rows if r["metrics"] is not None)
            for k in ("tp", "fp", "fn")
        }
        tp, fp, fn = counts["tp"], counts["fp"], counts["fn"]
        counts["f1"] = 2 * tp / (2 * tp + fp + fn) if tp + fp + fn else None
        summary[group] = counts
    for key, getter in {
        "text_recall_mean": lambda m: m["rooms"]["text_recall"],
        "matched_category_accuracy_mean": lambda m: m["rooms"][
            "matched_category_accuracy"
        ],
        "scale_relative_error_mean": lambda m: m["scale_relative_error"],
        "door_position_error_px_mean": lambda m: m["doors"][
            "matched_position_error_px"
        ],
        "reference_route_success_mean": lambda m: (
            m["navigation"]["reference_route_success"] if m["navigation"] else None
        ),
        "wall_crossing_rate_mean": lambda m: (
            m["navigation"]["ground_truth_wall_crossing_rate"]
            if m["navigation"]
            else None
        ),
    }.items():
        values = [getter(r["metrics"]) for r in rows if r["metrics"] is not None]
        values = [v for v in values if v is not None]
        summary[key] = statistics.mean(values) if values else None
    summary["features_by_category"] = {}
    categories = {
        category
        for row in rows
        if row["metrics"] is not None
        for category in row["metrics"]["features_by_category"]
    }
    for category in sorted(categories):
        counts = {
            key: sum(
                row["metrics"]["features_by_category"].get(category, {}).get(key, 0)
                for row in rows
                if row["metrics"] is not None
            )
            for key in ("tp", "fp", "fn")
        }
        tp, fp, fn = counts["tp"], counts["fp"], counts["fn"]
        counts["f1"] = 2 * tp / (2 * tp + fp + fn) if tp + fp + fn else None
        summary["features_by_category"][category] = counts
    report = {
        "manifest": manifest,
        "repeats": repeats,
        "summary": summary,
        "results": rows,
    }
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    write_json(Path(output_dir) / "benchmark.json", report)
    return report
