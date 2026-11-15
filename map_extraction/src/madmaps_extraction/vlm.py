"""Optional MLflow wrapper. Import only in a GPU environment with the vlm extra."""

import base64
import json
from io import BytesIO
from pathlib import Path

import mlflow.pyfunc
from PIL import Image


class FloorPlanVLM(mlflow.pyfunc.PythonModel):
    def load_context(self, context):
        import torch
        from transformers import AutoModelForImageTextToText, AutoProcessor

        settings_path = Path(context.artifacts["weights"]) / "madmaps-generation.json"
        self.generation_settings = (
            json.loads(settings_path.read_text()) if settings_path.is_file() else {}
        )
        self.processor = AutoProcessor.from_pretrained(
            context.artifacts["weights"],
            **(
                {"max_pixels": self.generation_settings["max_pixels"]}
                if self.generation_settings
                else {}
            ),
        )
        self.model = AutoModelForImageTextToText.from_pretrained(
            context.artifacts["weights"], torch_dtype="auto", device_map="auto"
        ).eval()
        self.torch = torch
        self.fast_decoder = None
        if self.generation_settings:
            from .fast_extraction import PROFILE, FastDecoder

            if self.generation_settings.get("profile") != PROFILE:
                raise ValueError("Unsupported saved extraction profile")
            self.fast_decoder = FastDecoder(self.model, self.processor)

    def predict(self, context, model_input, params=None):
        results = []
        for record in model_input.to_dict(orient="records"):
            image = Image.open(
                BytesIO(base64.b64decode(record["image_base64"], validate=True))
            ).convert("RGB")
            if self.fast_decoder is not None:
                raw, generation = self.fast_decoder.generate(
                    image, max_new_tokens=self.generation_settings["max_new_tokens"]
                )
                if not generation["generation_complete"]:
                    raise ValueError("Extraction reached its output token limit")
                extraction = self.fast_decoder.parse(
                    raw, {"width": image.width, "height": image.height}
                )
                results.append(json.dumps(extraction, separators=(",", ":")))
                continue
            messages = [
                {
                    "role": "user",
                    "content": [
                        {"type": "image", "image": image},
                        {"type": "text", "text": record["prompt"]},
                    ],
                }
            ]
            text = self.processor.apply_chat_template(
                messages, tokenize=False, add_generation_prompt=True
            )
            inputs = self.processor(
                text=[text], images=[image], return_tensors="pt"
            ).to(self.model.device)
            with self.torch.inference_mode():
                output = self.model.generate(
                    **inputs, do_sample=False, max_new_tokens=8192
                )
            # Preserve model text for diagnosis; normalization/validation occurs client-side.
            results.append(
                self.processor.batch_decode(
                    output[:, inputs.input_ids.shape[1] :], skip_special_tokens=True
                )[0]
            )
        return results
