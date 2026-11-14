# Role 3: Serverpod persistence

## Mission and current state

Turn the generated greeting starter into map and anchor persistence. Serverpod server and generated client exist; MadMaps models, authentication, submissions, and publishing do not. ../CONTRACTS.md is proposed and changeable, not an implemented API.

## Ownership and proposed interface

Own madmaps_server/ and regeneration of madmaps_client/. Do not manually edit generated client/protocol code. Own a future Flutter MapRepository adapter in coordination with navigation. Inputs: building/floor IDs, draft maps, and calibrated anchors. Outputs: summaries, published revisions, floor anchors, and submission identifiers through the proposed MapRepository operations.

Use Serverpod protocol models for transport/persistence and explicit domain adapters when necessary. Agree the canonical domain schema first. Keep endpoint validation and storage logic separate enough to test without UI.

## Task checklist

1. First task: run the generated greeting test/server and demonstrate a client response using README commands.
2. Agree shared schema and publication rules, then add building, floor, map revision, room/graph data, and anchor records.
3. Generate typed endpoints and migrations with the matching CLI; include generated changes in the same PR.
4. Implement published map reads and anchor reads before draft submissions.
5. Add submission validation: graph references, floor/revision alignment, complete anchor pose, finite coordinates, and expiry handling.
6. Keep drafts separate from immutable published revisions. Human review must precede publication; define reviewer authorization before exposing writes beyond trusted local development.
7. Add file storage with upload size/type checks and safe references; never store arbitrary client filesystem paths.

## Fixtures, tests, and acceptance

Use the future synthetic floor and fake anchor metadata from ../TESTING.md. Add endpoint tests for missing floors, invalid IDs, map revision mismatch, draft isolation, unauthorized writes, and published round trips. Run generation, analysis, and dart test; record database prerequisites or failures.

Done means navigation reads the agreed map through MapRepository, draft submissions cannot silently change published routing, and anchor metadata preserves full pose/revision. No real Cloud Anchor resolution occurs on the backend.

## Debugging and integration

For missing endpoint methods regenerate using the project CLI version. For connection errors check host/device addressing and configured database port. For schema mismatch inspect adapter mapping rather than changing generated code.

Keep Databricks tokens and database passwords outside tracked files. No auth is scaffolded; do not present anonymous development submissions as production safe. Coordinate transport changes with every client consumer. Stretch goals: accounts, review UI, audit history, and production deployment.
