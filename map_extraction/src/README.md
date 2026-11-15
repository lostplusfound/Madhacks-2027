# MadMaps floor-plan extraction

For the Flutter frontend, live Databricks connection, review/export, and fine-tuning workflow, see [LAB.md](LAB.md).
For the no-spend preparation kit, free GPU options, and bounded training trial, see [TRAINING.md](TRAINING.md).

Python extraction worker and benchmark for the existing Flutter/Serverpod app.
Run commands below from `map_extraction/src`. This package does not change the app,
create cloud resources, or deploy a model automatically.

## Local quick start

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -e '.[databricks,dev]'
.venv/bin/python examples/make_fixture.py
.venv/bin/madmaps-extract run --config examples/config.json
.venv/bin/madmaps-extract benchmark --manifest examples/manifest.json --output runs/benchmark-001 --repeats 3
.venv/bin/python -m unittest discover -s tests -v
```

The example uses **recorded synthetic output**, identical to its separate synthetic
annotation file. Perfect scores only verify the harness; they say nothing about VLM
accuracy. Choose a fresh benchmark output directory for each experiment. Pipeline
runs get UUID directories automatically. Artifacts are not committed.

## Pipeline and contract

1. Render a selected PDF page at the configured DPI, or normalize image EXIF
   orientation. Record source/image SHA-256, dimensions, page, and canonical frame.
2. Call the recorded adapter or Databricks custom Model Serving endpoint.
3. Preserve the original response, enforce `extraction.schema.json`, then check
   finite coordinates, image dimensions, polygon validity, bounds, and references.
4. Compute `metersPerUnit = distance_m / pixel_distance` using a known reference.
5. Construct a conservative single-floor grid roadmap inside walkable polygons,
   with door approach nodes. Edges must remain in free space and avoid walls.
6. Export a candidate graph and validation report. Persist history to Delta if requested.

See `examples/recorded.json` for the model output format. The schema contains rooms
with labels/bboxes, wall exclusion polygons, door points linked to rooms, and
walkable polygons. Wall polygons must have actual door openings. This version does
not carve openings, infer missing walls, or connect floors.

All geometry and annotations use the **canonical top-left pixel frame**, before any
model-specific resizing. The included VLM prompt asks for coordinates in that frame;
validation checks bounds but cannot establish that the model localized them correctly.
Any future adapter that crops/tiles images must invert those transforms explicitly.
Calibration points are in the same canonical frame. They must come from a reliable
known distance; no scale is guessed. A uniform scale assumes an undistorted plan.

Each run produces `result.json`, `metadata.json`, `raw_response.json`,
`extraction.json`, `validation.json`, and (when calibrated) `graph_candidate.json`,
as stages complete. Failed runs retain available artifacts and a failure-stage/type
record. HTTP exception bodies are not logged because they can contain secrets or
large image payloads. Malformed inference output is retained for diagnosis.

Every successful extraction has status `needsReview`, including geometrically valid
candidates. `candidate_valid` means the local checks passed, not that extracted
semantics are correct. Low-confidence features, missing approach doors, and
connectivity problems invalidate the candidate. Missing calibration withholds the graph.
Empty or incorrectly extracted walls cannot be detected without ground truth or review.
Grid spacing and clearance affect connectivity; narrow corridors may need a finer grid.
Work is bounded by `max_nodes` (default 2500) and one million grid samples.

## Connect a real VLM

The default adapter protocol expects a **custom MLflow pyfunc endpoint**. Hosted vision chat endpoints are also supported with `--api-format chat`; see [the live connection guide](LAB.md). The custom protocol is:

```json
{"dataframe_records": [{"image_base64": "<PNG base64>", "prompt": "<schema and instructions>"}]}
```

The endpoint must return `{"predictions": [<extraction object or JSON string>]}`.
`madmaps_extraction/vlm.py` supplies an optional Transformers/MLflow wrapper.
It uses greedy generation and preserves the model's output text. A malformed or
truncated answer fails validation; the pipeline does not repair invented geometry.

To register a candidate Qwen VLM, use GPU compute in your Databricks workspace:

```sh
python -m pip install '.[vlm]'
python databricks/register_vlm.py \
  --model-id Qwen/Qwen2.5-VL-3B-Instruct \
  --revision <full-40-character-Hugging-Face-commit-SHA> \
  --registered-name <catalog.schema.model>
