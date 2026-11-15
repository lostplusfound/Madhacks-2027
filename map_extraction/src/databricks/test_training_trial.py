import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch
from zipfile import ZipFile

from run_training_trial import (
    MANIFEST_SHA256,
    MODEL,
    REVISION,
    run_stage,
    unpack_source,
    verify_baseline,
    verify_file,
)


class TrialTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def stage(self, *, code=0, records=None, expected=None):
        if records is not None:
            (self.root / "stage").mkdir()
            (self.root / "stage/evaluation.json").write_text(
                json.dumps({"runs": records, "failure_rate": 1.0})
            )
        process = MagicMock()
        process.__enter__.return_value = process
        process.stdout = io.StringIO("test worker output\n")
        process.wait.return_value = code
        with patch("run_training_trial.subprocess.Popen", return_value=process):
            run_stage("stage", "unused.module", [], self.root, {}, expected)

    def test_failed_training_blocks_continuation(self):
        with self.assertRaisesRegex(RuntimeError, "later stages will not run"):
            self.stage(code=1)

    def test_complete_quality_failures_are_preserved_as_baseline_evidence(self):
        self.stage(
            code=1,
            records=[{"status": "failed", "error_type": "JSONDecodeError"}],
            expected=1,
        )

    def test_incomplete_evaluation_is_a_pipeline_failure(self):
        with self.assertRaisesRegex(RuntimeError, "complete evaluation"):
            self.stage(code=1, records=[], expected=8)

    def test_gpu_oom_is_not_treated_as_a_quality_measurement(self):
        with self.assertRaisesRegex(RuntimeError, "execution error"):
            self.stage(
                code=1,
                records=[{"status": "failed", "error_type": "OutOfMemoryError"}],
                expected=1,
            )

    def test_source_archive_cannot_escape_work_directory(self):
        archive_path = self.root / "source.zip"
        with ZipFile(archive_path, "w") as archive:
            archive.writestr("../escaped.py", "unsafe")
        with self.assertRaisesRegex(ValueError, "escapes"):
            unpack_source(archive_path, self.root / "source")
        self.assertFalse((self.root / "escaped.py").exists())

    def test_changed_training_input_is_rejected(self):
        path = self.root / "manifest.json"
        path.write_text("changed")
        with self.assertRaisesRegex(ValueError, "checksum mismatch"):
            verify_file(path, "0" * 64)

    def test_saved_baseline_must_match_model_manifest_and_budget(self):
        report = {
            "model": MODEL,
            "revision": REVISION,
            "manifest_sha256": MANIFEST_SHA256,
            "split": "validation",
            "max_pixels": 262144,
            "public_annotations_enabled": True,
            "runs": [{} for _ in range(8)],
        }
        verify_baseline(report)
        for key, value in (
            ("revision", "wrong-revision"),
            ("max_pixels", 1048576),
            ("manifest_sha256", "different-data"),
        ):
            with (
                self.subTest(key=key),
                self.assertRaisesRegex(ValueError, "does not match"),
            ):
                verify_baseline({**report, key: value})

    def test_saved_baseline_cannot_reuse_incomplete_predictions(self):
        with self.assertRaisesRegex(ValueError, "does not match"):
            verify_baseline({"runs": []})


if __name__ == "__main__":
    unittest.main()
