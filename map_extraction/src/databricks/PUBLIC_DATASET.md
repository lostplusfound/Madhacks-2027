# CubiCasa5K starter dataset

Prepared 2026-11-15 for the MadMaps GPU training trial. This is an **80-plan
experimental subset**, with 64 training, 8 validation and 8 test examples. It
preserves the publisher's official splits. Source-plan IDs, encoded image hashes,
decoded pixel hashes and source annotation hashes are distinct across the subset.
The dataset does not provide reliable building IDs, so building-level independence
is not established.

The accepted targets contain 742 room/space boxes, 459 structural polygon pieces,
617 source door openings represented by 1,149 door-to-room links, and 747 derived
indoor-space polygon pieces. The converter rejected 109 candidates; the reasons
and source paths are in `rejections.json`. All 80 accepted examples pass schema,
bounds, polygon, reference, provenance and checksum validation.

## Files

Local artifacts are in `datasets/cubicasa5k-trial/` (Git-ignored):

- `manifest.json`: relative image/target paths, source split and provenance.
- `madmaps-public-dataset.zip`: accepted PNG/SVG/JSON files, overlays, preview,
  split lists, license notices, converter snapshot and validation reports.
- `madmaps-training-source.zip`: current package source, including the explicit
  public-annotation loader option; excludes credentials and local configuration.
- `preview.jpg`: a 12-plan overlay contact sheet. Each accepted example also has
  a full-resolution `overlay.png`; red marks structural exclusions, blue outlines
  show room boxes, orange points show door links, and green shows derived indoor
  space.
- `provenance.json` and `zenodo-record.json`: publisher metadata and conversion
  details. The saved converter snapshot's SHA-256 is recorded in provenance.
- `validation.json`: acceptance counts, failures and conversion limitations.
- `upload-result.json`: Databricks upload and remote ZIP verification result.

The Databricks destination is:

```text
/Volumes/workspace/default/madmaps_training/cubicasa5k-trial-c7713c30f808/
```

The manifest SHA-256 is:

```text
c7713c30f80871606f1dfcd62e8131ab0236220bfa1fb6aa0d543cba4905f334
```

## Annotation meaning and limits

Targets are **automatically converted public annotations**, with `reviewed: false`.
The trainer rejects these by default. `--allow-public-annotations` explicitly
accepts them for experiments while retaining source/target checksum validation
and split checks. It does not admit unreviewed private examples without public
provenance. Training/evaluation reports record whether this option was enabled.

Room labels are the source semantic classes, not verified transcriptions of text
printed on the plan. Room categories are mapped to existing MadMaps categories,
with unsupported classes mapped to `other`.

Following the publisher's loader, SVG geometry uses the **direct pixel frame of
`F1_scaled.png`**. SVG canvas dimensions can differ from PNG dimensions because of
image margins; stretching the SVG canvas to match the raster would misalign the
labels. Ancestor/polygon affine transforms are applied. Geometry is quantized to
0.01 pixels, with at most 2 pixels of image-boundary overflow clipped.

Door footprints cut openings in structural polygons, then link to one or two
touching annotated spaces within 2 pixels. Ambiguous adjacency rejects the entire
plan. Structural exclusions include walls, railings and columns. Holes are
decomposed into polygon pieces instead of being filled. Invalid polygons,
unsupported geometry, multi-floor plans, duplicates and overly long targets are
rejected, creating selection bias toward convertible plans.

Green areas are indoor space footprints minus structural exclusions. Furniture,
clearances, accessibility and true traversability are not certified. No calibrated
scale or navigation graph is supplied. This residential starter set is suitable
for checking training integration; it does not establish campus navigation quality.

## Reproduce and validate

From this directory, using the project's existing Python environment:

```sh
../.venv/bin/python public_dataset.py \
  --output datasets/cubicasa5k-new-trial --train 64 --validation 8 --test 8
../.venv/bin/python public_dataset.py \
  --output datasets/cubicasa5k-new-trial --validate-only
../.venv/bin/python -m madmaps_extraction.training \
  --manifest datasets/cubicasa5k-trial/manifest.json \
  --allow-public-annotations --validate-only
../.venv/bin/python -m unittest test_public_dataset -v
```

