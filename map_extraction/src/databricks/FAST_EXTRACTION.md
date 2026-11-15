# Fast map extraction

The user requested reliable map extraction with faster iteration and no wall
checks. The `fast-map-v1` profile extracts rooms/amenities, door points and walkable
polygons. Wall generation and wall metrics are omitted. The existing extraction
envelope is retained with an explicitly empty `walls` array.

Training uses compact JSON and 2-decimal coordinates. Insignificant floating-point
digits are removed; source walkable annotations are simplified within 2 pixels
while preserving topology. All 80 existing examples pass the transformed-target
checks. Average training-answer length drops from 6,848 to 3,335 characters.
Raw source labels and checksums remain unchanged. Predictions are never repaired,
clipped or simplified after generation to make them pass validation.

XGrammar 0.1.24 constrains output to the compact JSON schema and supported room
categories. Each request gets a fresh grammar matcher. Geometry, bounds and door
references remain checked after generation. Structural validity does not by itself
establish that the extracted map matches the image.

The profile keeps the source-model visual budget at 262,144 pixels, caps generation
at 4,096 new tokens and retains raw predictions. A token-limit exit is a failed
extraction. Fast-profile evaluation reports `walls_evaluated: false` and omits the
wall metric; it does not relabel an empty wall list as a perfect wall score.

## Current run

`fast-training.yml` adapts trial 02's merged model for three epochs, using the
memory-efficient loss already verified on one A10. It has a 30-minute cap and no
automatic retries. A two-plan validation pilot runs first; broader validation is
skipped when the pilot fails. A pilot is never sufficient to declare readiness.
The eight test plans remain untouched.

```sh
databricks air get 1095519663735379 --profile madmaps
databricks air logs 1095519663735379 --profile madmaps --tail 40
```

Artifacts are under:

```text
/Volumes/workspace/default/madmaps_training/training/cubicasa5k-20261115-trial-03-fast/
```

`fast-run.json` records this run. Successful training or valid JSON is not a claim
that the candidate is ready for map use. Room, door and walkable-area accuracy must
be measured before that claim can be made.

## Commands

Add `--extraction-profile fast` to the training and evaluation commands. Evaluation
also requires `xgrammar==0.1.24`; set `--max-new-tokens 4096` for the bounded fast
profile and `--limit 2` for a pilot. The default profile remains `full` for existing
commands. Saved fast models include `madmaps-generation.json` describing the
profile; a serving wrapper must use that profile consistently.

```sh
../.venv/bin/python -m unittest test_fast_extraction -v
```
