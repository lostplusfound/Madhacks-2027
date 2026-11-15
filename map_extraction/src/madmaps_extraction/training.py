"""Reviewed dataset validation and optional GPU LoRA training (no automatic deployment)."""

import argparse
import hashlib
import json
import re
from importlib.metadata import version
from pathlib import Path

from PIL import Image

from .adapters import prompt
from .contract import load_json, validate
from .pipeline import write_json
from .workbench import resolve_under


def dataset_summary(partitions):
    return {
        split: {
            "examples": len(rows),
            "groups": sorted({row["group"] for row in rows}),
            "max_image_pixels": max(
                (row["metadata"]["width"] * row["metadata"]["height"] for row in rows),
                default=0,
            ),
        }
        for split, rows in partitions.items()
    }


class VisionCollator:
    """TRL 0.21 needs explicit multimodal collation; supervise the answer only."""

    def __init__(self, processor):
        self.processor = processor
        self.processor.tokenizer.padding_side = "right"

    def __call__(self, examples):
        processor = self.processor
        texts = [
            processor.apply_chat_template(e["messages"], tokenize=False)
            for e in examples
        ]
        prefixes = [
            processor.apply_chat_template(
                e["messages"][:-1], tokenize=False, add_generation_prompt=True
            )
            for e in examples
        ]
        images = [e["images"] for e in examples]
        batch = processor(text=texts, images=images, return_tensors="pt", padding=True)
        prefix_batch = processor(
            text=prefixes, images=images, return_tensors="pt", padding=True
        )
        labels = batch["input_ids"].clone()
        labels[batch["attention_mask"] == 0] = -100
        for index, length in enumerate(prefix_batch["attention_mask"].sum(dim=1)):
            length = int(length)
            if length >= int(batch["attention_mask"][index].sum()):
                raise ValueError("Training example has no answer tokens")
            if not (
                batch["input_ids"][index, :length]
                == prefix_batch["input_ids"][index, :length]
            ).all():
                raise ValueError("Chat template prefix does not match training answer")
            labels[index, :length] = -100
        batch["labels"] = labels
        return batch


def load_reviewed_dataset(manifest_path):
    path = Path(manifest_path).resolve()
    manifest = load_json(path)
    groups, images, sources = {}, {}, {}
    partitions = {"train": [], "validation": [], "test": []}
    for row in manifest["examples"]:
        if row.get("synthetic", False):
            continue
        split, group = row["split"], row["group"]
        if split not in partitions or not group or row.get("reviewed") is not True:
            raise ValueError(
                "Every real example needs a review, source group, and valid split"
            )
        image_path = resolve_under(path.parent, row["image"])
        target_path = resolve_under(path.parent, row["target"])
        digest = hashlib.sha256(image_path.read_bytes()).hexdigest()
        if row.get("image_sha256") != digest:
            raise ValueError("Reviewed image checksum mismatch")
        for index, key in (
            (groups, group),
            (images, digest),
            (sources, row["source_sha256"]),
        ):
            if key in index and index[key] != split:
                raise ValueError(
                    "Building, source, or image leakage across dataset splits"
                )
            index[key] = split
        if any(existing["image_sha256"] == digest for existing in partitions[split]):
            raise ValueError("Duplicate training/validation image")
        with Image.open(image_path) as image:
            metadata = {"width": image.width, "height": image.height}
        target = validate(load_json(target_path), metadata)
        partitions[split].append(
            {
                **row,
                "image_path": str(image_path),
                "target_json": target,
                "metadata": metadata,
            }
        )
    if not partitions["train"] or not partitions["validation"]:
        raise ValueError(
            "Provide real reviewed train and validation examples from separate source groups"
        )
    return partitions


