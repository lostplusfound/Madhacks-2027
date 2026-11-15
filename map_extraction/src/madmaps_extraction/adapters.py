"""Adapters return (normalized extraction, original response, provenance)."""

import base64
import hashlib
import json
import re
import time
from pathlib import Path

from .contract import SCHEMA, load_json


class InferenceFailure(RuntimeError):
    def __init__(self, attempts, error_code=None):
        super().__init__("Serving request failed")
        self.attempts = attempts
        self.error_code = error_code


class InvalidResponse(ValueError):
    def __init__(self, raw, attempts=1, issue="invalid_model_response"):
        super().__init__("Malformed serving response; inspect raw_response.json")
        self.raw = raw
        self.attempts = attempts
        self.issue = issue


def prompt(metadata):
    template = {
        "schema_version": 1,
        "width": metadata["width"],
        "height": metadata["height"],
        "coordinate_origin": "top-left",
        "coordinate_units": "pixels",
        "rooms": [],
        "walls": [],
        "doors": [],
        "walkable_areas": [],
    }
    return (
        "Extract the visible contents of this architectural floor plan as ONE JSON data object. "
        "Return an INSTANCE, never a JSON Schema; do not output properties, required, type, or $schema keys. "
        f"The canonical image is {metadata['width']} by {metadata['height']} pixels. "
        "Use top-left pixel coordinates in that frame, not normalized or resized coordinates. "
        "Walls are solid exclusion polygons with actual door gaps; do not close door openings. "
        "Walkable areas are conservative traversable polygons, including approach space at doors. "
        "Door points must lie in free space, not inside a wall. Do not invent hidden connections. "
        "Room bbox is [left, top, right, bottom]. Confidence is an estimate, not calibrated probability. "
        "Only trace visible solid wall bands, not inferred room perimeters. "
        "Detect numbered AND unnumbered places, including restroom/WC/toilet symbols, elevator/lift symbols, "
        "stairs/stairwell symbols, entrances, exits, and accessible amenities. Do not limit extraction to room numbers. "
        "Use category bathroom for restrooms, elevator for lifts, and stairs for stairwells. "
        "If a feature has no written name, give it a descriptive label such as Restroom, Elevator, or Stairs; never invent a room number. "
        "Boxes should cover the room or amenity footprint rather than only its text label. Stair tread lines are not wall bands. "
        "Each room or amenity: id (unique simple ASCII identifier), label, category, bbox, confidence, rotation_deg. "
        "rotation_deg is clockwise degrees in [-180,180], normally 0. bbox is the unrotated rectangle "
        "rotated about its center by rotation_deg; its final four corners must stay inside the image. "
        "Category must be one of "
        + json.dumps(
            SCHEMA["properties"]["rooms"]["items"]["properties"]["category"]["enum"]
        )
        + ". "
        "Each wall and walkable area: id, polygon (list of [x,y] vertices, at least 3), confidence. "
        "Each door: id, room_id (an existing room id), point ([x,y] in free doorway space), confidence. "
        "Use confidence numbers in [0,1]. Use bbox [left,top,right,bottom], with positive area. "
        "Return empty arrays for unobservable features. Fill this exact data shape from the image: "
        + json.dumps(template)
    )


def serving_schema(metadata):
    """Expand references and remove unsupported generation constraints.

    The original strict contract remains the post-inference validator.
    """

    def expand(value):
        if isinstance(value, list):
            return [expand(item) for item in value]
        if not isinstance(value, dict):
            return value
        if "$ref" in value:
            return expand(SCHEMA["$defs"][value["$ref"].rsplit("/", 1)[-1]])
        result = {
            key: expand(item)
            for key, item in value.items()
            if key
            not in {
                "$schema",
                "$defs",
                "pattern",
                "minimum",
                "maximum",
                "minLength",
                "maxLength",
                "minItems",
                "maxItems",
                "const",
            }
        }
        if "const" in value:
            result["type"] = "integer" if isinstance(value["const"], int) else "string"
            result["enum"] = [value["const"]]
        return result

    result = expand(SCHEMA)
    for key in ("width", "height"):
        result["properties"][key]["enum"] = [metadata[key]]
    return result


class RecordedAdapter:
    def __init__(self, path):
        self.path = Path(path)

    def extract(self, metadata):
        result = load_json(self.path)
        return (
            result,
            result,
            {"adapter": "recorded", "model": "recorded-fixture", "attempts": 1},
        )


