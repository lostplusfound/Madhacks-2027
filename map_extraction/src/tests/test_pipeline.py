import copy
import json
import math
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

import pymupdf
from PIL import Image

from madmaps_extraction.adapters import (
    DatabricksAdapter,
    InvalidResponse,
    serving_schema,
)
from madmaps_extraction.benchmark import benchmark, match, navigation_metrics, score
from madmaps_extraction.contract import calibrate, load_json, validate
from madmaps_extraction.geometry import room_polygon
from madmaps_extraction.graph import build_graph
from madmaps_extraction.pipeline import run
from madmaps_extraction.preprocess import preprocess
from madmaps_extraction.storage import persist

EXAMPLES = Path(__file__).resolve().parents[1] / "examples"


class PipelineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.truth = load_json(EXAMPLES / "ground_truth.json")
        self.config = load_json(EXAMPLES / "config.json")
        self.config.update(
            input=str(EXAMPLES / "plan.png"),
            recorded_output=str(EXAMPLES / "recorded.json"),
            output_dir=str(self.root),
        )

    def graph(self, extraction=None):
        return build_graph(
            extraction or self.truth,
            0.05,
            graph_id="g",
            building_id="b",
            floor_id="f",
            spacing=20,
        )

    def test_scale(self):
        self.assertAlmostEqual(calibrate(self.config["calibration"], 400, 240), 0.05)
        for points, distance in (
            ([[1, 1], [1, 1]], 1),
            ([[0, 0], [1000, 0]], 10),
            ([[0, 0], [1, 1]], math.nan),
        ):
            with self.assertRaises(ValueError):
                calibrate({"points": points, "distance_m": distance}, 400, 240)

    def test_schema_bounds_references_and_nonfinite(self):
        validate(self.truth)
        for mutate in (
            lambda e: e["doors"][0].update(room_id="missing"),
            lambda e: e["rooms"][0].update(bbox=[0, 0, 500, 5]),
            lambda e: e["doors"][0].update(point=[math.nan, 2]),
            lambda e: e["walls"].append(copy.deepcopy(e["walls"][0])),
            lambda e: e["walls"][0].update(
                polygon=[[0, 0], [10, 10], [0, 10], [10, 0]]
            ),
        ):
            extraction = copy.deepcopy(self.truth)
            mutate(extraction)
            with self.assertRaises(ValueError):
                validate(extraction)

    def test_dimension_mismatch(self):
        with self.assertRaises(ValueError):
            validate(self.truth, {"width": 500, "height": 240})

    def test_exif_orientation(self):
        path = self.root / "rotated.jpg"
        image = Image.new("RGB", (10, 20))
        exif = image.getexif()
        exif[274] = 6
        image.save(path, exif=exif)
        metadata = preprocess(path, self.root / "processed")
        self.assertEqual((metadata["width"], metadata["height"]), (20, 10))
        with self.assertRaises(FileExistsError):
            preprocess(path, self.root / "processed")

    def test_pdf_page_selection(self):
        path = self.root / "two.pdf"
        with pymupdf.open() as doc:
            doc.new_page(width=72, height=144)
            doc.new_page(width=144, height=72)
            doc.save(path)
        metadata = preprocess(path, self.root / "pdf", page=1, dpi=72)
        self.assertEqual((metadata["width"], metadata["height"]), (144, 72))
        with self.assertRaises(ValueError):
            preprocess(path, self.root / "invalid", page=2)

    def test_candidate_and_no_wall_crossings(self):
        graph, report = self.graph()
        self.assertTrue(report["candidate_valid"], report)
        self.assertTrue(report["requires_human_review"])
        metrics = navigation_metrics(
            graph,
            self.truth,
            [{"start": [160, 120], "end": [240, 120], "reachable": True}],
            10,
        )
        self.assertEqual(metrics["reference_route_success"], 1)
        self.assertEqual(metrics["ground_truth_wall_crossings"], 0)
        self.assertEqual(graph["floors"][0]["metersPerUnit"], 0.05)

    def test_disconnected_roadmap(self):
        extraction = copy.deepcopy(self.truth)
        extraction["walls"].append(
            {
                "id": "block",
                "polygon": [[190, 80], [210, 80], [210, 160], [190, 160]],
                "confidence": 1,
            }
        )
        _, report = self.graph(extraction)
        self.assertFalse(report["candidate_valid"])
        self.assertGreater(report["components"], 1)

    def test_door_inside_wall_is_rejected(self):
        extraction = copy.deepcopy(self.truth)
        extraction["doors"][0]["point"] = [200, 40]
        _, report = self.graph(extraction)
        self.assertFalse(report["candidate_valid"])
        self.assertTrue(
            any("no usable approach" in issue for issue in report["issues"])
        )

    def test_node_limit(self):
        with self.assertRaises(ValueError):
            build_graph(
                self.truth,
                0.05,
                graph_id="g",
                building_id="b",
                floor_id="f",
                spacing=10,
                max_nodes=3,
            )

    def test_success_artifacts(self):
        result = run(self.config)
        self.assertEqual(result["status"], "needsReview")
        self.assertTrue(result["validation"]["candidate_valid"])
        for name in (
            "extraction.json",
            "raw_response.json",
            "graph_candidate.json",
            "result.json",
        ):
            self.assertTrue((Path(result["artifact_dir"]) / name).exists())

    def test_missing_calibration_withholds_graph(self):
        del self.config["calibration"]
        result = run(self.config)
        self.assertEqual(result["status"], "needsReview")
        self.assertFalse(result["validation"]["candidate_valid"])
        self.assertFalse(
            (Path(result["artifact_dir"]) / "graph_candidate.json").exists()
        )

    def test_low_confidence_review(self):
        extraction = copy.deepcopy(self.truth)
        extraction["doors"][0]["confidence"] = 0.1
        adapter = Mock()
        adapter.extract.return_value = (extraction, extraction, {"adapter": "test"})
        result = run(self.config, adapter=adapter)
        self.assertFalse(result["validation"]["candidate_valid"])

    def test_failure_record_and_raw_preservation(self):
        adapter = Mock()
        adapter.extract.side_effect = InvalidResponse({"predictions": ["not json"]})
        result = run(self.config, adapter=adapter)
        self.assertEqual(result["status"], "failed")
        self.assertEqual(result["error"]["stage"], "extraction")
        self.assertEqual(
            load_json(Path(result["artifact_dir"]) / "raw_response.json"),
            {"predictions": ["not json"]},
        )

    def test_invalid_geometry_preserves_raw(self):
        extraction = copy.deepcopy(self.truth)
        extraction["width"] = 999
        adapter = Mock()
        adapter.extract.return_value = (extraction, extraction, {"adapter": "test"})
        result = run(self.config, adapter=adapter)
        self.assertEqual(result["status"], "failed")
        self.assertTrue((Path(result["artifact_dir"]) / "raw_response.json").exists())

    def test_serving_contract_and_malformed_output(self):
        metadata = {"image": str(EXAMPLES / "plan.png"), "width": 400, "height": 240}
        with (
            patch("databricks.sdk.WorkspaceClient", autospec=True) as client,
            patch("databricks.sdk.config.Config", autospec=True),
        ):
            api = client.return_value.api_client
            api.do.return_value = {"predictions": [json.dumps(self.truth)]}
            adapter = DatabricksAdapter("test-endpoint")
            extraction, _, provenance = adapter.extract(metadata)
            self.assertEqual(extraction, self.truth)
            self.assertEqual(provenance["attempts"], 1)
            self.assertIn(
                "image_base64", api.do.call_args.kwargs["body"]["dataframe_records"][0]
            )
            api.do.return_value = {"predictions": ["```invalid"]}
            with self.assertRaises(InvalidResponse):
                adapter.extract(metadata)
            api.do.return_value = {"predictions": []}
            with self.assertRaises(InvalidResponse):
                adapter.extract(metadata)

    def test_spatial_matching_independent_of_ids(self):
        predicted = copy.deepcopy(self.truth)
        predicted["rooms"][0]["id"] = "different-id"
        predicted["rooms"][0]["label"] = " room   A "
        metrics = score(predicted, self.truth)
        self.assertEqual(metrics["rooms"]["f1"], 1)
        self.assertEqual(metrics["rooms"]["matched_text_accuracy"], 1)

    def test_rotated_boxes_use_polygon_overlap_and_validate_bounds(self):
        truth = copy.deepcopy(self.truth)
        truth["rooms"] = [dict(truth["rooms"][0], bbox=[100, 80, 180, 120])]
        truth["doors"] = []
        predicted = copy.deepcopy(truth)
        predicted["rooms"][0]["rotation_deg"] = 90
        validate(predicted)
        self.assertAlmostEqual(room_polygon(predicted["rooms"][0]).area, 3200)
        self.assertEqual(score(predicted, truth)["rooms"]["tp"], 0)
        predicted["rooms"][0].update(bbox=[0, 0, 100, 30], rotation_deg=45)
        with self.assertRaises(ValueError):
            validate(predicted)

    def test_amenity_categories_are_scored_separately_from_room_text(self):
        truth = copy.deepcopy(self.truth)
        truth["rooms"][0].update(label="Restroom", category="bathroom")
        predicted = copy.deepcopy(truth)
        predicted["rooms"][0]["category"] = "elevator"
        metrics = score(predicted, truth)
        self.assertEqual(metrics["rooms"]["f1"], 1)
        self.assertEqual(metrics["rooms"]["matched_category_accuracy"], 0.5)
        self.assertEqual(metrics["features_by_category"]["bathroom"]["fn"], 1)
        self.assertEqual(metrics["features_by_category"]["elevator"]["fp"], 1)
        self.assertIsNone(metrics["features_by_category"]["stairs"]["f1"])

    def test_chat_vision_sends_image_schema_and_preserves_usage(self):
        metadata = {"image": str(EXAMPLES / "plan.png"), "width": 400, "height": 240}
        with (
            patch("databricks.sdk.WorkspaceClient", autospec=True) as client,
            patch("databricks.sdk.config.Config", autospec=True) as config,
        ):
            api = client.return_value.api_client
            api.do.return_value = {
                "choices": [
                    {
                        "finish_reason": "stop",
                        "message": {
                            "content": "```json\n" + json.dumps(self.truth) + "\n```"
                        },
                    }
                ],
                "usage": {"total_tokens": 23},
            }
            extraction, raw, provenance = DatabricksAdapter(
                "gemma", api_format="chat", profile="madmaps"
            ).extract(metadata)
            self.assertEqual(extraction, self.truth)
            self.assertEqual(raw["usage"], provenance["usage"])
            self.assertEqual(config.call_args.kwargs["profile"], "madmaps")
            body = api.do.call_args.kwargs["body"]
            self.assertTrue(
                body["messages"][0]["content"][1]["image_url"]["url"].startswith(
                    "data:image/png;base64,"
                )
            )
            self.assertEqual(
                body["response_format"]["json_schema"]["schema"]["properties"]["width"][
                    "enum"
                ],
                [400],
            )
            self.assertNotIn("$ref", json.dumps(serving_schema(metadata)))
            self.assertNotIn("pattern", json.dumps(serving_schema(metadata)))

    def test_chat_truncation_is_a_preserved_failure(self):
        metadata = {"image": str(EXAMPLES / "plan.png"), "width": 400, "height": 240}
        with (
            patch("databricks.sdk.WorkspaceClient", autospec=True) as client,
            patch("databricks.sdk.config.Config", autospec=True),
        ):
            raw = {
                "choices": [{"finish_reason": "length", "message": {"content": "{"}}]
            }
            client.return_value.api_client.do.return_value = raw
            with self.assertRaises(InvalidResponse) as raised:
                DatabricksAdapter("gemma", api_format="chat").extract(metadata)
            self.assertEqual(raised.exception.raw, raw)
            self.assertEqual(raised.exception.issue, "output_truncated")

    def test_transient_serving_failure_retries(self):
        from databricks.sdk.errors import DatabricksError

        metadata = {"image": str(EXAMPLES / "plan.png"), "width": 400, "height": 240}
        with (
            patch("databricks.sdk.WorkspaceClient", autospec=True) as client,
            patch("databricks.sdk.config.Config", autospec=True),
            patch("madmaps_extraction.adapters.time.sleep") as sleep,
        ):
            client.return_value.api_client.do.side_effect = [
                DatabricksError("busy", error_code="REQUEST_LIMIT_EXCEEDED"),
                {"predictions": [self.truth]},
            ]
            _, _, provenance = DatabricksAdapter("test").extract(metadata)
            self.assertEqual(provenance["attempts"], 2)
            sleep.assert_called_once_with(1)

    def test_permanent_serving_failure_does_not_retry(self):
        from databricks.sdk.errors import DatabricksError

        with (
            patch("databricks.sdk.WorkspaceClient", autospec=True) as client,
            patch("databricks.sdk.config.Config", autospec=True),
            patch("madmaps_extraction.adapters.time.sleep") as sleep,
        ):
            client.return_value.api_client.do.side_effect = DatabricksError(
                "secret details", error_code="PERMISSION_DENIED"
            )
            result = run(self.config, adapter=DatabricksAdapter("test"))
            self.assertEqual(result["status"], "failed")
            self.assertEqual(result["inference_attempts"], 1)
            self.assertNotIn("secret details", json.dumps(result))
            sleep.assert_not_called()

    def test_matching_maximizes_valid_cardinality(self):
        self.assertEqual(set(match([[0.9, 0.8], [0.8, 0.1]], 0.5)), {(0, 1), (1, 0)})

    def test_missing_and_duplicate_detections(self):
        predicted = copy.deepcopy(self.truth)
        predicted["rooms"].append(copy.deepcopy(predicted["rooms"][0]))
        predicted["doors"] = []
        metrics = score(predicted, self.truth)
        self.assertEqual(metrics["rooms"]["fp"], 1)
        self.assertEqual(metrics["doors"]["recall"], 0)

    def test_missed_wall_does_not_credit_route(self):
        truth = copy.deepcopy(self.truth)
        truth["walls"].append(
            {
                "id": "hidden",
                "polygon": [[190, 80], [210, 80], [210, 160], [190, 160]],
                "confidence": 1,
            }
        )
        graph, _ = self.graph()
        metrics = navigation_metrics(
            graph, truth, [{"start": [160, 120], "end": [240, 120]}], 10
        )
        self.assertGreater(metrics["ground_truth_wall_crossings"], 0)
        self.assertEqual(metrics["reference_route_success"], 0)

    def test_benchmark_failed_run_stays_in_denominator(self):
        config_path = self.root / "config.json"
        config_path.write_text(json.dumps(self.config))
        manifest = {
            "cases": [
                {
                    "id": "missing",
                    "config": "config.json",
                    "ground_truth": str(EXAMPLES / "ground_truth.json"),
                }
            ]
        }
        self.config["input"] = str(self.root / "missing.png")
        config_path.write_text(json.dumps(self.config))
        path = self.root / "manifest.json"
        path.write_text(json.dumps(manifest))
        report = benchmark(path, self.root / "benchmark", repeats=2)
        self.assertEqual(report["summary"]["failure_rate"], 1)
        self.assertEqual(report["summary"]["evaluated_runs"], 0)
        self.assertEqual(report["summary"]["runs"], 2)

    def test_benchmark_end_to_end(self):
        report = benchmark(
            EXAMPLES / "manifest.json", self.root / "benchmark", repeats=2
        )
        self.assertEqual(report["summary"]["rooms"]["f1"], 1)
        self.assertEqual(report["summary"]["reference_route_success_mean"], 1)
        self.assertEqual(report["summary"]["failure_rate"], 0)

    def test_table_identifier_validation_before_spark(self):
        with self.assertRaises(ValueError):
            persist({}, "a.b.c; DROP TABLE x", record_type="test")


if __name__ == "__main__":
    unittest.main()
