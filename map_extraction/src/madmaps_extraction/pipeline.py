import hashlib
import json
import math
import re
import time
from datetime import UTC, datetime
from pathlib import Path
from uuid import uuid4

from . import __version__
from .adapters import DatabricksAdapter, InvalidResponse, RecordedAdapter
from .contract import calibrate, validate
from .graph import build_graph
from .preprocess import preprocess


def write_json(path, value):
    Path(path).write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")


def run(config, *, adapter=None):
    started = time.perf_counter()
    run_id = uuid4().hex
    root = Path(config.get("output_dir", "runs")) / run_id
    root.mkdir(parents=True)
    result = {
        "run_id": run_id,
        "pipeline_version": __version__,
        "created_at": datetime.now(UTC).isoformat(),
        "status": "failed",
        "config_sha256": hashlib.sha256(
            json.dumps(config, sort_keys=True).encode()
        ).hexdigest(),
        "config": config,
        "timings_s": {},
        "artifact_dir": str(root),
        "usage": None,
        "cost_usd": None,
    }
    # A run always gets a result record, including failed preprocessing/inference.
    stage = "configuration"
    try:
        for key in ("graph_id", "building_id", "floor_id"):
            if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,127}", config[key]):
                raise ValueError(f"Invalid {key}")
        confidence = config.get("min_confidence", 0.7)
        if not math.isfinite(confidence) or not 0 <= confidence <= 1:
            raise ValueError("min_confidence must be between zero and one")
        stage = "preprocess"
        tick = time.perf_counter()
        metadata = preprocess(
            config["input"],
            root / "preprocessed",
            page=config.get("page", 0),
            dpi=config.get("dpi", 200),
        )
        result["timings_s"]["preprocess"] = time.perf_counter() - tick
        result["metadata"] = metadata
        write_json(root / "metadata.json", metadata)
        stage = "adapter_configuration"
        if adapter is None:
            provider = config.get("adapter", "recorded")
            if provider == "recorded":
                adapter = RecordedAdapter(config["recorded_output"])
            elif provider == "databricks":
                adapter = DatabricksAdapter(
                    config["endpoint"],
                    timeout=config.get("timeout_s", 120),
                    max_attempts=config.get("max_attempts", 3),
                    model_revision=config.get("model_revision"),
                    api_format=config.get("api_format", "custom"),
                    profile=config.get("profile"),
                    host=config.get("host"),
                    structured_output=config.get("structured_output", True),
                )
            else:
                raise ValueError(f"Unknown adapter: {provider}")
        tick = time.perf_counter()
        stage = "extraction"
        try:
            extraction, raw, provenance = adapter.extract(metadata)
        except InvalidResponse as error:
            write_json(root / "raw_response.json", error.raw)
            raise
        finally:
            result["timings_s"]["extraction"] = time.perf_counter() - tick
        # Preserve malformed JSON strings/wrappers before schema validation.
        write_json(root / "raw_response.json", raw)
        result["provenance"] = provenance
        result["usage"] = provenance.get("usage")
        result["raw_sha256"] = hashlib.sha256(
            (root / "raw_response.json").read_bytes()
        ).hexdigest()
        tick = time.perf_counter()
        stage = "validation"
        validate(extraction, metadata)
        write_json(root / "extraction.json", extraction)
        issues = []
        for group in ("rooms", "walls", "doors", "walkable_areas"):
            if any(
                item["confidence"] < config.get("min_confidence", 0.7)
                for item in extraction[group]
            ):
                issues.append(f"Low-confidence {group}")
        calibration = config.get("calibration")
        if calibration is None:
            issues.append("Missing scale calibration; graph export withheld")
            report = {
                "candidate_valid": False,
                "requires_human_review": True,
                "issues": issues,
            }
        else:
            stage = "calibration_graph"
            scale = calibrate(calibration, metadata["width"], metadata["height"])
            result["meters_per_unit"] = scale
            graph, report = build_graph(
                extraction,
                scale,
                graph_id=config["graph_id"],
                building_id=config["building_id"],
                floor_id=config["floor_id"],
                floor_number=config.get("floor_number", 1),
                spacing=config.get("grid_spacing_px", 40),
                clearance_m=config.get("clearance_m", 0.1),
                max_nodes=config.get("max_nodes", 2500),
            )
            report["issues"].extend(issues)
            report["candidate_valid"] = not report["issues"]
            write_json(root / "graph_candidate.json", graph)
        result["validation"] = report
        write_json(root / "validation.json", report)
        result["timings_s"]["transform_validate"] = time.perf_counter() - tick
        result["status"] = "needsReview"
    except Exception as error:  # noqa: BLE001 - persist a failure record at the worker boundary
        # Do not persist exception text: SDK/HTTP errors can contain credentials or image data.
        result["error"] = {
            "type": type(error).__name__,
            "stage": stage,
            "message": "Stage failed; inspect input and stage artifacts",
        }
        if hasattr(error, "attempts"):
            result["inference_attempts"] = error.attempts
        if getattr(error, "error_code", None):
            result["error"]["databricks_code"] = error.error_code
        if getattr(error, "issue", None):
            result["error"]["response_issue"] = error.issue
    result["timings_s"]["total"] = time.perf_counter() - started
    write_json(root / "result.json", result)
    return result
