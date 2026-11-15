# Integration procedure

## Current local Android integration

The Flutter entry flow opens the visitor Home screen, with Map, Saved, and
Profile tabs. Home searches the real floor-1 catalogue; Saved contains local
bookmarks and aliases. `MapStore` persists map and
anchor metadata plus floor calibration/overrides in SharedPreferences. Google
Cloud hosts/resolves Cloud Anchors directly. The floor image stays bundled; the graph and catalogue are read through the
generated Serverpod client. One validated FloorGraph is shared by the shell,
navigation and calibration tools. See [backend integration](LURAY_INTEGRATION.md).

1. Start the [backend script](LOCAL_WINDOWS_RUNTIME.md), then launch Flutter separately.
   Configure pinned plugin/keyless authorization using [AR setup](AR_PROTOTYPE.md).
2. Open **Profile > Manage AR maps and calibration**, create a map, host
   separated anchors, associate it with floor 1, and calibrate their image
   positions. Return to Map and select **Find my location**, or choose a
   destination from Home/Saved. Missing calibration opens a setup sheet and
   retains the selected destination.
3. Pick a room/amenity from search or a tappable marker. Dijkstra routes through
   hallway approaches; the UI shows route progress, turns, estimated ETA, and Cancel.
4. Switch tabs during a trip and return through its summary. Cancel clears the
   trip while localization continues; Back closes the session and clears the trip.
   Test heading-follow, interactive browsing, compact AR, far-from-segment starts,
   return guidance, automatic cloud retries, tracking loss, and background recovery.
5. Disable floor association to check the legacy layout without deleting setup.
   See [floor navigation](FLOOR_NAVIGATION.md) and [testing](TESTING.md).

Update root `nodes.csv`, `edges.csv`, and `locations.csv` together with their
matching copies in `madmaps_flutter/assets/floor1/`. The removed Swara
`assets/graph/` copies and mock routing engine are not used.
Update `madmaps_server/assets/floor1_seed.json` when changing the source CSVs;
seed fidelity tests detect drift. The seed verifier refuses to overwrite a changed
existing database graph, so coordinate intentional graph updates explicitly.
Preserve saved anchor frames and local overrides; never silently reinterpret
pixels as meters. Current graph/amenity approaches are draft and need on-site
walkability checks. Shared domain contracts remain proposals, not a description
of the current local serialization format.

Latest recorded checks: 94 Flutter tests, 24 backend tests, analysis without
errors/warnings and an Android debug APK build on November 14, 2026. A LAN client
graph read and room search also passed. Physical localization remains unverified.

## UI integration decisions

The merge on `integration/swara-ui` preserves Swara's screen flow and theme while
using real localization, routing, and position-based arrival. `NavigationSession`
coordinates the shell and existing native session owner; `AppState` stores UI
preferences separately from maps. No schema migration or backend change is needed.

Multi-floor and step-free routing, description-based localization, opening hours,
and report submission are omitted because no real implementation/data source
exists. See [the merge decisions and remaining checks](SWARA_UI_INTEGRATION.md).

## Backend integration

Serverpod supplies graph snapshots, destination search and category shortcuts.
Graph editing and issue reports exist on the backend but have no visitor UI in
this pass. Reads are anonymous; writes require authentication. The app retains
loaded data in memory, reports failed uncached requests, and requires a new
backend load after restart. Shared Cloud Anchor storage, server routing,
publication review and AI processing remain future work.

Use the [Windows launcher](LOCAL_WINDOWS_RUNTIME.md) for PostgreSQL, the patched
local runner, Floor 1 seeding and logs. It never launches Flutter. Ctrl+C stops
the runner and both local database instances. Follow `AGENTS.md` for MCP tooling
when available and never manually edit generated code.

## Future shared-domain integration

Agree a revision of the proposed contracts, introduce explicit repository and
localization service adapters, and coordinate shared types with the AR/navigation
owners. Validate floor/map revision, calibrated poses, and persistence semantics
before replacing local storage. Add publication/review and accessibility policies
before claiming verified routes. Cross-floor routing and shared anchor persistence remain unsupported. Luray
provides Serverpod models and migrations; those are separate from the phone
anchor/calibration serialization.
