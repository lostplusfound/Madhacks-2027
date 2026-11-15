import contextlib
import io
import json
import unittest
from unittest.mock import patch

import numpy as np

from madmaps_extraction.training import VisionCollator, main


class Tensor(np.ndarray):
    """Exercise masking without installing PyTorch on the laptop."""

    def clone(self):
        return self.copy()

    def sum(self, dim=None, **kwargs):
        return super().sum(axis=dim, **kwargs)


class Processor:
    def __init__(self):
        self.tokenizer = type("Tokenizer", (), {"padding_side": "left"})()
        self.calls = 0

    def apply_chat_template(self, messages, **kwargs):
        return "prefix" if kwargs.get("add_generation_prompt") else "complete"

    def __call__(self, **kwargs):
        self.calls += 1
        tokens = (
            [[11, 12, 21, 22], [11, 12, 21, 0]]
            if self.calls == 1
            else [[11, 12], [11, 12]]
        )
        ids = np.array(tokens).view(Tensor)
        return {"input_ids": ids, "attention_mask": (ids != 0).astype(int).view(Tensor)}


class TrainingTests(unittest.TestCase):
    def test_collator_masks_image_prompt_and_padding_but_keeps_answers(self):
        processor = Processor()
        collator = VisionCollator(processor)
        examples = [
            {
                "messages": [{"role": "user"}, {"role": "assistant"}],
                "images": [object()],
            }
        ] * 2
        batch = collator(examples)
        np.testing.assert_array_equal(
            batch["labels"], [[-100, -100, 21, 22], [-100, -100, 21, -100]]
        )
        self.assertEqual(processor.tokenizer.padding_side, "right")

    def test_collator_rejects_mismatched_chat_prefix(self):
        class BadProcessor(Processor):
            def __call__(self, **kwargs):
                result = super().__call__(**kwargs)
                if self.calls == 2:
                    result["input_ids"][0, 0] = 99
                return result

        with self.assertRaisesRegex(ValueError, "prefix"):
            VisionCollator(BadProcessor())(
                [{"messages": [{}, {}], "images": [object()]}] * 2
            )

    def test_validation_does_not_need_revision_output_or_gpu(self):
        partitions = {
            "train": [{"group": "a", "metadata": {"width": 100, "height": 200}}],
            "validation": [],
            "test": [],
        }
        output = io.StringIO()
        with (
            patch("sys.argv", ["training", "--manifest", "unused", "--validate-only"]),
            patch(
                "madmaps_extraction.training.load_reviewed_dataset",
                return_value=partitions,
            ),
            contextlib.redirect_stdout(output),
        ):
            main()
        report = json.loads(output.getvalue())
        self.assertEqual(report["train"]["examples"], 1)
        self.assertEqual(report["train"]["max_image_pixels"], 20000)


if __name__ == "__main__":
    unittest.main()
