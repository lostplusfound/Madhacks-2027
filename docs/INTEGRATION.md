# Integration procedure

## Current local Android integration

The Flutter entry flow opens the visitor Home screen, with Map, Saved, and
Profile tabs. Home searches the real floor-1 catalogue; Saved contains local
bookmarks and aliases. `MapStore` persists map and
anchor metadata plus floor calibration/overrides in SharedPreferences. Google
Cloud hosts/resolves Cloud Anchors directly. The bundled floor-1 image and CSV
graph are loaded by Flutter; Serverpod domain endpoints, generated client models,
and database migrations are not part of this flow.

1. Configure the pinned plugin/keyless authorization using [AR setup](AR_PROTOTYPE.md).
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
Preserve saved anchor frames and local overrides; never silently reinterpret
pixels as meters. Current graph/amenity approaches are draft and need on-site
walkability checks. Shared domain contracts remain proposals, not a description
of the current local serialization format.

Latest recorded local checks: 88 Flutter tests, analysis without errors/warnings,
and a successful Android debug APK build on November 14, 2026. These are not a
physical localization test or proof of backend map integration.

## UI integration decisions

The merge on `integration/swara-ui` preserves Swara's screen flow and theme while
using real localization, routing, and position-based arrival. `NavigationSession`
coordinates the shell and existing native session owner; `AppState` stores UI
preferences separately from maps. No schema migration or backend change is needed.

Multi-floor and step-free routing, description-based localization, opening hours,
and report submission are omitted because no real implementation/data source
exists. See [the merge decisions and remaining checks](SWARA_UI_INTEGRATION.md).

## Optional starter backend integration

README describes the generated endpoint/client greeting example. That verifies
framework wiring only. Backend map persistence, shared domain types, review state,
AI processing, and production map publication remain future work. Any future
backend implementation must use Serverpod. Follow `AGENTS.md` for runner,
generation, migration, restart, and log tooling; do not edit generated code.

For an emulator/backend round trip, use 10.0.2.2 for the host; a physical phone
uses the development machine's LAN address and suitable firewall/network settings.
`SERVER_URL` is relevant to this greeting/backend flow, not the local AR/map flow.
See [setup history](SETUP_STATUS.md) for earlier environment blockers.

## Future shared-domain integration

Agree a revision of the proposed contracts, introduce explicit repository and
localization service adapters, and coordinate shared types with the AR/navigation
owners. Validate floor/map revision, calibrated poses, and persistence semantics
before replacing local storage. Add publication/review and accessibility policies
before claiming verified routes. No cross-floor routing, backend migration, or
shared domain package was introduced by the local navigation enhancements.
