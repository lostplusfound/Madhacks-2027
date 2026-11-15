# Floor-plan model comparison and fine-tuning research

Updated 2026-11-15. No training run or deployment is claimed.

## GPU startup attempt: 2026-11-15

Restored Databricks authentication and checked the workspace: no existing clusters
or jobs were returned before the preflight. The CLI supports serverless AI Runtime,
so an existing classic cluster is not required for that execution path.
Submitted `gpu-preflight.yml` requesting one A10, no retries, and a five-minute
timeout. Configuration validation succeeded, but allocation failed immediately:
`RESOURCE_EXHAUSTED`: the configured `max-num-nodes-gpu-1xa10` limit is **0**.
Run: https://dbc-be616652-c982.cloud.databricks.com/jobs/runs/257781238113368.
No GPU training started. Other GPU types' quotas were not tested.
See `gpu-preflight-result.json` for the recorded result and public dataset metadata.

The user has no labeled dataset. CubiCasa5K is a candidate for an initial
noncommercial geometry experiment: its publisher provides 5,000 annotated plans,
and its license is CC BY-NC 4.0. Zenodo lists a 5,469,495,706-byte ZIP with MD5
`0ce0b203d1e3c125b51087b219bd23b9`. It has not been downloaded or converted.
Its SVG annotations need conversion and validation against MadMaps' schema;
automatically converted examples must not be represented as manually reviewed
MadMaps labels. GPU access and usable converted data remain prerequisites.

### GPU access recheck after user account update

The second preflight succeeded on 2026-11-15 at 13:22 UTC:
https://dbc-be616652-c982.cloud.databricks.com/jobs/runs/688116848383551.
`nvidia-smi` reported `NVIDIA A10G, 23028 MiB`. The bounded check completed
successfully in 42 seconds. The earlier zero-quota failure is resolved for one A10
in this workspace. This confirms GPU allocation, not VLM training; dataset
conversion and validation are still outstanding.

### Public dataset preparation completed

Prepared an 80-plan CubiCasa5K starter subset: 64 train, 8 validation, 8 test,
preserving official source splits. Accepted plans pass geometry, schema,
reference, provenance, file checksum and decoded-pixel duplicate checks. There
were 109 rejected candidates. The annotation policy is explicitly automatic public
conversion, with zero manually reviewed MadMaps examples. The trainer/evaluator
now require `--allow-public-annotations` to consume this data.

Uploaded the accepted examples, source annotations, overlays, reports and current
training source to
`/Volumes/workspace/default/madmaps_training/cubicasa5k-trial-c7713c30f808/`.
Downloaded the remote portable ZIP and verified its SHA-256 and member CRCs.
Dataset ZIP SHA-256:
`ad859398c4b525598256085329add2c5eb5862a71597c7d7d209284a54c24b68`.
The 37 existing tests and 13 public-dataset regression tests pass. Dataset
preparation did not start training. See [PUBLIC_DATASET.md](PUBLIC_DATASET.md)
for artifacts, commands, mapping limitations and license notices.

The live Zenodo dataset metadata records **CC BY-NC-SA 4.0**, whereas the
publisher repository's license records **CC BY-NC 4.0**. Earlier research notes
only mentioned the repository notice. Both notices are now retained with the
data; the experimental subset carries noncommercial/share-alike terms.

### GPU training pipeline launched

Submitted run https://dbc-be616652-c982.cloud.databricks.com/jobs/runs/539375730767571
on one A10 with a 90-minute timeout and zero automatic retries. Environment
installation and remote dataset validation passed; the last observed stage was
`baseline-validation`. The pipeline then runs two optimizer steps, checks smoke
success, runs one epoch on 64 training plans, and evaluates the candidate on eight
validation plans. Eight test plans remain outside training and model selection.
The model revision is `66285546d2b821cf421d4f5eb2576359d3770cd3`.
No completed training or quality improvement is claimed at submission time.
See `training-run.json`, `public-training.yml`, and `run_training_trial.py`.
Six additional regression tests cover failure gating and source verification.

### First training failure and memory fix

Trial 01 completed baseline evaluation: all eight predictions failed JSON/schema
validation. It then failed before its first optimizer step with CUDA OOM in
cross entropy, requesting an additional 5.87 GiB with 2.97 GiB free. The smoke
process recorded peak allocation 18,837,710,336 bytes and peak reservation
23,095,934,976 bytes. No one-epoch candidate started in that run.

Submitted trial 02:
https://dbc-be616652-c982.cloud.databricks.com/jobs/runs/355972322118525.
It uses the same A10, model, dataset and hyperparameters, with optional Liger 0.6.2
fused loss and `skip_logits` during training and loss evaluation. It reuses the
complete baseline only after checking report hash, model revision, manifest hash,
split, visual budget and prediction count. Training source is versioned separately
as `madmaps-training-source-liger-v2.zip`; trial 01 artifacts remain intact.
The 58 local tests pass. GPU success remains to be established by the resumed
smoke test; a submitted/running job alone does not establish that the fix works.

### Trial 02 completed: training works, candidate quality fails

Databricks run 355972322118525 completed successfully at 14:46 UTC. The two-step
smoke test passed, followed by 16 optimizer steps covering one epoch on 64 plans.
The candidate training process took 241.55 seconds, with peak GPU allocation
10,746,995,712 bytes (10.01 GiB). Held-out teacher-forced validation loss was
0.40558; that loss is not an extraction-quality score.

All eight generated validation predictions failed: four JSON decoding failures
and four schema validation failures. The baseline also had zero valid predictions
out of eight. Inspected candidate outputs repeat coordinates, truncate JSON, or
use unsupported room categories. This trial establishes GPU training integration,
but does not establish a usable floor-plan extractor or a quality improvement.
No test-set generation was run and no model was promoted or deployed.

