"""Evaluate local GPU weights on reviewed held-out images without a serving bill."""

import argparse
import hashlib
import json
import re
import time
from pathlib import Path

from PIL import Image

from .adapters import prompt
from .benchmark import score
from .contract import validate
from .fast_extraction import FastDecoder
from .pipeline import write_json
from .training import dataset_summary, load_reviewed_dataset


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True)
    parser.add_argument(
        "--allow-public-annotations",
        action="store_true",
        help="Explicitly evaluate against provenance-tracked public converted labels",
    )
    parser.add_argument(
        "--model", required=True, help="Base HF model ID or merged weights directory"
    )
    parser.add_argument(
        "--revision", help="Required immutable revision for a remote base model"
    )
    parser.add_argument("--split", choices=["validation", "test"], default="validation")
    parser.add_argument("--output", required=True)
    parser.add_argument("--max-pixels", type=int, default=1024 * 1024)
    parser.add_argument(
        "--extraction-profile", choices=["full", "fast"], default="full"
    )
    parser.add_argument("--max-new-tokens", type=int, default=8192)
    parser.add_argument(
        "--limit",
        type=int,
        help="Bounded validation pilot; never used to declare readiness",
    )
    args = parser.parse_args()
    if not Path(args.model).is_dir() and not re.fullmatch(
        r"[0-9a-f]{40}", args.revision or ""
    ):
        parser.error("Remote models require --revision with a full commit SHA")
    partitions = load_reviewed_dataset(
        args.manifest, allow_public_annotations=args.allow_public_annotations
    )
    if not partitions[args.split]:
        parser.error(f"No reviewed examples in {args.split}")
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=False)
    import torch
    from transformers import AutoModelForImageTextToText, AutoProcessor

    if not torch.cuda.is_available():
        raise RuntimeError("Evaluation requires CUDA GPU compute")
    processor = AutoProcessor.from_pretrained(
        args.model, revision=args.revision, max_pixels=args.max_pixels
    )
    model = AutoModelForImageTextToText.from_pretrained(
        args.model, revision=args.revision, torch_dtype="auto", device_map="auto"
    ).eval()
    decoder = (
        FastDecoder(model, processor) if args.extraction_profile == "fast" else None
    )
    records = []
    selected_rows = (
        partitions[args.split][: args.limit] if args.limit else partitions[args.split]
    )
    for index, row in enumerate(selected_rows):
        record = {"image_sha256": row["image_sha256"], "group": row["group"]}
        started = time.perf_counter()
        try:
            with Image.open(row["image_path"]) as source:
                image = source.convert("RGB")
            if decoder is not None:
                raw, generation = decoder.generate(
                    image, max_new_tokens=args.max_new_tokens
                )
                record.update(generation)
            else:
                messages = [
                    {
                        "role": "user",
                        "content": [
                            {"type": "image"},
                            {"type": "text", "text": prompt(row["metadata"])},
                        ],
                    }
                ]
                text = processor.apply_chat_template(
                    messages, tokenize=False, add_generation_prompt=True
                )
                inputs = processor(text=[text], images=[image], return_tensors="pt").to(
                    model.device
                )
                with torch.inference_mode():
                    generated = model.generate(
                        **inputs, do_sample=False, max_new_tokens=args.max_new_tokens
                    )
                raw = processor.batch_decode(
                    generated[:, inputs.input_ids.shape[1] :], skip_special_tokens=True
                )[0]
            (output / f"{index:04d}-raw.txt").write_text(raw)
            fenced = re.fullmatch(r"\s*```(?:json)?\s*\n([\s\S]*?)\n```\s*", raw)
            if decoder is not None:
                if not record["generation_complete"]:
                    raise ValueError("Generation reached its token limit")
                prediction = decoder.parse(raw, row["metadata"])
            else:
                prediction = json.loads(fenced.group(1) if fenced else raw)
            validate(prediction, row["metadata"])
            write_json(output / f"{index:04d}-extraction.json", prediction)
            metrics = score(prediction, row["target_json"])
            if args.extraction_profile == "fast":
                metrics.pop("walls", None)
            record.update(status="scored", metrics=metrics)
        except Exception as error:  # noqa: BLE001 - record each failed example in the denominator
            # Retain failures in the denominator without copying sensitive exception bodies.
            record.update(status="failed", error_type=type(error).__name__)
            if isinstance(error, ValueError):
                record["issue"] = str(error)[:200]
        record["latency_s"] = time.perf_counter() - started
        records.append(record)
        write_json(
            output / "evaluation.json",
            {
                "model": args.model,
                "revision": args.revision,
                "manifest_sha256": hashlib.sha256(
                    Path(args.manifest).read_bytes()
                ).hexdigest(),
                "split": args.split,
                "dataset": dataset_summary(partitions),
                "public_annotations_enabled": args.allow_public_annotations,
                "max_pixels": args.max_pixels,
                "extraction_profile": args.extraction_profile,
                "walls_evaluated": args.extraction_profile != "fast",
                "max_new_tokens": args.max_new_tokens,
                "pilot_limit": args.limit,
                "runs": records,
                "failure_rate": sum(r["status"] == "failed" for r in records)
                / len(records),
                "navigation_evaluated": False,
            },
        )
    print(output / "evaluation.json")
    if any(record["status"] == "failed" for record in records):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
