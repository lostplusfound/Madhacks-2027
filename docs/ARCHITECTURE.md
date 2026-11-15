# MadMaps architecture

## Current state

The Android app implements local named AR maps and first-floor indoor navigation.
The backend remains a generated Serverpod starter; it is not used by the current
AR/map flow. The published AR dependency stays pinned at
`ar_flutter_plugin_plus: 1.1.3`, with a documented local override under
`third_party/`. No shared/backend domain package or map API has been introduced.

Current data flow:

1. `MapStore` loads/saves `AnchorMap` records, saved poses/expiry, floor setup, and
   local overrides in SharedPreferences. Google Cloud resolves/hosts known IDs.
2. `ArAdapter` wraps the native session and consistent frame samples.
   `LocalizationController` maintains alignment, validates anchor handoffs,
   blends corrections, and schedules 20m/20s refresh. The session screen restarts
   discovery when the reference is cleared and handles lifecycle/cancellation.
3. `FloorGraph` loads the bundled floor-1 CSVs; `FloorSetup` calibrates AR X/Z
   meters to image pixels. `GuidanceState` computes directed routes, progress,
   structured maneuvers/ETA, distant attachments, and return-to-route recovery.
4. `NavigationPanel` composes controls and status. `InteractiveFloorMap` shares
   one pan/zoom/rotation transform across image and overlays, with screen-sized
   place targets and heading/position/free viewport modes. The persistent native
   camera changes between compact and expanded viewports without replacing its
   ARCore session. Disabling floor association restores the legacy layout.

Cloud refresh failure retains estimated movement when AR tracking is valid.
Tracking loss hides the dot and pauses directions; background/resume clears the
old pose and starts automatic map-scoped discovery. Route connectors outside the
graph remain estimated because no wall geometry is encoded. All floor-1 edges
and added amenity approaches remain draft.

See [floor navigation](FLOOR_NAVIGATION.md), [AR behavior](AR_PROTOTYPE.md), and
[verification](TESTING.md). The current implementation uses Flutter SDK state
management; the service boundaries below describe future shared-domain work.

## Proposed direction

Flutter presents floor plans and guidance. A future shared Dart package owns domain models. Localization translates AR session poses into floor-local building meters behind a service boundary. Routing consumes a published map and localized position. Serverpod would store maps, review state, and calibrated anchor metadata; its generated client connects Flutter to endpoints. Optional Python/Databricks tooling produces draft maps for human review.

These boundaries and all contracts are proposals, not fixed requirements. Revise them together before implementation. Start with Flutter SDK state management (ChangeNotifier/ValueNotifier) rather than adding a framework.

## MVP and later work

Android, one floor, one verified hallway route, and reliable anchor resolution are the MVP. Preserve floor IDs and map revisions for future multiple-floor support. Cross-floor edges must eventually identify stair/elevator transitions; failed anchor resolution is not evidence of floor identity. iOS interoperability, accounts, automated geometry, and global 3D reconstruction are outside initialization.

Unreviewed AI edges must not silently become published routes. Backend secrets stay server-side. Databricks is optional; manually authored draft JSON is the fallback. No provider access has been verified.
