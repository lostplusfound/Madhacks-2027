import base64
import hashlib
import json
import shutil
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

from madmaps_extraction.contract import load_json
from madmaps_extraction.training import load_reviewed_dataset
from madmaps_extraction.workbench import execute, export_reviews, review_example

ROOT = Path(__file__).resolve().parents[1]


class WorkbenchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.job = self.directory / "job"
        self.job.mkdir()

    def demo(self):
        return execute({"action": "extract", "mode": "demo"}, self.job, ROOT)

    def test_demo_has_measured_synthetic_metrics(self):
        payload = self.demo()
        self.assertTrue(payload["synthetic"])
        self.assertEqual(payload["metrics"]["rooms"]["f1"], 1)
        self.assertTrue(base64.b64decode(payload["plan_base64"]).startswith(b"\x89PNG"))

    def test_upload_recorded_without_truth_has_no_accuracy(self):
        payload = execute(
            {
                "action": "extract",
                "mode": "recorded",
                "file_name": "my-plan.png",
                "file_base64": base64.b64encode(
                    (ROOT / "examples/plan.png").read_bytes()
                ).decode(),
                "recorded_extraction": load_json(ROOT / "examples/recorded.json"),
            },
            self.job,
            ROOT,
        )
        self.assertIsNone(payload["metrics"])
        self.assertFalse(payload["synthetic"])
        self.assertIsNone(payload["graph"])

    def test_review_and_export(self):
        payload = self.demo()
        review_example(
            self.directory, payload, payload["extraction"], split="train", group="demo"
        )
        with self.assertRaises(ValueError):
            review_example(
                self.directory,
                payload,
                payload["extraction"],
                split="validation",
                group="demo",
            )
        result = export_reviews(self.directory, self.directory / "dataset.zip")
        self.assertEqual(result["examples"], 1)
        with ZipFile(self.directory / "dataset.zip") as archive:
            manifest = json.loads(archive.read("manifest.json"))
            self.assertTrue(manifest["examples"][0]["reviewed"])
            self.assertTrue(manifest["examples"][0]["synthetic"])
            self.assertIn(manifest["examples"][0]["image"], archive.namelist())
        # Synthetic data alone can never silently launch actual model training.
        with self.assertRaises(ValueError):
            extracted = self.directory / "extracted"
            with ZipFile(self.directory / "dataset.zip") as archive:
                archive.extractall(extracted)
            load_reviewed_dataset(extracted / "manifest.json")

    def make_real_manifest(self):
        rows = []
        for split in ("train", "validation", "test"):
            target = self.directory / split
            target.mkdir()
            shutil.copy(ROOT / "examples/plan.png", target / "image.png")
            # Distinct canonical images, same dimensions, from independent source groups.
            from PIL import Image

            with Image.open(target / "image.png") as image:
                image.putpixel(
                    (0, 0),
                    {"train": (1, 1, 1), "validation": (2, 2, 2), "test": (3, 3, 3)}[
                        split
                    ],
                )
                image.save(target / "image.png")
            shutil.copy(ROOT / "examples/ground_truth.json", target / "target.json")
            digest = hashlib.sha256((target / "image.png").read_bytes()).hexdigest()
            rows.append(
                {
                    "image": f"{split}/image.png",
                    "target": f"{split}/target.json",
                    "group": split,
                    "source_sha256": split,
                    "image_sha256": digest,
                    "reviewed": True,
                    "synthetic": False,
                    "split": split,
                }
            )
        manifest = self.directory / "manifest.json"
        manifest.write_text(json.dumps({"examples": rows}))
        return manifest, rows

    def test_training_loader_keeps_test_separate(self):
        manifest, _ = self.make_real_manifest()
        partitions = load_reviewed_dataset(manifest)
        self.assertEqual(
            [len(partitions[k]) for k in ("train", "validation", "test")], [1, 1, 1]
        )

    def test_training_loader_rejects_group_leakage_and_checksums(self):
        manifest, rows = self.make_real_manifest()
        rows[1]["group"] = rows[0]["group"]
        manifest.write_text(json.dumps({"examples": rows}))
        with self.assertRaisesRegex(ValueError, "leakage"):
            load_reviewed_dataset(manifest)
        rows[1]["group"] = "validation"
        rows[0]["image_sha256"] = "wrong"
        manifest.write_text(json.dumps({"examples": rows}))
        with self.assertRaisesRegex(ValueError, "checksum"):
            load_reviewed_dataset(manifest)

    def test_training_loader_rejects_paths_outside_export(self):
        manifest, rows = self.make_real_manifest()
        rows[0]["image"] = "../escape.png"
        manifest.write_text(json.dumps({"examples": rows}))
        with self.assertRaisesRegex(ValueError, "outside"):
            load_reviewed_dataset(manifest)
