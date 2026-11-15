# MadMaps architecture

## Current state

The Android app combines local AR localization and first-floor routing with
Serverpod graph/catalogue reads. The generated client exposes Luray's graph,
search, category, editing and reporting APIs; the visitor UI currently uses only
map/search reads. The AR dependency stays pinned at `ar_flutter_plugin_plus: 1.1.3`
with its documented local override under `third_party/`.

## Visitor UI and state ownership

`main.dart` composes the Swara-style visitor shell under
`madmaps_flutter/lib/features/shell/`. Home, Map, Saved, and Profile reuse place
rows, cards, sheets, search data, theme tokens, and distance formatting.

- `AppState` owns bookmarks/aliases by stable location ID, real-arrival visit
  history, units, contrast, and voice preferences. These use `madmaps.ui.v1`;
  map/anchor persistence keeps its existing key and format. Failed preference
  storage leaves the UI usable in memory and surfaces a status message.
- `NavigationSession` is the ChangeNotifier bridge for destination requests,
  cancellation, current guidance, and once-per-trip arrival. It is not a second
  routing or localization engine.
- `MadMapsShell` retains a nested Map navigator in an IndexedStack. The existing
  `MapSessionScreen` continues to own the native AR adapter, localization lifecycle,
  and guidance. Switching tabs retains this owner; closing the session disposes
  it. Speech consumes actual guidance/status changes rather than simulated steps.

Current data flow:

1. `MapStore` loads/saves `AnchorMap` records, saved poses/expiry, floor setup, and
   local overrides in SharedPreferences. Google Cloud resolves/hosts known IDs.
2. `ArAdapter` wraps the native session and consistent frame samples.
   `LocalizationController` maintains alignment, validates anchor handoffs,
   blends corrections, and schedules 20m/20s refresh. The session screen restarts
   discovery when the reference is cleared and handles lifecycle/cancellation.
3. `ServerMapRepository` loads and validates a Serverpod snapshot, adapting it to
   one shared `FloorGraph`. The bundled CSVs are seed/test source data, not a
   runtime fallback. `FloorSetup` calibrates AR X/Z meters to image pixels. `GuidanceState` computes directed routes, progress,
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

Swara's mock catalogue, graph parser, walking timer, and schematic map are not
used. The visitor shell consumes the existing floor catalogue and navigation
implementation. Unsupported source-branch features and merge resolutions are
listed in [UI integration notes](SWARA_UI_INTEGRATION.md).

See [floor navigation](FLOOR_NAVIGATION.md), [AR behavior](AR_PROTOTYPE.md), and
[verification](TESTING.md). The current implementation uses Flutter SDK state
management; the service boundaries below describe future shared-domain work.

## Backend and runtime boundaries

The shell injects a MapRepository, making real server reads replaceable in tests.
ServerMapRepository validates Floor 1 dimensions, finite coordinates and graph
references, maps backend locations to stable frontend IDs, and retains successful
search results in memory. Home debounces queries and ignores stale replies;
personal aliases stay local and merge into the results. A failed backend load
shows Retry. A loaded graph remains pinned through an active navigation session;
app restart requires another server load. There is no persistent offline map cache.

PostgreSQL stores shared graph data and reports. Cloud Anchor poses, floor
calibration, local overrides, bookmarks, preferences and visit history are not
uploaded. Backend lifecycle status active is not a claim of verified geometry.
The seed preserves draft review notes; edge costs and node coordinates remain
image pixels. Physical walking distances use phone calibration.

Luray's wall model is supported by backend validation, but the current Floor 1
seed has no polygons. The frontend rejects Floor 1 snapshots containing wall
constraints until its local router understands them. The backend's A* library
has no visitor routing endpoint; existing local routing still drives guidance.

On this Windows ARM64 machine, the project launcher manages two portable
PostgreSQL instances, prepares an ignored local Serverpod CLI workaround, starts
the runner without Flutter, seeds/verifies Floor 1 and follows runner.log. Ctrl+C
runs shutdown for the runner and both database clusters. See
[Windows runtime](LOCAL_WINDOWS_RUNTIME.md) for commands and failure diagnosis.

## Proposed direction

Shared anchor persistence, publication/review policy, server routing, a separate
shared domain package, multi-floor/accessibility routing, and AI map generation
remain future work. Domain contracts are proposals; coordinate changes rather
than treating the draft contract document as the implemented wire API. Keep the
existing Flutter SDK state management unless a concrete need justifies a change.
