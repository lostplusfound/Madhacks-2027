# Navigation and shared AR capture

The visitor app routes across Basement and Floors 1–3 through explicit stairs and elevator connections. Avoid stairs excludes stairs and escalators. Guidance pauses at a floor transition until stable resolution of a destination-floor anchor confirms location. The layers menu provides manual floor discovery recovery; AR height alone never confirms a floor. During an active cross-floor route, staying within 4 meters of the planned connector for 500 ms starts next-floor discovery independently of route-segment arrival. The live source-floor dot is cleared during the handoff; only a stable destination-floor anchor confirms the new floor. Failed handoff searches retry after 2 seconds. “I’m at the stairs—scan next floor” provides recovery when position drift misses the automatic trigger. Missing destination-floor anchors are reported explicitly.

## Map review

Basement and Floor 1 are the priority for further refinement. Hallways use centerline spines and short entrance branches. Basement routes follow the user-marked loop and middle aisle around the central tables; table footprints prevent diagonal shortcuts. Floor 1 bathroom routes bypass the highlighted divider. University → 1524 follows the west side of the gray core, the west-side hallway directly to the door nearest the Orchard Street exit, bypassing the east entrance foyer, following the user-marked route. The green University stair landings are the only stair connection between Basement and Floor 1. Floor 1 Main Stairs (yellow) are the only stairs connected to Floor 2. South, west, Cafe, and divider stairs have no lower-floor connections. Elevator connections and Floor 2–3 connections are retained.

Upper-floor corrections already made are retained; further upper-floor auditing is deferred. All geometry requires on-site verification. Entrances that cannot be identified remain unmapped. Walking times use estimated scales until measured captures are available. Avoid stairs is not a certified accessibility assessment.

## Use

Edit `serverUrl` in `madmaps_flutter/lib/client.dart` and hot reload. The getter is reread on reassembly, the client reconnects, repository caches are invalidated, and stale responses are rejected. The JSON config asset and SERVER_URL override are removed. Pending destinations and local anchor metadata are retained.

Open Community from the bottom bar; Profile and map-toolbar mapping shortcuts
also open Community. A floor without a compatible shared scan starts with two
known points at least 2 meters apart in the same AR session. Tap each point on
the plan and then its physical position on a visible floor surface, scan, host,
and share. Interrupted captures must restart; failed uploads are saved for retry.

Existing shared scans offer Add point, Remove point, and Remove entire shared
scan. Add point first resolves an existing anchor; the hosted pose is transformed
into the saved scan frame using a simultaneous tracked reference sample.
Removing a calibration point selects a valid remaining pair. Removing the final
usable pair requires confirming removal of the entire scan. Each scan supports
2 to 20 anchors. Edits publish immediately through Serverpod and compare the
original stored JSON to prevent overwriting concurrent edits. No schema migration
is needed. Deletions retain an expired record so queued uploads cannot resurrect
the scan. Retry pending uploads includes edits; discard conflicting edits in the
scan editor and refresh before editing again. Removal only unpublishes metadata,
not Google's hosted resources. Shared records take precedence over old local copies.

Community also lists local points and links to the original phone-only map tools.
On opening Community, a one-time import per phone/backend publishes the saved
Floor 1 snapshot. Local records remain untouched. Interrupted imports resume the
same payloads, and successful imports do not repeat. Other floors are excluded.
Cloud expiry is never extended; expired or uncalibrated points are reported and
kept locally. Missing image positions are derived from the existing calibration,
while local graph overrides are omitted from shared captures. More than 20 points
are split into scans retaining the same calibration pair.

Route previews and Community scan placement hide generated place labels and graph
lines. Tap anywhere on the floor plan to drop a red scan pin; it does not snap to
rooms or graph nodes. Pan and zoom remain available.

Choose a destination or select Plan a route to specify both endpoints. Current
location is the default start and requires visual localization before live
guidance. A named start displays an estimated route and numbered manual steps
without AR, including floor transitions and Avoid stairs. Manual checkboxes do
not track position or record arrival. Optional visual localization changes the
origin to the actual resolved position. Saved places now lives under Profile.

Restarting `scripts/start-local-backend.ps1` applies reviewed corrections, creates
missing floors, and verifies existing seed data. It does not replace existing
graphs with changed seed files. Image-only edits do not require reseeding; graph
edits require a matching backend graph update. Restart the app to reload maps.

The separate mapper entry point, from `madmaps_flutter`, is:

```powershell
flutter run -t lib/mapper.dart
```

The visitor entry point remains `lib/driver.dart`. Both use the existing Android package and pinned AR plugin; run the visitor entry point again to return from the mapper.

Captures publish immediately without sign-in or review in this prototype. Serverpod stores Cloud Anchor IDs, floor/revision metadata, transforms, expiry, calibration points, and movement coverage. Google hosts/resolves Cloud Anchors; raw imagery and ARCore feature maps are not uploaded to Serverpod. Compatible, unexpired metadata is cached locally. Movement coverage is not ARCore feature quality.

## Data and verification

The additive migration creates `ar_capture` and `floor_connector`. The launcher runs `bin/apply_map_corrections.dart` before seed verification. Entity comparisons and graph-version checks preserve unrelated edits and stop on conflicts. Seed helpers shut down without masking failures. The runner remains under the launcher's existing Ctrl+C lifecycle.

Regressions cover mapped-destination connectivity, wall intersections, bathroom and 1524 routes, connector choices, automatic stairs/elevator handoff without replacing the AR session, and capture persistence/retries/revision compatibility. Physical walking, native hosting, second-phone resolution, and connector pairing checks remain necessary. Serverpod/Dart MCP was unavailable during implementation; the local runner API/CLI fallback was used. No physical phone validation is claimed.

Cross-floor directions offer a Between floors choice of Elevator or Stairs in the planner, Map controls, and live route menu. Avoid stairs overrides the choice until stairs are allowed again. Unavailable choices report no connected route. The live position pointer is drawn above place markers and labels, at a constant screen size.
