"""Optional MLflow wrapper. Import only in a GPU environment with the vlm extra."""

import base64
from io import BytesIO

import mlflow.pyfunc
from PIL import Image


class FloorPlanVLM(mlflow.pyfunc.PythonModel):
    def load_context(self, context):
        import torch
        from transformers import AutoModelForImageTextToText, AutoProcessor

        self.processor = AutoProcessor.from_pretrained(context.artifacts["weights"])
        self.model = AutoModelForImageTextToText.from_pretrained(
            context.artifacts["weights"], torch_dtype="auto", device_map="auto"
        ).eval()
        self.torch = torch

    def predict(self, context, model_input, params=None):
        results = []
        for record in model_input.to_dict(orient="records"):
            image = Image.open(
                BytesIO(base64.b64decode(record["image_base64"], validate=True))
            ).convert("RGB")
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
