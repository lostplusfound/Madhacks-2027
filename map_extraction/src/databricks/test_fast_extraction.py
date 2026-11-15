import base64
import copy
import importlib.util
import io
import json
import sys
import types
import unittest
from pathlib import Path
from unittest.mock import patch

from jsonschema import ValidationError
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from madmaps_extraction.contract import load_json
from madmaps_extraction.fast_extraction import (
    fast_prompt,
    fast_schema,
    fast_target,
    unpack_wire,
)


class FastExtractionTests(unittest.TestCase):
    def setUp(self):
        self.target = load_json(
            Path(__file__).resolve().parents[1] / "examples/ground_truth.json"
        )
        self.metadata = {"width": self.target["width"], "height": self.target["height"]}

    def test_wall_free_target_retains_other_features_and_source(self):
        original = copy.deepcopy(self.target)
        wire = fast_target(self.target)
        self.assertEqual(set(wire), {"rooms", "doors", "walkable_areas"})
        extraction = unpack_wire(wire, self.metadata)
        self.assertEqual(extraction["walls"], [])
        self.assertEqual(len(extraction["rooms"]), 2)
        self.assertEqual(len(extraction["doors"]), 2)
        self.assertEqual(self.target, original)

    def test_decoder_rejects_an_added_wall_payload(self):
        wire = fast_target(self.target)
        wire["walls"] = self.target["walls"]
        with self.assertRaises(ValidationError):
            unpack_wire(wire, self.metadata)

    def test_valid_json_does_not_bypass_door_reference_validation(self):
        wire = fast_target(self.target)
        wire["doors"][0]["room_id"] = "missing-room"
        with self.assertRaisesRegex(ValueError, "door room reference"):
            unpack_wire(wire, self.metadata)

    def test_self_intersecting_generated_area_is_not_repaired(self):
        wire = fast_target(self.target)
        wire["walkable_areas"][0]["polygon"] = [[0, 0], [100, 100], [100, 0], [0, 100]]
        with self.assertRaisesRegex(ValueError, "Invalid walkable"):
            unpack_wire(wire, self.metadata)

    def test_unsupported_category_is_rejected(self):
        wire = fast_target(self.target)
        wire["rooms"][0]["category"] = "livingRoom"
        with self.assertRaises(ValidationError):
            unpack_wire(wire, self.metadata)

    def test_prompt_and_schema_keep_wall_generation_out(self):
        self.assertIn("Do not generate walls", fast_prompt(self.metadata))
        self.assertNotIn("walls", fast_schema()["properties"])

    def test_serving_wrapper_uses_fast_profile_and_restores_envelope(self):
        pyfunc = types.ModuleType("mlflow.pyfunc")
        pyfunc.PythonModel = object
        mlflow = types.ModuleType("mlflow")
        mlflow.pyfunc = pyfunc
        path = Path(__file__).resolve().parents[1] / "madmaps_extraction/vlm.py"
        spec = importlib.util.spec_from_file_location("_fast_vlm_wrapper_test", path)
        module = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, {"mlflow": mlflow, "mlflow.pyfunc": pyfunc}):
            spec.loader.exec_module(module)
        wire = fast_target(self.target)

        class Decoder:
            complete = True

            def generate(inner, image, *, max_new_tokens):
                self.assertEqual(max_new_tokens, 4096)
                return json.dumps(wire), {"generation_complete": inner.complete}

            def parse(inner, raw, metadata):
                return unpack_wire(json.loads(raw), metadata)

        image = io.BytesIO()
        Image.new("RGB", (self.metadata["width"], self.metadata["height"])).save(
            image, "PNG"
        )
        records = [
            {
                "image_base64": base64.b64encode(image.getvalue()).decode(),
                "prompt": "legacy full prompt",
            }
        ]

        class Frame:
            def to_dict(inner, orient):
                return records

        model = module.FloorPlanVLM()
        model.fast_decoder = Decoder()
        model.generation_settings = {"max_new_tokens": 4096}
        results = model.predict(None, Frame())
        result = json.loads(results[0])
        self.assertEqual(result["walls"], [])
        self.assertEqual(result["width"], self.metadata["width"])
        model.fast_decoder.complete = False
        with self.assertRaisesRegex(ValueError, "token limit"):
            model.predict(None, Frame())


if __name__ == "__main__":
    unittest.main()