def main():
    parser = argparse.ArgumentParser(
        description="GPU LoRA fine-tuning on reviewed floor plans"
    )
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--output")
    parser.add_argument("--model-id", default="Qwen/Qwen2.5-VL-3B-Instruct")
    parser.add_argument("--revision")
    parser.add_argument("--epochs", type=int, default=1)
    parser.add_argument("--learning-rate", type=float, default=1e-4)
    parser.add_argument("--rank", type=int, default=16)
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Check labels without GPU imports or network calls",
    )
    parser.add_argument(
        "--max-steps",
        type=int,
        default=-1,
        help="Positive optimizer-step limit for smoke tests; -1 uses epochs",
    )
    parser.add_argument(
        "--max-pixels",
        type=int,
        default=1024 * 1024,
        help="Qwen visual token budget; canonical label coordinates stay unchanged",
    )
    args = parser.parse_args()
    partitions = load_reviewed_dataset(args.manifest)
    if args.validate_only:
        print(json.dumps(dataset_summary(partitions), indent=2))
        return
    if not args.output:
        parser.error("--output is required for training")
    if not args.revision or not re.fullmatch(r"[0-9a-f]{40}", args.revision):
        parser.error("revision must be a full Hugging Face commit SHA")
    if (
        not 1 <= args.epochs <= 10
        or not 1e-6 <= args.learning_rate <= 1e-3
        or args.rank not in {8, 16, 32, 64}
        or args.max_steps == 0
        or args.max_steps < -1
        or args.max_pixels < 56 * 56
    ):
        parser.error("Invalid training hyperparameters")
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=False)
    # Heavy dependencies are optional so local review/export never requires a GPU.
    import torch
    from datasets import Dataset
    from datasets import Image as DatasetImage
    from peft import LoraConfig
    from transformers import AutoModelForImageTextToText, AutoProcessor, set_seed
    from trl import SFTConfig, SFTTrainer

    if not torch.cuda.is_available():
        raise RuntimeError("Fine-tuning requires CUDA GPU compute")
    set_seed(42)
    processor = AutoProcessor.from_pretrained(
        args.model_id, revision=args.revision, max_pixels=args.max_pixels
    )
    dtype = torch.bfloat16 if torch.cuda.is_bf16_supported() else torch.float16
    model = AutoModelForImageTextToText.from_pretrained(
        args.model_id, revision=args.revision, torch_dtype=dtype
    )
    model.config.use_cache = False

    def dataset(rows):
        examples = []
        for row in rows:
            examples.append(
                {
                    "images": [row["image_path"]],
                    "messages": [
                        {
                            "role": "user",
                            "content": [
                                {"type": "image"},
                                {"type": "text", "text": prompt(row["metadata"])},
                            ],
                        },
                        {
                            "role": "assistant",
                            "content": [
                                {"type": "text", "text": json.dumps(row["target_json"])}
                            ],
                        },
                    ],
                }
            )
        # datasets 4 changed Sequence(dict) behavior; a list feature works in 3/4.
        return Dataset.from_list(examples).cast_column("images", [DatasetImage()])

    config = SFTConfig(
        output_dir=str(output / "checkpoints"),
        num_train_epochs=args.epochs,
        max_steps=args.max_steps,
        learning_rate=args.learning_rate,
        per_device_train_batch_size=1,
        per_device_eval_batch_size=1,
        gradient_accumulation_steps=4,
        gradient_checkpointing=True,
        gradient_checkpointing_kwargs={"use_reentrant": False},
        max_length=None,
        bf16=dtype == torch.bfloat16,
        fp16=dtype == torch.float16,
        eval_strategy="epoch",
        save_strategy="epoch",
        save_total_limit=1,
        logging_steps=1,
        report_to="none",
        seed=42,
        remove_unused_columns=False,
        dataset_kwargs={"skip_prepare_dataset": True},
    )
    trainer = SFTTrainer(
        model=model,
        args=config,
        train_dataset=dataset(partitions["train"]),
        eval_dataset=dataset(partitions["validation"]),
        processing_class=processor,
        data_collator=VisionCollator(processor),
        peft_config=LoraConfig(
            r=args.rank,
            lora_alpha=args.rank * 2,
            lora_dropout=0.05,
            target_modules=["q_proj", "v_proj"],
            task_type="CAUSAL_LM",
        ),
    )
    trainer.train()
    evaluation = trainer.evaluate()
    trainer.save_model(str(output / "adapter"))
    processor.save_pretrained(str(output / "adapter"))
    # Produce a self-contained model usable by the existing MLflow wrapper.
    merged = trainer.model.merge_and_unload()
    merged.config.use_cache = True
    merged.save_pretrained(str(output / "merged"), safe_serialization=True)
    processor.save_pretrained(str(output / "merged"))
    write_json(
        output / "training_result.json",
        {
            "base_model": args.model_id,
            "revision": args.revision,
            "manifest_sha256": hashlib.sha256(
                Path(args.manifest).read_bytes()
            ).hexdigest(),
            "train_examples": len(partitions["train"]),
            "validation_examples": len(partitions["validation"]),
            "held_out_test_examples": len(partitions["test"]),
            "evaluation": evaluation,
            "epochs": args.epochs,
            "learning_rate": args.learning_rate,
            "rank": args.rank,
            "max_steps": args.max_steps,
            "max_pixels": args.max_pixels,
            "global_step": trainer.state.global_step,
            "smoke_test": args.max_steps > 0,
            "environment": {
                name: version(name)
                for name in (
                    "torch",
                    "transformers",
                    "trl",
                    "peft",
                    "datasets",
                    "accelerate",
                )
            },
            "seed": 42,
            "promoted": False,
        },
    )


if __name__ == "__main__":
    main()