The downloader reads only selected members using HTTP ranges, verifies ZIP member
CRCs, and records SHA-256 for accepted files. It checks the published archive size
and MD5 metadata before reading. It cannot verify the complete 5.5 GB archive MD5
without downloading the entire archive. `--archive /path/to/cubicasa5k.zip` can use
an existing complete ZIP. `--cache /path/to/previous-output` reuses raw members
only after checking their size and original ZIP CRC.

Before GPU training, install the packaged training dependencies, preserve a full
Hugging Face commit SHA, evaluate a baseline on validation, then run a bounded
two-step smoke test. Add `--allow-public-annotations` to both training and
evaluation commands. Hold test labels out of tuning. Dataset preparation itself
does not start training or deploy a model.

## GPU training pipeline

`public-training.yml` runs the pinned Qwen2.5-VL-3B revision on one A10, with a
90-minute wall-clock limit and no automatic retries. `run_training_trial.py`
verifies dataset/source hashes and reuses the completed, checksum-verified baseline
from trial 01, then runs a two-optimizer-step smoke test, one training epoch, and
candidate validation. The baseline's model revision, manifest, split, visual budget
and eight predictions must match before it can be reused. An incomplete evaluation,
GPU execution error or failed smoke test prevents later stages from starting.
Malformed baseline predictions are retained as quality failures. The test split
is not evaluated during this trial. No model is automatically deployed.

The submitted run and persistent artifact directory are recorded in
`training-run.json`. Check it with:

```sh
databricks air get 355972322118525 --profile madmaps
databricks air logs 355972322118525 --profile madmaps --tail 50
databricks fs cat dbfs:/Volumes/workspace/default/madmaps_training/training/cubicasa5k-20261115-trial-02-liger/status.json --profile madmaps
```

Baseline/candidate predictions, evaluation reports, stage logs, package versions,
elapsed time and peak GPU memory are saved in that directory. The smoke test's
merged model stays temporary; the candidate's adapter and merged weights persist
under `candidate/`. A new trial needs a unique `MADMAPS_TRIAL_ID` and idempotency
key so previous evidence is preserved.

Trial 01 completed baseline evaluation, with all eight predictions failing schema
or JSON validation, then ran out of GPU memory in the first training loss calculation
before completing an optimizer step. Trial 02 preserves that evidence and uses
`liger-kernel==0.6.2` fused linear cross entropy, enabled by the trainer's optional
`--use-liger-kernel` flag. The collator requests loss without vocabulary logits
during both training and loss evaluation. Dataset, model, rank, learning rate and
visual budget are unchanged. Inputs are unpacked locally after hash verification
to avoid repeated remote file reads; outputs still persist in the Volume.

Trial 02 is complete. The smoke test passed and the candidate completed 16
optimizer steps (one epoch). The training process took approximately four minutes
and used 10.01 GiB peak allocated GPU memory. Both the adapter and merged model
are saved and their file inventory is in `training-summary.json`.

Generated validation quality failed: **0/8 valid predictions**, with four JSON
decoding failures and four schema failures. The baseline was also 0/8. This trial
proves training execution, not useful extraction accuracy. The model remains an
experimental artifact and has not been promoted or deployed.

## Attribution and license notices

CubiCasa5K v1.0 is by Ahti Kalervo, Juha Ylioinas, Markus Haikio, Antti Karhu and
Juho Kannala (2019), [DOI 10.5281/zenodo.2613548](https://doi.org/10.5281/zenodo.2613548).
The downloaded Zenodo metadata says **CC BY-NC-SA 4.0**; the
[publisher repository notice](https://github.com/CubiCasa/CubiCasa5k/blob/master/LICENSE)
says **CC BY-NC 4.0**. Both notices are preserved, and the converted subset carries
the stricter noncommercial/share-alike notice. It is not prepared for commercial
use. Original PNGs and SVGs are unchanged; JSON targets and overlays are derivatives.

Coordinate handling follows the
[publisher's scaled-image loader](https://github.com/CubiCasa/CubiCasa5k/blob/master/floortrans/loaders/svg_loader.py)
and [SVG annotation loader](https://github.com/CubiCasa/CubiCasa5k/blob/master/floortrans/loaders/house.py).
