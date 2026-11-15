"""Fast wall-free adaptation, followed by a two-plan pilot before broader checks."""

import json
import os
import tempfile
from datetime import UTC, datetime
from pathlib import Path

from run_training_trial import (
    DATA_ROOT,
    REVISION,
    run_stage,
    unpack_source,
    verify_file,
    write_json,
)

SOURCE = "madmaps-training-source-fast-v3.zip"
SOURCE_SHA256 = "9e29c2b4cb2eeb58b7925e28e6ac56e625ab29bb55dc28fa5db37980a64577f6"
DATASET_SHA256 = "ad859398c4b525598256085329add2c5eb5862a71597c7d7d209284a54c24b68"
PARENT_MODEL = (
    DATA_ROOT.parent / "training/cubicasa5k-20261115-trial-02-liger/candidate/merged"
)


def pilot_passes(report):
    return len(report["runs"]) == 2 and all(
        row["status"] == "scored" and row["metrics"]["rooms"]["f1"] >= 0.5
        for row in report["runs"]
    )


def main():
    trial = DATA_ROOT.parent / "training/cubicasa5k-20261115-trial-03-fast"
    trial.mkdir(parents=True, exist_ok=False)
    state = {
        "status": "running",
        "stage": "prepare",
        "profile": "fast-map-v1",
        "started_at": datetime.now(UTC).isoformat(),
        "completed_stages": [],
        "walls_generated": False,
        "walls_evaluated": False,
        "quality_gate_passed": False,
        "parent_model": str(PARENT_MODEL),
        "training_source_sha256": SOURCE_SHA256,
        "train_examples": 64,
        "epochs": 3,
        "max_new_tokens": 4096,
        "promoted": False,
    }
    write_json(trial / "status.json", state)
    try:
        verify_file(DATA_ROOT / SOURCE, SOURCE_SHA256)
        verify_file(DATA_ROOT / "madmaps-public-dataset.zip", DATASET_SHA256)
        with tempfile.TemporaryDirectory(prefix="madmaps-fast-") as temporary:
            source, dataset = Path(temporary) / "source", Path(temporary) / "dataset"
            unpack_source(DATA_ROOT / SOURCE, source)
            unpack_source(DATA_ROOT / "madmaps-public-dataset.zip", dataset)
            environment = dict(os.environ)
            environment["PYTHONPATH"] = (
                str(source) + os.pathsep + environment.get("PYTHONPATH", "")
            )
            common = [
                "--manifest",
                str(dataset / "manifest.json"),
                "--allow-public-annotations",
                "--max-pixels",
                "262144",
                "--extraction-profile",
                "fast",
            ]
            state["stage"] = "candidate"
            write_json(trial / "status.json", state)
            run_stage(
                "candidate",
                "madmaps_extraction.training",
                [
                    *common,
                    "--model-id",
                    str(PARENT_MODEL),
                    "--revision",
                    REVISION,
                    "--use-liger-kernel",
                    "--rank",
                    "16",
                    "--learning-rate",
                    "0.0002",
                    "--epochs",
                    "3",
                    "--output",
                    str(trial / "candidate"),
                ],
                trial,
                environment,
            )
            state["completed_stages"].append("candidate")
            state["stage"] = "pilot-validation"
            write_json(trial / "status.json", state)
            evaluate = [
                *common,
                "--model",
                str(trial / "candidate/merged"),
                "--max-new-tokens",
                "4096",
            ]
            run_stage(
                "pilot-validation",
                "madmaps_extraction.evaluate_vlm",
                [
                    *evaluate,
                    "--limit",
                    "2",
                    "--output",
                    str(trial / "pilot-validation"),
                ],
                trial,
                environment,
                2,
            )
            state["completed_stages"].append("pilot-validation")
            pilot = json.loads((trial / "pilot-validation/evaluation.json").read_text())
            state["pilot_passed"] = pilot_passes(pilot)
            state["pilot_valid_predictions"] = sum(
                row["status"] == "scored" for row in pilot["runs"]
            )
            if state["pilot_passed"]:
                state["stage"] = "validation"
                write_json(trial / "status.json", state)
                run_stage(
                    "validation",
                    "madmaps_extraction.evaluate_vlm",
                    [*evaluate, "--output", str(trial / "validation")],
                    trial,
                    environment,
                    8,
                )
                report = json.loads((trial / "validation/evaluation.json").read_text())
                state["completed_stages"].append("validation")
                state["quality_gate_passed"] = all(
                    row["status"] == "scored"
                    and all(
                        row["metrics"][key]["f1"] >= 0.8
                        for key in ("rooms", "doors", "walkable_areas")
                    )
                    for row in report["runs"]
                )
            else:
                state["broader_validation_skipped"] = (
                    "Pilot did not pass; preserve GPU time and inspect evidence first"
                )
            state.update(status="complete", completed_at=datetime.now(UTC).isoformat())
    except BaseException as error:
        state.update(status="failed", error_type=type(error).__name__)
        write_json(trial / "status.json", state)
        raise
    write_json(trial / "status.json", state)
    print(json.dumps(state, indent=2), flush=True)


if __name__ == "__main__":
    main()