class DatabricksAdapter:
    """Custom pyfunc or a Databricks vision chat endpoint, chosen explicitly."""

    def __init__(
        self,
        endpoint,
        *,
        timeout=120,
        max_attempts=3,
        model_revision=None,
        api_format="custom",
        profile=None,
        host=None,
        structured_output=True,
    ):
        if (
            not re.fullmatch(r"[A-Za-z0-9_-]+", endpoint)
            or timeout <= 0
            or not 1 <= max_attempts <= 5
        ):
            raise ValueError("Endpoint, positive timeout, and 1..5 attempts required")
        if api_format not in {"custom", "chat"}:
            raise ValueError("api_format must be custom or chat")
        from databricks.sdk import WorkspaceClient
        from databricks.sdk.config import Config

        self.client = WorkspaceClient(
            config=Config(
                http_timeout_seconds=timeout,
                retry_timeout_seconds=0,
                profile=profile,
                host=host,
            )
        )
        self.endpoint, self.max_attempts = endpoint, max_attempts
        self.model_revision = model_revision
        self.api_format = api_format
        self.structured_output = structured_output

    def extract(self, metadata):
        from databricks.sdk.errors import DatabricksError

        record = {
            "image_base64": base64.b64encode(
                Path(metadata["image"]).read_bytes()
            ).decode(),
            "prompt": prompt(metadata),
        }
        body = {"dataframe_records": [record]}
        path = f"/serving-endpoints/{self.endpoint}/invocations"
        if self.api_format == "chat":
            path = "/serving-endpoints/chat/completions"
            body = {
                "model": self.endpoint,
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": record["prompt"]},
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": f"data:image/png;base64,{record['image_base64']}"
                                },
                            },
                        ],
                    }
                ],
                "max_tokens": 8192,
                "temperature": 0,
            }
            if self.structured_output:
                body["response_format"] = {
                    "type": "json_schema",
                    "json_schema": {
                        "name": "floor_plan",
                        "strict": True,
                        "schema": serving_schema(metadata),
                    },
                }
        for attempt in range(1, self.max_attempts + 1):
            try:
                # SDK unified authentication: notebook identity, profile, OAuth, or env.
                raw = self.client.api_client.do(
                    "POST",
                    path,
                    body=body,
                )
                break
            except DatabricksError as error:
                if (
                    error.error_code
                    not in {
                        "REQUEST_LIMIT_EXCEEDED",
                        "TEMPORARILY_UNAVAILABLE",
                        "INTERNAL_ERROR",
                    }
                    or attempt == self.max_attempts
                ):
                    raise InferenceFailure(attempt, error.error_code) from error
                time.sleep(min(2 ** (attempt - 1), 4))
        if not isinstance(raw, dict):
            raise InvalidResponse(raw, attempt)
        predictions = raw.get("predictions")
        if self.api_format == "chat":
            choices = raw.get("choices")
            if (
                not isinstance(choices, list)
                or len(choices) != 1
                or not isinstance(choices[0], dict)
            ):
                raise InvalidResponse(raw, attempt)
            if choices[0].get("finish_reason") in {"length", "max_tokens"}:
                raise InvalidResponse(raw, attempt, "output_truncated")
            message = choices[0].get("message", {})
            predictions = (
                [message.get("content")] if isinstance(message, dict) else None
            )
        if not isinstance(predictions, list) or len(predictions) != 1:
            raise InvalidResponse(raw, attempt)
        prediction = predictions[0]
        if isinstance(prediction, list) and all(
            isinstance(block, dict)
            and block.get("type") == "text"
            and isinstance(block.get("text"), str)
            for block in prediction
        ):
            prediction = "".join(block["text"] for block in prediction)
        if isinstance(prediction, str):
            # Accept a single JSON code fence, preserving the unmodified response.
            fenced = re.fullmatch(r"\s*```(?:json)?\s*\n([\s\S]*?)\n```\s*", prediction)
            if fenced:
                prediction = fenced.group(1)
            try:
                prediction = json.loads(prediction)
            except (ValueError, TypeError) as error:
                raise InvalidResponse(raw, attempt) from error
        return (
            prediction,
            raw,
            {
                "adapter": "databricks",
                "model": self.endpoint,
                "declared_model_revision": self.model_revision,
                "api_format": self.api_format,
                "reported_model": raw.get("model"),
                "prompt_sha256": hashlib.sha256(record["prompt"].encode()).hexdigest(),
                "usage": raw.get("usage"),
                "attempts": attempt,
            },
        )
