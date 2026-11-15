# Navigation and shared AR capture

The visitor app routes across Basement and Floors 1–3 through explicit stairs and elevator connections. Avoid stairs excludes stairs and escalators. Guidance pauses at a floor transition until stable resolution of a destination-floor anchor confirms location. The layers menu provides manual floor discovery recovery; AR height alone never confirms a floor.

## Map review

Basement and Floor 1 are the priority for further refinement. Hallways use centerline spines and short entrance branches. Floor 1 bathroom routes bypass the highlighted divider. University → 1524 follows the west side of the gray core, the north foyer, and the east-side passage to its door, following the user-marked route. Basement Stair 4 connects to the Cafe/University stairs on Floor 1. The separate descending stair beside the divider is shown without an invented lower-floor pairing.

Upper-floor corrections already made are retained; further upper-floor auditing is deferred. All geometry requires on-site verification. Entrances that cannot be identified remain unmapped. Walking times use estimated scales until measured captures are available. Avoid stairs is not a certified accessibility assessment.

## Use

Edit `serverUrl` in `madmaps_flutter/lib/client.dart` and hot reload. The getter is reread on reassembly, the client reconnects, repository caches are invalidated, and stale responses are rejected. The JSON config asset and SERVER_URL override are removed. Pending destinations and local anchor metadata are retained.

Open mapping tools from Profile or the map toolbar. Select a floor and a known point on the plan. Tap that physical point on a visible floor surface, scan around it, and host the anchor. Repeat at a second known point at least 2 meters away, in the same AR session. Check calibration and select Share scan. Interrupted captures must restart the pair; failed uploads are saved for Retry pending uploads.

The separate mapper entry point, from `madmaps_flutter`, is:

```powershell
flutter run -t lib/mapper.dart
```

The visitor entry point remains `lib/driver.dart`. Both use the existing Android package and pinned AR plugin; run the visitor entry point again to return from the mapper.

Captures publish immediately without sign-in or review in this prototype. Serverpod stores Cloud Anchor IDs, floor/revision metadata, transforms, expiry, calibration points, and movement coverage. Google hosts/resolves Cloud Anchors; raw imagery and ARCore feature maps are not uploaded to Serverpod. Compatible, unexpired metadata is cached locally. Movement coverage is not ARCore feature quality.

## Data and verification

The additive migration creates `ar_capture` and `floor_connector`. The launcher runs `bin/apply_map_corrections.dart` before seed verification. Entity comparisons and graph-version checks preserve unrelated edits and stop on conflicts. Seed helpers shut down without masking failures. The runner remains under the launcher's existing Ctrl+C lifecycle.

Regressions cover mapped-destination connectivity, wall intersections, bathroom and 1524 routes, connector choices, automatic stairs/elevator handoff without replacing the AR session, and capture persistence/retries/revision compatibility. Physical walking, native hosting, second-phone resolution, and connector pairing checks remain necessary. Serverpod/Dart MCP was unavailable during implementation; the local runner API/CLI fallback was used. No physical phone validation is claimed.
