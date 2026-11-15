"""File-based worker used by the development-only Serverpod extraction lab."""

import argparse
import base64
import json
import re
import shutil
from pathlib import Path
from uuid import uuid4
from zipfile import ZIP_DEFLATED, ZipFile

from .benchmark import benchmark, navigation_metrics, score
from .contract import load_json, validate
from .pipeline import run, write_json
from .settings import load_settings


def resolve_under(root, path):
    result = (root / path).resolve()
    if not result.is_relative_to(root.resolve()):
        raise ValueError("Path outside dataset root")
    return result


def review_example(root, previous, correction, *, split, group):
    if split not in {"train", "validation", "test"} or not re.fullmatch(
        r"[A-Za-z0-9_-]{1,80}", group
    ):
        raise ValueError("Choose a split and a building/source group")
    validate(correction, previous["result"]["metadata"])
    dataset = root / "runs" / "reviews"
    dataset.mkdir(parents=True, exist_ok=True)
    source_hash = previous["result"]["metadata"]["source_sha256"]
    image_hash = previous["result"]["metadata"]["image_sha256"]
    for path in dataset.glob("*/review.json"):
        existing = load_json(path)
        if (
            existing["group"] == group or existing["source_sha256"] == source_hash
        ) and existing["split"] != split:
            raise ValueError(
                "The same building/source or image cannot appear in multiple splits"
            )
        if existing["image_sha256"] == image_hash:
            raise ValueError(
                "This canonical image is already reviewed; remove its old review before replacing it"
            )
    target = dataset / uuid4().hex
    target.mkdir()
    shutil.copyfile(previous["result"]["metadata"]["image"], target / "image.png")
    write_json(target / "target.json", correction)
    record = {
        "id": target.name,
        "image": f"{target.name}/image.png",
        "target": f"{target.name}/target.json",
        "split": split,
        "group": group,
        "source_sha256": source_hash,
        "image_sha256": image_hash,
        "reviewed": True,
        "synthetic": previous.get("synthetic", False),
    }
    write_json(target / "review.json", record)
    return {"saved": True, "example_id": target.name, "split": split, "group": group}


def export_reviews(root, output):
    dataset = root / "runs" / "reviews"
    records = [load_json(p) for p in sorted(dataset.glob("*/review.json"))]
    if not records:
        raise ValueError("Save a reviewed correction first")
    manifest = {"schema_version": 1, "examples": records}
    with ZipFile(output, "w", ZIP_DEFLATED) as archive:
        archive.writestr("manifest.json", json.dumps(manifest, indent=2))
        for row in records:
            for key in ("image", "target"):
                archive.write(resolve_under(dataset, row[key]), row[key])
    return {
        "file_name": "madmaps-reviewed-dataset.zip",
        "examples": len(records),
        "zip_base64": base64.b64encode(output.read_bytes()).decode(),
    }


