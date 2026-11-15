"""Run a bounded baseline -> smoke -> one-epoch VLM trial on Databricks."""

import hashlib
import json
import os
import runpy
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import UTC, datetime
from pathlib import Path
from zipfile import ZipFile

DATA_ROOT = Path(
    "/Volumes/workspace/default/madmaps_training/cubicasa5k-trial-c7713c30f808"
)
MODEL = "Qwen/Qwen2.5-VL-3B-Instruct"
REVISION = "66285546d2b821cf421d4f5eb2576359d3770cd3"
SOURCE_ARCHIVE = "madmaps-training-source-liger-v2.zip"
SOURCE_SHA256 = "4504f8ce7799acba28a7fce6ed5fbc8232ab3d5198610eab9ff305699f2ca85d"
MANIFEST_SHA256 = "c7713c30f80871606f1dfcd62e8131ab0236220bfa1fb6aa0d543cba4905f334"
DATASET_SHA256 = "ad859398c4b525598256085329add2c5eb5862a71597c7d7d209284a54c24b68"
BASELINE_TRIAL = "cubicasa5k-20261115-trial-01"
BASELINE_SHA256 = "cbc0a07826acc7307521dbbfdcddeb79b662fdf4756dbfe25d127998c576b7c3"


def verify_baseline(report):
    expected = {
        "model": MODEL,
        "revision": REVISION,
        "manifest_sha256": MANIFEST_SHA256,
        "split": "validation",
        "max_pixels": 262144,
        "public_annotations_enabled": True,
    }
    if (
        any(report.get(key) != value for key, value in expected.items())
        or len(report.get("runs", [])) != 8
    ):
        raise ValueError("Saved baseline does not match the resumed trial")


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, allow_nan=False) + "\n")


def verify_file(path, expected):
    if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise ValueError(f"Training input checksum mismatch: {path.name}")


