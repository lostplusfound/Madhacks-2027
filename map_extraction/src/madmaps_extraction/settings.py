"""Non-secret lab settings, reloaded per request. Authentication stays in the SDK."""

import os
from pathlib import Path

from .contract import load_json

SETTINGS = {
    "host": "DATABRICKS_HOST",
    "profile": "DATABRICKS_CONFIG_PROFILE",
    "endpoint": "MADMAPS_VLM_ENDPOINT",
    "api_format": "MADMAPS_VLM_API_FORMAT",
    "model_revision": "MADMAPS_VLM_REVISION",
    "training_job_id": "MADMAPS_TRAINING_JOB_ID",
}


def load_settings(root):
    path = Path(root) / "lab.local.json"
    local = load_json(path) if path.exists() else {}
    if not isinstance(local, dict) or set(local) - SETTINGS.keys():
        raise ValueError(
            "Lab settings contain unsupported keys; never store API tokens here"
        )
    result = {
        key: os.environ.get(env) or local.get(key) for key, env in SETTINGS.items()
    }
    result["api_format"] = result["api_format"] or "custom"
    if result["api_format"] not in {"custom", "chat"}:
        raise ValueError("api_format must be custom or chat")
    return result
