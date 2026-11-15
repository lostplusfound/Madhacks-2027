# Training preparation

No cloud compute is provisioned by these preparation commands. GPU execution remains
untested until a real smoke test completes. Keep using the current live endpoint
until a candidate has been evaluated and explicitly deployed.

## Start locally, without spending

After saving real reviewed annotations, export the dataset ZIP from the lab.
Unpack it into a fresh directory, keeping image/target paths intact, then run:

```sh
.venv/bin/python -m madmaps_extraction.training \
  --manifest /path/to/dataset/manifest.json --validate-only
.venv/bin/python tools/prepare_training_kit.py
```

Validation checks geometry, checksums, path containment, duplicates and building/source
separation. It requires real reviewed train and validation examples; synthetic demo
examples are excluded. Include a separate test building for final evaluation.
One or two examples can check plumbing, not establish extraction quality.

The kit is under `runs/training-kit/`: a source ZIP containing only package files and
the registration script, plus `train_floorplans.ipynb` and a **non-executed**
`databricks-cluster-draft.json` (one g6e.2xlarge, 16.4 LTS GPU ML, 15-minute idle shutdown).
Those instance/runtime IDs were returned by this workspace, but capacity, price and
memory suitability still need confirmation. The draft creates a billable machine if
submitted; do not submit without explicit spending authorization. It excludes credentials,
connection settings, run history, photos, and reviewed datasets. Upload the dataset
separately. Rebuild the source ZIP after any subsequent code changes.

## Free attempt: Google Colab

Open https://colab.research.google.com and upload the prepared notebook. Select a
GPU runtime. The notebook uploads the source and reviewed-data ZIPs, installs optional
dependencies, validates the dataset, records a pinned Qwen revision, evaluates the base
model, and runs a two-step smoke test. Run cells individually; do not run the full
notebook unattended. Each training/evaluation subprocess exits to release GPU memory.

Free GPUs and session duration are not guaranteed. A supplied GPU may not have enough
memory for this configuration. The notebook limits visual pixels to 262144 for the
initial trial; annotations retain their canonical image coordinates. A smaller visual
budget can lose details, so use the same budget for baseline/candidate comparisons.
This is ordinary LoRA, not 4-bit QLoRA. If it runs out of memory, stop and reassess;
the kit does not purchase more resources or silently change model families.

After a successful smoke test, run a one-epoch candidate and compare validation reports.
Test data must stay out of tuning; evaluate the selected candidate and baseline on test
only after selecting settings. Download the evidence ZIP and model artifacts before the
runtime expires. Colab training must be described as Colab training, not Databricks training.

## Databricks execution when GPU access is authorized

The existing workspace has no clusters; its GPU pools API returned FEATURE_DISABLED
during the read-only check. GPU types are listed, but capacity, credits and launch
permissions have not been demonstrated. Listing node types is not a reservation.

Databricks Free Edition documents limited AI Runtime access for eligible LinkedIn-verified
accounts. Availability must be checked in the account; the existing cluster-based bundle
does not automatically run on serverless AI Runtime. Free Edition also restricts custom
GPU serving. Do not assume training access includes deployment access.

For classic compute, use one dedicated GPU ML node with no workers, a short idle shutdown,
and an explicitly authorized runtime budget. Idle shutdown does not stop an active training
job and is not a dollar cap. The existing `databricks/training.yml` references an existing
cluster and uses a six-hour task timeout; override that before a four-hour experiment.
Do not deploy the bundle unchanged as a spending safeguard.

Upload the kit and reviewed dataset to a writable Unity Catalog Volume. Import the notebook,
skip its Colab upload cell, and configure the ZIP/work paths. A Volume work directory keeps
artifacts persistent. Alternatively, use the existing wheel job after configuring cluster,
manifest, output and pinned revision. The lab launch button only submits a configured job;
it does not monitor training or deploy a model.

## Evaluation, MLflow and serving

`python -m madmaps_extraction.evaluate_vlm` evaluates local merged weights or a pinned base
model without a serving endpoint. Reports include per-example room/door/wall/walkable and
text metrics, latency and failure rate. Raw responses survive validation failures.
These reports do not evaluate navigation, scale or serving latency; use the existing
calibrated graph benchmark for those. Inspect individual plans as well as scores.

After validation selects a candidate, preserve its adapter, processor, merged weights,
`training_result.json`, base revision, exact package environment and evaluation reports.
The optional `databricks/register_vlm.py --local-weights ... --registered-name catalog.schema.model`
packages it with MLflow on authenticated GPU compute. Registration does not create serving.
Deployment requires a compatible endpoint and a separately authorized budget, then a
smoke test and an explicit update to `lab.local.json` using `api_format: custom`.

References:
- https://research.google.com/colaboratory/faq.html
- https://docs.databricks.com/aws/en/getting-started/free-edition-limitations
- https://huggingface.co/docs/trl/v0.21.0/en/sft_trainer