def unpack_source(archive_path, destination):
    destination.mkdir()
    with ZipFile(archive_path) as archive:
        for entry in archive.infolist():
            target = (destination / entry.filename).resolve()
            if not target.is_relative_to(destination.resolve()):
                raise ValueError("Training source ZIP path escapes destination")
            if (entry.external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError("Training source ZIP contains a symlink")
        archive.extractall(destination)


def worker(module, metrics_path, arguments):
    import torch

    started = time.monotonic()
    torch.cuda.reset_peak_memory_stats()
    sys.argv = [module, *arguments]
    try:
        runpy.run_module(module, run_name="__main__")
    finally:
        write_json(
            Path(metrics_path),
            {
                "module": module,
                "elapsed_seconds": time.monotonic() - started,
                "gpu": torch.cuda.get_device_name(0),
                "peak_allocated_bytes": torch.cuda.max_memory_allocated(),
                "peak_reserved_bytes": torch.cuda.max_memory_reserved(),
            },
        )


def run_stage(name, module, arguments, trial, environment, expected_predictions=None):
    command = [
        sys.executable,
        "-u",
        str(Path(__file__).resolve()),
        "worker",
        module,
        str(trial / f"{name}-runtime.json"),
        *arguments,
    ]
    print(f"Starting stage: {name}", flush=True)
    with (
        (trial / f"{name}.log").open("w") as log,
        subprocess.Popen(
            command,
            env=environment,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        ) as process,
    ):
        for line in process.stdout:
            print(line, end="", flush=True)
            log.write(line)
            log.flush()
        code = process.wait()
    if expected_predictions is not None:
        report_path = trial / name / "evaluation.json"
        report = json.loads(report_path.read_text()) if report_path.is_file() else {}
        complete = len(report.get("runs", [])) == expected_predictions
        # The evaluator exits 1 for invalid predictions, which are a measured
        # model-quality outcome, not a reason to discard the baseline evidence.
        if code not in {0, 1} or not complete:
            raise RuntimeError(
                f"{name} did not produce a complete evaluation report (exit {code})"
            )
        operational_errors = {
            "OutOfMemoryError",
            "RuntimeError",
            "ImportError",
            "ModuleNotFoundError",
            "OSError",
            "TypeError",
        }
        if any(row.get("error_type") in operational_errors for row in report["runs"]):
            raise RuntimeError(
                f"{name} encountered an execution error; later stages will not run"
            )
        print(f"{name}: failure rate {report['failure_rate']:.3f}", flush=True)
    elif code != 0:
        raise RuntimeError(
            f"{name} failed with exit code {code}; later stages will not run"
        )
    print(f"Completed stage: {name}", flush=True)


def main():
    trial_id = os.environ["MADMAPS_TRIAL_ID"]
    if not trial_id or any(
        c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
        for c in trial_id
    ):
        raise ValueError("Invalid training trial ID")
    trial = DATA_ROOT.parent / "training" / trial_id
    trial.mkdir(parents=True, exist_ok=False)
    state = {
        "trial_id": trial_id,
        "model": MODEL,
        "revision": REVISION,
        "manifest": str(DATA_ROOT / "manifest.json"),
        "manifest_sha256": MANIFEST_SHA256,
        "training_source_sha256": SOURCE_SHA256,
        "started_at": datetime.now(UTC).isoformat(),
        "stage": "validate",
        "status": "running",
        "completed_stages": [],
        "training_examples": 64,
        "validation_examples": 8,
        "held_out_test_examples": 8,
        "max_pixels": 262144,
        "epochs": 1,
        "rank": 16,
        "learning_rate": 0.0001,
        "public_annotations_enabled": True,
        "use_liger_kernel": True,
        "baseline_reused_from": BASELINE_TRIAL,
        "promoted": False,
    }
    write_json(trial / "status.json", state)
    print("Persistent artifacts:", trial, flush=True)
    try:
        verify_file(DATA_ROOT / "manifest.json", MANIFEST_SHA256)
        verify_file(DATA_ROOT / SOURCE_ARCHIVE, SOURCE_SHA256)
        verify_file(DATA_ROOT / "madmaps-public-dataset.zip", DATASET_SHA256)
        previous_baseline = (
            DATA_ROOT.parent / "training" / BASELINE_TRIAL / "baseline-validation"
        )
        verify_file(previous_baseline / "evaluation.json", BASELINE_SHA256)
        verify_baseline(json.loads((previous_baseline / "evaluation.json").read_text()))
        shutil.copytree(previous_baseline, trial / "baseline-validation")
        state["completed_stages"].append("baseline-validation-reused")
        write_json(trial / "status.json", state)
        print(
            "Reusing complete, checksum-verified baseline from",
            BASELINE_TRIAL,
            flush=True,
        )
        with tempfile.TemporaryDirectory(prefix="madmaps-vlm-") as temporary:
            source = Path(temporary) / "source"
            unpack_source(DATA_ROOT / SOURCE_ARCHIVE, source)
            dataset = Path(temporary) / "dataset"
            unpack_source(DATA_ROOT / "madmaps-public-dataset.zip", dataset)
            environment = dict(os.environ)
            environment["PYTHONPATH"] = (
                str(source) + os.pathsep + environment.get("PYTHONPATH", "")
            )
            environment["TOKENIZERS_PARALLELISM"] = "false"
            environment["HF_HOME"] = str(Path(temporary) / "hf-cache")
            environment["HF_HUB_DISABLE_XET"] = "1"
            common = [
                "--manifest",
                str(dataset / "manifest.json"),
                "--allow-public-annotations",
            ]
            subprocess.run(
                [
                    sys.executable,
                    "-m",
                    "madmaps_extraction.training",
                    *common,
                    "--validate-only",
                ],
                env=environment,
                check=True,
            )
            freeze = subprocess.run(
                [sys.executable, "-m", "pip", "freeze"],
                capture_output=True,
                text=True,
                check=True,
            )
            (trial / "environment.txt").write_text(freeze.stdout)
            evaluation = [*common, "--max-pixels", "262144"]
            training = [
                *evaluation,
                "--revision",
                REVISION,
                "--rank",
                "16",
                "--learning-rate",
                "0.0001",
                "--use-liger-kernel",
            ]
            stages = [
                (
                    "smoke",
                    "madmaps_extraction.training",
                    [
                        *training,
                        "--max-steps",
                        "2",
                        "--output",
                        str(Path(temporary) / "smoke"),
                    ],
                    None,
                ),
                (
                    "candidate",
                    "madmaps_extraction.training",
                    [*training, "--epochs", "1", "--output", str(trial / "candidate")],
                    None,
                ),
                (
                    "candidate-validation",
                    "madmaps_extraction.evaluate_vlm",
                    [
                        *evaluation,
                        "--model",
                        str(trial / "candidate/merged"),
                        "--output",
                        str(trial / "candidate-validation"),
                    ],
                    8,
                ),
            ]
            for name, module, arguments, predictions in stages:
                state["stage"] = name
                write_json(trial / "status.json", state)
                run_stage(name, module, arguments, trial, environment, predictions)
                if name == "smoke":
                    smoke = Path(temporary) / "smoke/training_result.json"
                    result = json.loads(smoke.read_text())
                    if result["global_step"] != 2:
                        raise RuntimeError(
                            "Smoke test did not complete two optimizer steps"
                        )
                    write_json(trial / "smoke-training-result.json", result)
                state["completed_stages"].append(name)
                write_json(trial / "status.json", state)
        state.update(status="complete", completed_at=datetime.now(UTC).isoformat())
    except BaseException as error:
        state.update(status="failed", error_type=type(error).__name__)
        write_json(trial / "status.json", state)
        raise
    write_json(trial / "status.json", state)
    print(
        "Trial completed. Candidate is saved; no model has been promoted.", flush=True
    )


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "worker":
        worker(sys.argv[2], sys.argv[3], sys.argv[4:])
    else:
        main()
