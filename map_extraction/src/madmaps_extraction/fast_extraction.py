"""Bounded wall-free map extraction shared by training, evaluation and serving."""

import copy
import json

from jsonschema import Draft202012Validator
from shapely.geometry import Polygon

from .contract import SCHEMA, validate

PROFILE = "fast-map-v1"
LIMITS = {"rooms": 32, "doors": 64, "walkable_areas": 64, "vertices": 128}


def fast_prompt(metadata):
    return (
        f"Read this floor plan ({metadata['width']} x {metadata['height']} pixels). "
        "Return compact JSON only with rooms, doors and walkable_areas. Do not generate walls, markdown or explanations. "
        "Use original top-left pixel coordinates. Rooms and amenities need id, label, category, bbox [left,top,right,bottom], confidence; "
        "rotation_deg is optional and normally 0. Use English room-purpose labels where recognizable; preserve visible room numbers. "
        "Categories: "
        + ",".join(
            SCHEMA["properties"]["rooms"]["items"]["properties"]["category"]["enum"]
        )
        + ". "
        "Doors need id, room_id referencing a returned room, point [x,y], confidence. "
        "Walkable areas need id, polygon of [x,y] vertices, confidence. Use a few boundary corners, not repeated points. "
        "Confidence is 0 to 1. Include only visible features; use empty arrays when unobservable. "
        'Shape: {"rooms":[],"doors":[],"walkable_areas":[]}'
    )


def fast_schema():
    schema = {
        "type": "object",
        "additionalProperties": False,
        "required": ["rooms", "doors", "walkable_areas"],
        "properties": {
            key: copy.deepcopy(SCHEMA["properties"][key])
            for key in ("rooms", "doors", "walkable_areas")
        },
        "$defs": copy.deepcopy(SCHEMA["$defs"]),
    }
    for key in ("rooms", "doors", "walkable_areas"):
        schema["properties"][key]["maxItems"] = LIMITS[key]
    schema["$defs"]["area"]["properties"]["polygon"]["maxItems"] = LIMITS["vertices"]
    schema["$defs"]["id"]["maxLength"] = 32
    schema["properties"]["rooms"]["items"]["properties"]["label"]["maxLength"] = 64
    return schema


def compact_numbers(value):
    if isinstance(value, dict):
        return {key: compact_numbers(item) for key, item in value.items()}
    if isinstance(value, list):
        return [compact_numbers(item) for item in value]
    if isinstance(value, float):
        rounded = round(value, 2)
        return int(rounded) if rounded.is_integer() else rounded
    return value


def fast_target(target):
    wire = {
        key: copy.deepcopy(target[key]) for key in ("rooms", "doors", "walkable_areas")
    }
    # Remove insignificant source precision and simplify training annotations
    # within 2 pixels. Predictions are never repaired or clipped this way.
    for area in wire["walkable_areas"]:
        shape = Polygon(area["polygon"]).simplify(2, preserve_topology=True)
        area["polygon"] = [list(point) for point in shape.exterior.coords[:-1]]
    wire = compact_numbers(wire)
    Draft202012Validator(fast_schema()).validate(wire)
    unpack_wire(wire, {"width": target["width"], "height": target["height"]})
    return wire


def unpack_wire(wire, metadata):
    Draft202012Validator(fast_schema()).validate(wire)
    extraction = {
        "schema_version": 1,
        "width": metadata["width"],
        "height": metadata["height"],
        "coordinate_origin": "top-left",
        "coordinate_units": "pixels",
        "walls": [],
        **wire,
    }
    return validate(extraction, metadata)


class FastDecoder:
    def __init__(self, model, processor):
        import xgrammar as xgr

        self.model, self.processor = model, processor
        tokenizer_info = xgr.TokenizerInfo.from_huggingface(
            processor.tokenizer,
            vocab_size=model.config.vocab_size,
            stop_token_ids=model.generation_config.eos_token_id,
        )
        compiler = xgr.GrammarCompiler(tokenizer_info)
        self.grammar = compiler.compile_json_schema(
            fast_schema(), any_whitespace=False, indent=None, separators=(",", ":")
        )

    def generate(self, image, *, max_new_tokens=4096):
        import torch
        from xgrammar.contrib.hf import LogitsProcessor

        metadata = {"width": image.width, "height": image.height}
        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "image"},
                    {"type": "text", "text": fast_prompt(metadata)},
                ],
            }
        ]
        text = self.processor.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=True
        )
        inputs = self.processor(text=[text], images=[image], return_tensors="pt").to(
            self.model.device
        )
        with torch.inference_mode():
            output = self.model.generate(
                **inputs,
                do_sample=False,
                max_new_tokens=max_new_tokens,
                logits_processor=[LogitsProcessor(self.grammar)],
            )
        tokens = output[:, inputs.input_ids.shape[1] :]
        raw = self.processor.batch_decode(tokens, skip_special_tokens=True)[0]
        stop_ids = self.model.generation_config.eos_token_id
        stop_ids = [stop_ids] if isinstance(stop_ids, int) else stop_ids
        complete = int(tokens[0, -1]) in stop_ids
        return raw, {
            "generated_tokens": tokens.shape[1],
            "generation_complete": complete,
        }

    def parse(self, raw, metadata):
        return unpack_wire(json.loads(raw), metadata)
