# Role 2: floor-plan drafts

## Mission and current state

Produce a useful human-reviewable draft map, optionally assisted by Databricks. No AI pipeline, provider access, sample schema validator, or domain package exists yet. ../CONTRACTS.md is a negotiable proposal; agree serialization with navigation/backend before exporting data.

## Ownership and proposed interface

Own future tools/floorplan_ai/ and AI prompts/preprocessing. Coordinate synthetic fixtures with navigation. Input: image or rendered PDF page, original pixel dimensions, floor/building IDs, and calibration evidence. Output: proposed IndoorMap JSON with provenance and uncertain edges clearly marked. Use original image pixels for u/v; do not silently export resized-image coordinates.

Separate preprocessing, provider calls, extraction normalization, geometry checks, and export. Keep provider configuration replaceable and credentials server-side. Notebook-to-JSON export is acceptable; do not introduce a service just for the demo.

## Task checklist

1. First task: manually author a small draft compatible with the agreed schema, so downstream work does not depend on a model.
2. Obtain a real floor plan with permission to use it. Preserve dimensions and record any resize transform.
3. Check actual Databricks workspace/model/image-input access with a minimal request. Record failure and continue manually if unavailable.
4. Extract room labels, door candidates, corridors, stairs, elevators, and ambiguity. Use deterministic image processing for geometry where useful.
5. Convert candidates into nodes/edges, resolving IDs and room entrance references. Validate edges against walkable areas and inspect visually.
6. Export a draft with unknown accessibility and unverified connections; require human review before publication.

## Fixtures, tests, and acceptance

Agree a synthetic map with three rooms and two corridor intersections. Add malformed IDs, disconnected rooms, and resized-image cases. Future validator should reject broken references and singular calibration. Run Python checks only once actual tooling exists; no Python installation commands or model tests are claimed in this scaffold.

Done means backend/navigation can consume the same draft, a reviewer can see uncertain geometry, and manual generation works without Databricks. Model output must not be treated as measured geometry or verified walkability.

## Debugging and integration

For shifted doors check resizing/cropping transforms. For hallucinated connections overlay candidates on the source and inspect walls. For schema failures compare agreed enum values and IDs rather than adding independent interpretations.

Deliver JSON and source dimensions to navigation; agree draft upload with backend. Stretch goals: OCR, corridor segmentation, automated editor suggestions, and improved uncertainty scoring.