def execute(request, directory, root):
    settings = load_settings(root)
    action = request.get("action", "extract")
    if action == "review":
        # previous_result is supplied by Serverpod from its job registry, never a browser path.
        previous = load_json(request["previous_result"])
        return review_example(
            root,
            previous,
            request["correction"],
            split=request["split"],
            group=request["group"],
        )
    if action == "export":
        return export_reviews(root, directory / "dataset.zip")
    if action == "train":
        from databricks.sdk import WorkspaceClient

        job_id = settings["training_job_id"]
        if not job_id:
            raise ValueError("No Databricks training job configured")
        manifest = request["manifest_path"]
        if not manifest.startswith("/Volumes/") or ".." in Path(manifest).parts:
            raise ValueError("Training manifest must be in a Unity Catalog Volume")
        epochs, rate, rank = (
            int(request["epochs"]),
            float(request["learning_rate"]),
            int(request["rank"]),
        )
        if (
            not 1 <= epochs <= 10
            or not 1e-6 <= rate <= 1e-3
            or rank not in {8, 16, 32, 64}
        ):
            raise ValueError("Invalid training parameters")
        from databricks.sdk.config import Config

        response = WorkspaceClient(
            config=Config(profile=settings["profile"], host=settings["host"])
        ).jobs.run_now(
            job_id=int(job_id),
            idempotency_token=directory.name,
            job_parameters={
                "manifest": manifest,
                "epochs": str(epochs),
                "learning_rate": str(rate),
                "rank": str(rank),
            },
        )
        return {
            "submitted": True,
            "run_id": response.run_id,
            "message": "Databricks job submitted; no model has been promoted",
        }
    mode = request.get("mode", "demo")
    synthetic = mode == "demo" or request.get("sample_plan") is True
    if mode not in {"demo", "recorded", "databricks"}:
        raise ValueError("Unknown extraction mode")
    overrides = {}
    if mode == "databricks":
        endpoint = settings["endpoint"]
        if not endpoint:
            raise ValueError(
                "Configure an endpoint in lab.local.json or MADMAPS_VLM_ENDPOINT"
            )
        overrides = {
            "adapter": "databricks",
            "endpoint": endpoint,
            "model_revision": settings["model_revision"],
            "api_format": settings["api_format"],
            "profile": settings["profile"],
            "host": settings["host"],
        }
    if action == "benchmark":
        report = benchmark(
            root / "examples" / "manifest.json",
            directory / "benchmark",
            repeats=3,
            overrides=overrides,
        )
        return {"benchmark": report, "synthetic": True, "inference_mode": mode}
    if action != "extract":
        raise ValueError("Unknown workbench action")
    config = load_json(root / "examples" / "config.json")
    config.update(
        input=str(root / "examples" / "plan.png"),
        recorded_output=str(root / "examples" / "recorded.json"),
        output_dir=str(directory / "pipeline"),
        graph_id=f"lab-{directory.name}",
    )
    truth = (
        load_json(root / "examples" / "ground_truth.json")
        if synthetic
        else request.get("ground_truth")
    )
    if not synthetic:
        data = base64.b64decode(request["file_base64"], validate=True)
        if not 0 < len(data) <= 8 * 1024 * 1024:
            raise ValueError("Upload a plan of at most 8 MB")
        extension = Path(request["file_name"]).suffix.lower()
        if extension not in {".png", ".jpg", ".jpeg", ".pdf"}:
            raise ValueError("Use PNG, JPEG, or PDF")
        source = directory / f"upload{extension}"
        source.write_bytes(data)
        config.update(
            input=str(source),
            calibration=request.get("calibration"),
            page=int(request.get("page", 0)),
        )
        if mode == "recorded":
            recorded = directory / "recorded.json"
            write_json(recorded, request["recorded_extraction"])
            config["recorded_output"] = str(recorded)
    config.update(overrides)
    result = run(config)
    payload = {
        "result": result,
        "synthetic": synthetic,
        "inference_mode": mode,
        "metrics": None,
    }
    if result["status"] == "failed":
        return payload
    artifacts = Path(result["artifact_dir"])
    extraction = load_json(artifacts / "extraction.json")
    payload["extraction"] = extraction
    graph_path = artifacts / "graph_candidate.json"
    payload["graph"] = load_json(graph_path) if graph_path.exists() else None
    payload["plan_base64"] = base64.b64encode(
        Path(result["metadata"]["image"]).read_bytes()
    ).decode()
    confidences = [
        item["confidence"]
        for group in ("rooms", "walls", "doors", "walkable_areas")
        for item in extraction[group]
    ]
    payload["mean_confidence"] = (
        sum(confidences) / len(confidences) if confidences else None
    )
    if truth is not None:
        validate(truth, result["metadata"])
        payload["metrics"] = score(extraction, truth)
        payload["metrics"]["navigation"] = (
            navigation_metrics(payload["graph"], truth, [], 10)
            if payload["graph"]
            else None
        )
    return payload


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--request", required=True)
    args = parser.parse_args()
    request_path = Path(args.request).resolve()
    root = Path(__file__).resolve().parents[1]
    try:
        payload = execute(load_json(request_path), request_path.parent, root)
        response = {"status": "completed", "payload": payload}
    except Exception as error:  # noqa: BLE001 - worker boundary with sanitized error output
        safe_message = (
            str(error)[:250]
            if type(error) is ValueError
            else "Worker failed; inspect configuration and input schema"
        )
        response = {
            "status": "failed",
            "error": safe_message,
            "error_type": type(error).__name__,
        }
    temporary = request_path.parent / "response.tmp.json"
    write_json(temporary, response)
    temporary.replace(request_path.parent / "response.json")


if __name__ == "__main__":
    main()
