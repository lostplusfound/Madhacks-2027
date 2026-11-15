# Floor-plan model comparison and fine-tuning research

Updated 2026-11-15. No training run or deployment is claimed.

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
