# MadMaps architecture

## Current state

Fresh Flutter/Serverpod starter only. The selected third-party AR dependency is ar_flutter_plugin_plus exactly at 1.1.3. Application features are to be written during the hackathon. Generated example behavior is a scaffold smoke test, not MadMaps functionality.

## Proposed direction

Flutter presents floor plans and guidance. A future shared Dart package owns domain models. Localization translates AR session poses into floor-local building meters behind a service boundary. Routing consumes a published map and localized position. Serverpod stores maps, review state, and calibrated anchor metadata; its generated client connects Flutter to endpoints. Optional Python/Databricks tooling produces draft maps for human review.

These boundaries and all contracts are proposals, not fixed requirements. Revise them together before implementation. Start with Flutter SDK state management (ChangeNotifier/ValueNotifier) rather than adding a framework.

## MVP and later work

Android, one floor, one verified hallway route, and reliable anchor resolution are the MVP. Preserve floor IDs and map revisions for future multiple-floor support. Cross-floor edges must eventually identify stair/elevator transitions; failed anchor resolution is not evidence of floor identity. iOS interoperability, accounts, automated geometry, and global 3D reconstruction are outside initialization.

Unreviewed AI edges must not silently become published routes. Backend secrets stay server-side. Databricks is optional; manually authored draft JSON is the fallback. No provider access has been verified.
