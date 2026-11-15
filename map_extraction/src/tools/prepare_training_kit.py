"""Build a credential-free source ZIP and Colab/Databricks notebook locally."""

import json
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "runs" / "training-kit"


def cell(kind, source):
    result = {"cell_type": kind, "metadata": {}, "source": source.splitlines(True)}
    if kind == "code":
        result.update(execution_count=None, outputs=[])
    return result


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    # Reviewable draft only. This script never calls a cloud API.
    (DEST / "databricks-cluster-draft.json").write_text(
        json.dumps(
            {
                "cluster_name": "madmaps-training-trial",
                "spark_version": "16.4.x-gpu-ml-scala2.13",
                "node_type_id": "g6e.2xlarge",
                "num_workers": 0,
                "spark_conf": {
                    "spark.databricks.cluster.profile": "singleNode",
                    "spark.master": "local[*]",
                },
                "custom_tags": {
                    "ResourceClass": "SingleNode",
                    "Project": "MadMaps-training-trial",
                },
                "data_security_mode": "SINGLE_USER",
                "autotermination_minutes": 15,
                "aws_attributes": {"availability": "ON_DEMAND", "zone_id": "auto"},
            },
            indent=2,
        )
    )
    paths = [ROOT / "pyproject.toml", ROOT / "databricks/register_vlm.py"]
    paths += sorted((ROOT / "madmaps_extraction").glob("*.py"))
    paths += sorted((ROOT / "madmaps_extraction").glob("*.json"))
    with ZipFile(DEST / "madmaps-training-source.zip", "w", ZIP_DEFLATED) as archive:
        for path in paths:
            archive.write(path, path.relative_to(ROOT))
    cells = [
        cell(
            "markdown",
            """# MadMaps GPU training trial
This notebook does not provision compute or deploy serving endpoints. Running cells uses
your selected runtime: choose a **free Colab GPU** to attempt training without paid compute,
or use an already authorized Databricks GPU runtime. Free GPU access/memory is not guaranteed.
GPU training is not yet verified. Do not use synthetic demo labels as real training data.

Upload `madmaps-training-source.zip` and your exported `madmaps-reviewed-dataset.zip`.
On Colab: Runtime → Change runtime type → GPU, then run the upload cell.
On Databricks: skip the upload cell and set paths to ZIPs you uploaded to a Volume.
""",
        ),
        cell(
            "code",
            """# Colab only: choose the two ZIPs. No credentials belong in either ZIP.
from google.colab import files
uploaded = files.upload()
""",
        ),
        cell(
            "code",
            """from pathlib import Path
from zipfile import ZipFile
import subprocess, sys

# On Databricks, replace these with /Volumes/... paths and use a writable work directory.
SOURCE_ZIP = Path("madmaps-training-source.zip")
DATASET_ZIP = Path("madmaps-reviewed-dataset.zip")
WORK = Path("/tmp/madmaps-training-trial")

def unpack(archive_path, destination):
    destination.mkdir(parents=True, exist_ok=False)
    with ZipFile(archive_path) as archive:
        for item in archive.infolist():
            if not (destination / item.filename).resolve().is_relative_to(destination.resolve()):
                raise ValueError("ZIP path escapes destination")
            if (item.external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError("ZIP symlinks are not supported")
        archive.extractall(destination)

WORK.mkdir(parents=True, exist_ok=True)
unpack(SOURCE_ZIP, WORK / "source")
unpack(DATASET_ZIP, WORK / "dataset")
subprocess.run([sys.executable, "-m", "pip", "install", str(WORK / "source") + "[training,vlm]"], check=True)
# If your notebook runtime requests a Python restart, restart and rerun only the next cells.
""",
        ),
        cell(
            "code",
            """from pathlib import Path
import subprocess, sys
WORK = Path("/tmp/madmaps-training-trial")
MANIFEST = WORK / "dataset/manifest.json"
subprocess.run([sys.executable, "-m", "madmaps_extraction.training", "--manifest", str(MANIFEST), "--validate-only"], check=True)
import torch
assert torch.cuda.is_available(), "Select a GPU runtime first"
print(torch.cuda.get_device_name(0))
print("GPU memory GiB:", torch.cuda.get_device_properties(0).total_memory / 2**30)
""",
        ),
        cell(
            "code",
            """# Resolve the base model once and preserve its exact revision for comparisons.
from huggingface_hub import model_info
MODEL = "Qwen/Qwen2.5-VL-3B-Instruct"
REVISION = model_info(MODEL).sha
(WORK / "base_revision.txt").write_text(REVISION)
print(MODEL, REVISION)
""",
        ),
        cell(
            "code",
            """# Baseline on validation data; test data remains untouched while tuning.
# This uses the runtime GPU, without creating a serving endpoint.
subprocess.run([sys.executable, "-m", "madmaps_extraction.evaluate_vlm",
    "--manifest", str(MANIFEST), "--model", MODEL, "--revision", REVISION,
    "--output", str(WORK / "baseline-validation"), "--max-pixels", "262144"], check=True)
""",
        ),
        cell(
            "code",
            """# Two optimizer steps prove integration, NOT model quality.
# The lower visual token budget is a memory-conscious trial, not a validated optimum.
subprocess.run([sys.executable, "-m", "madmaps_extraction.training",
    "--manifest", str(MANIFEST), "--revision", REVISION,
    "--output", str(WORK / "smoke"), "--max-steps", "2",
    "--max-pixels", "262144"], check=True)
""",
        ),
        cell(
            "code",
            """# Run only after the smoke test succeeds and there is enough GPU time remaining.
# For Colab free tier, stay within the runtime's usage allowance.
subprocess.run([sys.executable, "-m", "madmaps_extraction.training",
    "--manifest", str(MANIFEST), "--revision", REVISION,
    "--output", str(WORK / "candidate"), "--epochs", "1",
    "--max-pixels", "262144"], check=True)
""",
        ),
        cell(
            "code",
            """subprocess.run([sys.executable, "-m", "madmaps_extraction.evaluate_vlm",
    "--manifest", str(MANIFEST), "--model", str(WORK / "candidate/merged"),
    "--output", str(WORK / "candidate-validation"), "--max-pixels", "262144"], check=True)

import json
for name in ["baseline-validation", "candidate-validation"]:
    report = json.loads((WORK / name / "evaluation.json").read_text())
    print(name, "failure rate:", report["failure_rate"])
    for row in report["runs"]:
        print(row["group"], row["status"], row.get("metrics"))
# Inspect predictions as well. These reports do not measure navigation or calibrated scale.
# After selecting the model, evaluate base/candidate on --split test using new output paths.
""",
        ),
        cell(
            "code",
            """# Preserve reports, adapter and processor before a free runtime expires.
# Downloading the full merged weights is optional and can be several GB.
import shutil
EVIDENCE = WORK / "evidence"
EVIDENCE.mkdir(exist_ok=False)
for name in ["baseline-validation", "candidate-validation"]:
    shutil.copytree(WORK / name, EVIDENCE / name)
shutil.copytree(WORK / "candidate/adapter", EVIDENCE / "adapter")
shutil.copy(WORK / "candidate/training_result.json", EVIDENCE)
shutil.copy(WORK / "base_revision.txt", EVIDENCE)
shutil.make_archive(str(WORK / "madmaps-training-evidence"), "zip", EVIDENCE)
# Colab: files.download(str(WORK / "madmaps-training-evidence.zip"))
# Databricks: copy the ZIP/model to your writable Volume before terminating compute.
""",
        ),
        cell(
            "markdown",
            """## Optional registration after evaluation
On authenticated Databricks GPU compute, run the packaged `databricks/register_vlm.py`
with `--local-weights /path/to/candidate/merged --registered-name catalog.schema.model`.
Model registration and serving are separate: this notebook never creates an endpoint
or changes the live app. Do not deploy paid serving without a budget authorization.
If training runs in Colab, describe it as Colab training; Databricks inference remains
a separate, real integration. Do not claim training ran on Databricks.
""",
        ),
    ]
    notebook = {
        "nbformat": 4,
        "nbformat_minor": 5,
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3",
            }
        },
        "cells": cells,
    }
    for index, entry in enumerate(cells):
        entry["id"] = f"madmaps-{index:02d}"
    (DEST / "train_floorplans.ipynb").write_text(json.dumps(notebook, indent=2))
    print(DEST)


if __name__ == "__main__":
    main()
