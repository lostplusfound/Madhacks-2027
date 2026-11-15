import base64
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from madmaps_extraction.places import (
    execute_places,
    find_places,
    parse_places,
    places_schema,
)
from madmaps_extraction.workbench import execute

ROOT = Path(__file__).resolve().parents[1]


class PlaceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.image = self.directory / "plan.png"
        Image.new("RGB", (200, 100), "white").save(self.image)
        self.metadata = {"image": str(self.image), "width": 200, "height": 100}

    def test_points_are_transformed_to_original_pixels(self):
        pins = parse_places(
            {"places": [{"label": "201", "category": "other", "point": [250, 750]}]},
            self.metadata,
        )
        self.assertEqual((pins[0]["x"], pins[0]["y"]), (50, 75))

    def test_bad_points_are_rejected_instead_of_clipped(self):
        for point in (
            [1001, 2],
            [-1, 0],
            [True, 0],
            [float("nan"), 0],
            [float("inf"), 0],
            [1],
        ):
            with self.subTest(point=point), self.assertRaises(ValueError):
                parse_places(
                    {
                        "places": [
                            {"label": "WC", "category": "bathroom", "point": point}
                        ]
                    },
                    self.metadata,
                )

    def test_unsupported_labels_and_geometry_payloads_are_rejected(self):
        with self.assertRaises(ValueError):
            parse_places({"places": [], "walls": []}, self.metadata)
        with self.assertRaises(ValueError):
            parse_places(
                {"places": [{"label": "WC", "category": "invented", "point": [1, 2]}]},
                self.metadata,
            )
        self.assertEqual(set(places_schema()["properties"]), {"places"})

    def test_manual_prepare_needs_no_model_or_calibration(self):
        request = {
            "action": "extract",
            "profile": "places",
            "mode": "manual",
            "file_name": "plan.png",
            "file_base64": base64.b64encode(self.image.read_bytes()).decode(),
        }
        payload = execute(request, self.directory, ROOT)
        self.assertEqual(payload["places"], [])
        self.assertEqual(payload["result"]["metadata"]["width"], 200)
        self.assertEqual(payload["profile"], "places")
        self.assertNotIn("graph", payload)
        self.assertNotIn("extraction", payload)

    def test_live_request_only_asks_for_places_and_preserves_evidence(self):
        raw = {
            "choices": [
                {
                    "finish_reason": "stop",
                    "message": {
                        "content": json.dumps(
                            {
                                "places": [
                                    {
                                        "label": "WC",
                                        "category": "bathroom",
                                        "point": [500, 500],
                                    }
                                ]
                            }
                        )
                    },
                }
            ]
        }
        client = Mock()
        client.api_client.do.return_value = raw
        pins, response, provenance = find_places(
            self.metadata,
            {"api_format": "chat", "endpoint": "vision-model"},
            client=client,
        )
        self.assertEqual((pins[0]["x"], pins[0]["y"]), (100, 50))
        self.assertIs(response, raw)
        self.assertEqual(provenance["model_coordinate_frame"], "normalized-0-1000")
        body = client.api_client.do.call_args.kwargs["body"]
        self.assertEqual(body["max_tokens"], 2048)
        self.assertEqual(
            set(body["response_format"]["json_schema"]["schema"]["properties"]),
            {"places"},
        )

    def test_truncation_is_not_reported_as_success(self):
        client = Mock()
        client.api_client.do.return_value = {
            "choices": [
                {"finish_reason": "length", "message": {"content": '{"places":[]}'}}
            ]
        }
        with self.assertRaisesRegex(ValueError, "incomplete"):
            find_places(
                self.metadata,
                {"api_format": "chat", "endpoint": "vision-model"},
                client=client,
            )

    def test_example_is_clearly_distinguished_from_live_inference(self):
        payload = execute_places({"mode": "demo"}, self.directory, ROOT, {})
        self.assertTrue(payload["synthetic"])
        self.assertEqual(payload["inference_mode"], "demo")
        self.assertEqual(len(payload["places"]), 3)
        self.assertTrue(all(pin["source"] == "example" for pin in payload["places"]))


if __name__ == "__main__":
    unittest.main()