Verified the saved adapter, model configuration and two merged weight shards in
the trial's `candidate/` directory. Stage logs, raw predictions and final reports
remain in the Volume. `training-summary.json` records results and file inventory;
the same summary was saved remotely as `trial-summary.json`.

## Decision to test first

Compare available hosted models before investing in fine-tuning. The authenticated
workspace inventory includes Llama 4 Maverick and Gemma 3 12B with image input.
The available Qwen 3.5 122B A10B endpoint is text-only and is excluded from future
image comparisons. Its two initial BAD_REQUEST failures are compatibility failures,
not quality measurements.
`compare_models.py` makes one inference per model per fixture, retaining raw output,
validation failures, feature metrics, graph checks and latency. It does not provision
compute, create endpoints or update the app's selected model.

The current two labeled fixtures are synthetic. A winner on these is provisional;
there is no reviewed, independent real-plan evaluation manifest in the repository.
Use real campus plans from separate buildings/source documents for model selection.
Keep all pages/variants of each building in one split. Choose on validation; reserve
an untouched building for final test. Obtain permission for the plans used.

Selection priority:

1. Valid output and usable geometry; count failures on every attempted plan.
2. No graph edges crossing annotated walls and correct reachable/unreachable routes.
3. Door, wall and walkable-area recall/F1 alongside room and amenity detection.
4. Text recall, latency, and measured inference cost when available.

Do not declare a production winner if every candidate fails the safety criteria.
Missing navigation metrics are unavailable evidence, not a passing result. Inspect
source overlays and raw output because aggregate scores can hide unsafe geometry.

## Fine-tuning experiment after the comparison

The existing candidate is Qwen2.5-VL-3B-Instruct with TRL 0.21.0 and LoRA rank 16,
learning rate 1e-4, batch size 1, gradient accumulation 4, and seed 42. These are
starting settings, not measured optima. It is ordinary LoRA, not 4-bit QLoRA.
Keep the model revision, prompt, image budget and evaluator identical between
baseline and candidate. The current trial budget is 262144 visual pixels. This can
lose small text and thin door gaps; test a larger budget separately after the GPU
smoke test, rather than mixing budgets in a comparison.

Run dataset validation, base validation, two optimizer steps, then one epoch only
if the smoke test succeeds. Measure peak GPU memory and time before larger trials.
Compare generated geometry and navigation, not training loss alone. The collator
masks prompt/image/padding tokens; sequence truncation is disabled. Preserve exact
package versions and all failed predictions with the adapter and processor.

CubiCasa5K is a possible geometry pretraining resource, but its labels require a
reviewed conversion to this schema and its plan distribution does not establish
campus-building performance. Its published license is CC BY-NC 4.0. Keep data
provenance and applicable terms with each dataset; do not assume all Qwen checkpoints
share a license.

## Execution choices and verified sources

- [Databricks vision querying](https://docs.databricks.com/aws/en/machine-learning/model-serving/query-vision-models): image-input protocol and model limitations.
- [Supported Databricks models](https://docs.databricks.com/aws/en/machine-learning/foundation-model-apis/supported-models): check modality support for each endpoint.
- [TRL 0.21 SFT](https://huggingface.co/docs/trl/v0.21.0/sft_trainer): version-specific trainer and sequence-length settings.
- [Qwen2.5-VL 3B model card](https://huggingface.co/Qwen/Qwen2.5-VL-3B-Instruct): candidate model and image preprocessing guidance.
- [CubiCasa5K](https://github.com/CubiCasa/CubiCasa5k) and [published license](https://github.com/CubiCasa/CubiCasa5k/blob/master/LICENSE): dataset and terms.
- [Colab FAQ](https://research.google.com/colaboratory/faq.html): free GPU resources and runtime duration are not guaranteed.
- [Databricks Free Edition limits](https://docs.databricks.com/aws/en/getting-started/free-edition-limitations): serverless-only compute, limited AI Runtime access after eligible verification, and no GPU serving endpoints. A classic-cluster bundle needs a different execution path there.

The existing training notebook can attempt a free Colab GPU. Databricks classic GPU
execution remains a separately budgeted option. Hosted-model evaluation does not
establish that a fine-tuned model can be trained or served in the same account.

## First live comparison: 2026-11-15

Six requests, one per fixture/model, temperature 0, same prompt, structured-output
schema and 8192 output-token budget. Exact hosted revisions were not pinned; this
is a point-in-time smoke test. See `comparison-summary.json` for measured evidence.

| Model | Doorway fixture | Amenities fixture | Total request latency per fixture |
| --- | --- | --- | --- |
| Llama 4 Maverick | Rejected by geometry validation: invalid walkable polygon | 3/3 spatial/text amenity matches, but invented walls/doors/walkable geometry | 13.93s / 15.36s |
| Gemma 3 12B | Room, wall, door and walkable F1 all 0; reference route failed | 1/3 spatial/text matches | 5.93s / 3.73s |
| Qwen 3.5 122B A10B endpoint | Image request rejected | Image request rejected | Not a vision quality comparison |

Decision: **no overall winner yet**. Keep Llama as the provisional amenity-label
baseline; neither vision model passes the calibrated doorway/navigation case.
Amenities have no scale calibration, so candidate-valid rate is not a fair safety
ranking for that fixture. Both invent/miss features. Do not replace failed geometry
with model output merely because room labels look correct. Next comparison needs
independent reviewed real plans; further synthetic repetitions cannot supply them.
