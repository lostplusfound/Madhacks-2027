# Use the extraction lab

Open **Profile → Floor-plan extraction lab** in the Flutter app. It uses Serverpod's development-only
`extractionLab` endpoint to run the Python worker in the background. No separate
Python HTTP server is needed. The connection check is available from the settings icon.

## Try it

1. Start/attach to the Serverpod runner from `madmaps_server` using `serverpod start`.
   If its runner is already active, this attaches to it and launches configured apps.
2. In **Extract**, choose **Try the synthetic demo** to check the recorded-output path.
3. Choose **Test live VLM on sample plan** to send the sample through the configured
   Databricks model. The preview explicitly distinguishes live inference from replay.
4. For your own plan, choose a PNG, JPEG, or PDF (8 MB maximum), select **Databricks
   VLM**, choose a zero-based PDF page, and run extraction. The worker renders PDFs
   at 200 DPI. Calibration/annotations must use that canonical rendered image frame.
5. Add calibration JSON to generate a graph, for example:
   `{"points":[[20,120],[220,120]],"distance_m":10}`. These coordinates are examples;
   use a genuinely known reference distance on your own plan.
6. Import independent reference annotations using `examples/ground_truth.json` as
   a format guide. Without annotations, accuracy reads **not measured**. Confidence
   remains a separate, uncalibrated number. Re-run after changing reference annotations.

The room/door/wall/text metrics reflect actual spatial matching against the supplied
annotations. They are not percentages invented from model confidence. A valid JSON
response does not guarantee correct geometry. Door positions, missing walls, and
connectivity can still require correction. The lab never publishes candidate graphs.

## Draw and rotate annotations

After extraction, open **Fine-tune** to edit the reviewed training target directly on
its canonical image. The original prediction and its accuracy metrics stay intact.

- **Wall polygon / Walkable polygon:** click each corner, then click the first point
  or **Finish polygon**. Enter finishes and Escape cancels. Polygon edges cannot
  cross themselves, and every shape must stay inside the image.
- **Room / feature box:** drag a rectangle. Select it to edit its label and place
  category, then click **Apply room label**. Room numbers are optional.
- **Restroom / Elevator / Stairs:** use the quick-add buttons, then drag a box around
  the corresponding room or symbol footprint. Restroom is stored as `bathroom` to
  match the existing Serverpod category. Amenity labels do not invent room numbers.
- **Rotate:** select a box and drag its round handle above the top edge. Hold Shift
  to snap to 15-degree increments, or type an angle and click **Apply rotation**.
  Positive angles rotate clockwise. Corner resizing preserves the box's rotation.
- **Door point:** choose its room, then click the doorway in free space.
- **Select:** click a shape or select it from the annotation list. Drag its corner
  handles; polygon vertices can also be inserted or removed. Deleting a room removes
  its linked doors, and Undo restores both.
- **Pan / zoom / Fit:** navigate detailed plans without changing stored pixel
  coordinates. Undo/Redo retains up to 50 committed edits.

Drawings update the advanced JSON editor automatically. If you edit JSON manually,
apply or discard those changes before drawing or saving. Any edit clears the review
confirmation; check the annotations again before saving the reviewed example.

Room/feature records may include `rotation_deg` in [-180, 180]; omitted means zero.
`bbox` is the unrotated rectangle [left, top, right, bottom]. Rotation is about its
center, and validation checks the four final rotated corners. Old unrotated datasets
remain valid. Benchmark overlap uses the rotated polygon, and category-specific F1
scores distinguish restrooms, elevators, and stairs from generic room detection.
No examples of a category in either reference or predictions display an unmeasured
score, rather than an automatic 100%.

The VLM prompt requests numbered and unnumbered rooms, restroom/WC/toilet symbols,
elevators/lifts, stairs, entrances/exits, and accessible amenities. Actual accuracy
still needs independent annotations on representative real plans. The separate
`examples/amenities-manifest.json` is a synthetic feature smoke case only.

## Databricks connection

The lab reloads non-secret connection settings from `lab.local.json` on each server
request. That file is ignored by Git. CLI authentication is kept in Databricks' own
profile/cache; do not put tokens in JSON, Flutter code, or chat.

```sh
databricks auth login --host https://YOUR-WORKSPACE.cloud.databricks.com --profile madmaps
cp lab.local.example.json lab.local.json
```

Example for an existing hosted vision model:

```json
{
  "host": "https://YOUR-WORKSPACE.cloud.databricks.com",
  "profile": "madmaps",
  "endpoint": "databricks-llama-4-maverick",
  "api_format": "chat"
}
```

Choose an endpoint available in your workspace with image support and query
permission. A model's name containing Qwen or GPT does not establish image support.
For this workspace, Llama 4 Maverick completed a real extraction; Gemma 3 returned
invalid wall polygons on the test and was not selected as the default. This is a
connection/format check on a synthetic plan, not a real-plan accuracy evaluation.