```

Run from this directory so `code_paths` resolves. The script packages pinned model
weights and installed dependency versions in MLflow, and registers a Unity Catalog
model. It does not create a serving endpoint. Deploy that registered version on a
compatible GPU serving endpoint and smoke-test it before running the benchmark.
This GPU path has not been executed locally. Qwen is a candidate to evaluate, not a
claim of floor-plan accuracy. Check its license and available GPU memory before deployment.

For local calls, authenticate with the Databricks CLI (`databricks auth login
--host https://<workspace>`) or SDK-supported OAuth environment configuration.
Notebook/job calls use SDK unified authentication where supported. The job identity
needs permission to query the serving endpoint and access its data. Do not place tokens
in config JSON; configurations are included in run records.

```sh
.venv/bin/madmaps-extract run --config examples/config.json \
  --endpoint <endpoint-name> --model-revision <registered-version>
.venv/bin/madmaps-extract benchmark --manifest examples/manifest.json \
  --output runs/qwen-v1 --repeats 3 \
  --endpoint <endpoint-name> --model-revision <registered-version>
```

`model_revision` is a provenance declaration, not a lookup. Keep the endpoint pinned
to that version, disable traffic splits, and do not update it during a benchmark.
Default HTTP timeout is 120 seconds per attempt; transient Databricks errors are
retried up to three attempts with bounded backoff. Schema failures are not retried.

## Databricks deployment

The bundle defines extraction and benchmark wheel jobs on an existing cluster.
Use a supported runtime with Unity Catalog Volumes and `VARIANT`/`parse_json`
support (15.4+ functionality; choose a currently supported LTS runtime). The caller
needs cluster attach/job permissions, Volume access, endpoint query permission, and
schema/table creation or write permission. No Spark cluster is needed for local runs.

Upload plans, config files, and annotations to a Unity Catalog Volume. For example:

```text
/Volumes/<catalog>/<schema>/<volume>/dataset/config.json
/Volumes/<catalog>/<schema>/<volume>/dataset/manifest.json
/Volumes/<catalog>/<schema>/<volume>/dataset/plan.png
/Volumes/<catalog>/<schema>/<volume>/dataset/ground_truth.json
```

Paths in config files resolve relative to the config file. Paths in manifests resolve
relative to the manifest. Set `output_dir` to a writable Volume path, not ephemeral
workspace storage. Use a new `benchmark_output` path for every experiment.

Set bundle variables locally (none of these should contain credentials):

```sh
export BUNDLE_VAR_cluster_id='<existing-cluster-id>'
export BUNDLE_VAR_config_path='/Volumes/<catalog>/<schema>/<volume>/dataset/config.json'
export BUNDLE_VAR_manifest_path='/Volumes/<catalog>/<schema>/<volume>/dataset/manifest.json'
export BUNDLE_VAR_benchmark_output='/Volumes/<catalog>/<schema>/<volume>/benchmarks/qwen-v1'
export BUNDLE_VAR_delta_table='<catalog>.<schema>.extraction_history'
export BUNDLE_VAR_endpoint='<endpoint-name>'
export BUNDLE_VAR_model_revision='<registered-model-version>'
# Use this virtual environment so the bundle build can find python's build module.
export PATH="$PWD/.venv/bin:$PATH"
databricks bundle validate --target dev
databricks bundle deploy --target dev
databricks bundle run extract --target dev
# Or run the benchmark job:
databricks bundle run benchmark --target dev
```

Bundle deployment requires workspace authentication and has not been performed here.
The SDK and wheel dependencies install on the target cluster; its policy/network must
allow this. No Auto Loader is needed for this explicit per-job implementation.

