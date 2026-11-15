"""Run on GPU compute after installing .[vlm]. Does not create paid serving resources."""

import argparse
from pathlib import Path

import mlflow
from huggingface_hub import snapshot_download
from mlflow.models import ModelSignature
from mlflow.types import ColSpec, Schema

from madmaps_extraction.vlm import FloorPlanVLM


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-id", default="Qwen/Qwen2.5-VL-3B-Instruct")
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--revision", help="Pinned Hugging Face commit SHA")
    source.add_argument("--local-weights", help="Merged fine-tuned model directory")
    parser.add_argument("--registered-name", required=True, help="catalog.schema.model")
    args = parser.parse_args()
    if args.revision and (
        len(args.revision) != 40
        or any(c not in "0123456789abcdef" for c in args.revision)
    ):
        parser.error("revision must be a full lowercase commit SHA")
    weights = (
        str(Path(args.local_weights).resolve())
        if args.local_weights
        else snapshot_download(args.model_id, revision=args.revision)
    )
    if not Path(weights, "config.json").is_file():
        parser.error("Model directory must contain a complete merged model")
    mlflow.set_registry_uri("databricks-uc")
    signature = ModelSignature(
        inputs=Schema([ColSpec("string", "image_base64"), ColSpec("string", "prompt")]),
        outputs=Schema([ColSpec("string")]),
    )
    # Infer environment versions from the actual GPU environment rather than moving ranges.
    from importlib.metadata import version

    requirements = [
        f"{name}=={version(name)}"
        for name in (
            "mlflow",
            "torch",
            "transformers",
            "accelerate",
            "Pillow",
            "pandas",
        )
    ]
    with mlflow.start_run():
        model = mlflow.pyfunc.log_model(
            name="floorplan-vlm",
            python_model=FloorPlanVLM(),
            artifacts={"weights": weights},
            signature=signature,
            registered_model_name=args.registered_name,
            code_paths=["madmaps_extraction"],
            pip_requirements=requirements,
        )
        mlflow.log_params(
            {
                "huggingface_model": args.model_id,
                "weights_revision": args.revision or "local-fine-tuned",
            }
        )
        print(model.model_uri)


if __name__ == "__main__":
    main()