For a deployed custom Qwen/MLflow model from `databricks/register_vlm.py`, set its
endpoint name and `"api_format": "custom"`. The custom protocol uses
`dataframe_records`/`predictions`; hosted vision uses Chat Completions image content
and structured JSON output. JSON Schema references are expanded for Databricks'
generation schema, while full validation still runs locally. A single enclosing
JSON code fence may be removed; no missing geometry is fabricated or repaired.

Environment variables override the file:
`DATABRICKS_HOST`, `DATABRICKS_CONFIG_PROFILE`, `MADMAPS_VLM_ENDPOINT`,
`MADMAPS_VLM_API_FORMAT`, `MADMAPS_VLM_REVISION`, `MADMAPS_TRAINING_JOB_ID`.
After changing the file, click **Reconnect** in the lab. No runner restart is needed.
The existing running runner should be left running.

CLI equivalent (from `map_extraction/src`):

```sh
.venv/bin/madmaps-extract run --config examples/config.json \
  --endpoint databricks-llama-4-maverick --api-format chat --profile madmaps
```

## Benchmarks

The **Benchmark** tab can run three recorded synthetic repetitions, run three live
VLM repetitions on that same synthetic case, or import an existing `benchmark.json`
report. Dataset and inference source are shown separately. The live model path records
measured latency, token usage when provided, schema failures, and actual quality metrics.
A live call consumes the workspace's inference quota/billing.

Use an independently labeled collection of real plans before drawing model-quality
conclusions. Managed foundation endpoints can update model versions; records preserve
endpoint, reported model, prompt hash, timestamp, and original response, but cannot
promise immutable underlying weights. Use a pinned custom model for that requirement.

## Review and fine-tune

The **Fine-tune** tab supports this workflow:

1. Extract a plan, then draw or adjust its annotations in the Fine-tune tab.
   The editor changes a reviewed training target; it does not rewrite the original
   prediction or benchmark score. Advanced JSON editing remains available.
2. Choose a building/source group and split. All images from one building/source must
   stay in the same split. Confirm that you reviewed the annotations, then save.
3. Export the dataset ZIP. It contains canonical PNGs, corrected target JSON, checksums,
   and `manifest.json`. Reviews are stored under `runs/reviews` on the Serverpod host.
4. Unpack that ZIP into a Unity Catalog Volume. Keep the relative paths intact.
5. On suitable CUDA GPU compute, install the package with `.[training]`, then run:

```sh
madmaps-fine-tune \
  --manifest /Volumes/CATALOG/SCHEMA/VOLUME/dataset/manifest.json \
  --output /Volumes/CATALOG/SCHEMA/VOLUME/training/run-001 \
  --revision FULL_40_CHARACTER_QWEN_BASE_MODEL_COMMIT_SHA \
  --epochs 1 --learning-rate 0.0001 --rank 16
```

Training uses the pinned Qwen2.5-VL base model and LoRA. It requires real reviewed
train and validation examples from separate building/source groups. Synthetic examples
are excluded, image checksums are verified, path escapes and cross-split leakage are
rejected, and held-out test examples are never passed to the trainer. Validation loss
is logged in `training_result.json`; it is not floor-plan accuracy. GPU training has
not been executed or benchmarked in this local environment.

To expose training as a Databricks job, opt into `databricks/training.yml` using an
`include` entry in `databricks.yml`, set its four training variables, and deploy the
bundle. Use a GPU cluster with a compatible CUDA PyTorch installation. The job creates
an adapter and merged model in a unique run output directory. Set the deployed job ID
as a **string** under `training_job_id` in `lab.local.json`; then the launch button is
enabled. That button submits a real paid job, not a simulated progress bar. Its run ID
is reported for inspection in Databricks. Training jobs are not configured or launched
by default.

The currently selected hosted Llama endpoint is separate from this custom training
path. You cannot fine-tune its weights in place from the lab. Register a trained merged
Qwen candidate using:

```sh
python databricks/register_vlm.py \
  --local-weights /Volumes/CATALOG/SCHEMA/VOLUME/training/run-001/merged \
  --registered-name CATALOG.SCHEMA.floorplan_candidate
```

Evaluate that candidate on held-out plans before deploying its custom serving endpoint
and changing the lab settings. Training never promotes a model automatically.

## Development checks

```sh
# In map_extraction/src
.venv/bin/python -m unittest discover -s tests -q
# In madmaps_flutter
flutter test test/extraction_lab_screen_test.dart
# In madmaps_server
dart test
```

The bridge is development-only, uses one active worker at a time, bounds uploads,
retains job/result files, and keeps job IDs in memory. A server restart expires those
job IDs; re-run extraction before saving a correction. This is a local workbench,
not a production multi-user upload or training service.