Both CLI commands accept `--delta-table catalog.schema.table`. The destination is an
append-only Delta history with typed record ID/type/timestamp and a `VARIANT` payload.
Extraction records include raw and normalized outputs, graph candidate, and validation;
benchmark records include per-run metrics, artifact references, and a summary. Input
images remain in Volume storage. `VARIANT` provides flexible storage, while the Python
schema/geometry validators check data quality. Delta writes fail the command if they
fail; local result artifacts remain available for recovery. Re-executing a job creates
another extraction run, so application integration must enforce job-level idempotency.

## Benchmark real plans

Create a manifest following `examples/manifest.json`. Each case references an input
configuration and an independently human-labeled canonical-frame extraction. Include
known scale and reference routes where available. An unreachable reference route can
set `reachable: false`. Missing route endpoints count as failure even for unreachable
routes. Optional `distance_m` measures relative route-length error between snapped
roadmap nodes; it excludes the endpoint-to-node approach distances.

Split plans by building/source into development and held-out evaluation sets. Keep
DPI, image frame, calibration, grid spacing, clearance, thresholds, model weights,
and serving version fixed across comparisons. Ground truth should cover the same
features in every model run. Invalid annotation schemas abort evaluation; model
failures remain in the failure-rate denominator. A frame-size mismatch is an evaluation
failure. Include multiple real plans and repeated runs; a single example cannot estimate
accuracy or latency reliably. Report cold-start behavior separately if relevant.

Metrics in `benchmark.json`:

- Rooms/amenities: spatially matched (optionally rotated) box precision/recall/F1, matched IoU, normalized exact text
  accuracy on matched rooms, and text recall over all annotated rooms.
- Walls/walkable areas: one-to-one polygon IoU precision/recall/F1. Keep annotation
  segmentation consistent: differently split polygons can reduce this score.
- Doors: tolerance-gated one-to-one matching and position error on matched doors.
- Scale: relative error against an independent known scale (not a test of VLM math).
- Navigation: candidate edges crossing **ground-truth** walls, reference-route
  success, and optional relative route-distance error. Unsafe edges are excluded from
  route success even when the candidate omitted the wall.
- Operations: p50/p95 total and extraction latency, inference retries, failure rate,
  and candidate-valid rate. Latency excludes optional Delta writes and job startup.

Assignment maximizes valid match count before similarity, and never relies on
model-generated IDs. Text normalization only case-folds and collapses whitespace.
Quality summaries use evaluated runs; failure rate uses all runs. Always inspect both
so a model cannot look good merely by failing on hard inputs. Matched-only position
error should be read alongside door recall. Per-run route errors and similarities are
retained. `usage` and `cost_usd` remain null because custom GPU endpoints do not report
a reliable per-request dollar cost; use measured serving/compute billing for comparisons.

## Serverpod handoff

The exported candidate matches the domain fields of `CreateGraphRequest`:
`graphId`, `buildingId`, `name`, floors, nodes, edges, locations, and walls.
Floors retain pixel dimensions plus `metersPerUnit`; nodes/walls stay in pixels.
Edge cost is omitted so Serverpod can calculate distance using the floor scale.
This is a single-floor export. The building must already exist.

After review, a future authenticated Serverpod import endpoint should deserialize
these domain fields into generated Dart request types and call `MapGraphService`.
The JSON file is not a complete Serverpod wire-protocol request. Keep the existing
server validation as the final gate. Do not import an invalid/unreviewed graph: current
server graph status is active/deleted, not draft. Upload handling, async job tracking,
owner checks, idempotent submission, and the Flutter review screen are still application
integration work. No generated Dart files have been edited.

References: [custom model requests](https://docs.databricks.com/aws/en/machine-learning/model-serving/score-custom-model-endpoints),
[wheel bundle jobs](https://docs.databricks.com/aws/en/dev-tools/bundles/python-wheel),
[VARIANT queries](https://docs.databricks.com/aws/en/semi-structured/variant).
