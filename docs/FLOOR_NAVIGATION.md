# First-floor navigation

The integration combines the existing AR prototype with the first-floor graph from main and the corrected 1632 × 1056 Morgridge Hall image. Only floor 1 is enabled. All graph edges are draft: an image overlay is not evidence of physical walkability, entrance accuracy, or accessibility.

## Setup on the phone

1. Open or create an AR map and save at least two anchors at identifiable landmarks, at least 2 meters apart. A larger separation generally makes placement errors less influential.
2. Open **Floor 1 setup** from the map's home-screen menu or the edit-location icon in the AR session.
3. Enable **Associate this AR map with floor 1**. Select each anchor and tap its physical location on the plan. Pinch and pan to place points precisely.
4. Select exactly two **Calibrate** chips. The transform is derived from their saved horizontal AR positions and image points; height is ignored. No compass north setting is required.
5. Place a third anchor as a check without selecting its calibration chip. Its check error compares its measured AR position against the independently placed image point. Recheck placement if the error is excessive for the hallway being used.
6. Return to the session, use Locate to search saved anchors, and open **Rooms** using the directions icon. Search by name, room number, or alias and select a mapped destination.

Existing maps and direct anchor guidance continue to work without calibration. In the Anchors menu, **Navigate via hallways** is available after explicitly linking that anchor to an approach node in setup. Tapping the anchor itself retains direct, straight-line guidance.

## Draft editing

Setup can move an existing graph node or associate a room/anchor with an approach node. Changes are local overrides; source CSVs remain unchanged. Moving a node recalculates incident edge lengths. Repositioning or deleting either calibration anchor invalidates the calibration. Editing a third check anchor does not invalidate the selected pair.

The bundled CSVs are snapshots of the root `nodes.csv`, `edges.csv`, and `locations.csv`. After teammate updates, refresh their copies in `madmaps_flutter/assets/floor1/` together and rerun the asset/import tests. The loader validates references and imports floor 1 only. Other-floor rooms are omitted from the current destination picker.

## Guidance behavior

Associated maps open with a full floor map, an expandable AR camera overlay,
location heading, remaining route, turn banner, estimated walking duration and
arrival time, and Cancel. Walking estimates use 1.2 m/s. Pan to stop following;
Recenter resumes following and Map overview shows the entire plan. Mapping
actions are in the toolbar menu. Disable **Associate this AR map with floor 1**
to restore the legacy AR layout; saved calibration and overrides are retained.

Opening an associated map automatically searches its unexpired anchors, in
batches of at most 20. Locate retries the search and Cancel search stops it.
The six restroom, elevator and main-stair destinations now have draft entrance
approaches derived from the plan. Their earlier unmapped state was caused by
empty route-node assignments, independent of Cloud Anchor proximity. These new
approaches still require physical entrance and walkability checks.

Dijkstra respects imported costs and directionality. Route starts can attach within 3 meters of any mapped walk edge, including room and exit approaches. Nearby attachments are checked for a directed path; the nearest valid attachment wins, with route cost breaking distance ties. This fixes starts near the University exit, whose approach was previously excluded. Rooms without an assigned route node show **Not mapped yet**. Invalid destinations, missing nearby walkways, and disconnected routes have distinct messages.

Guidance tracks projected distance along the route. The initial projection is not a point you must visit. While walking beside the line, the compass translates a forward vector to your actual position instead of aiming sideways or backward at the centerline. Its 2-meter lookahead stops at the next turn. Left/right instructions use bends of at least 30 degrees; turn and remaining distances come from projected progress. The actual map position stays unsnapped.

Segment matching favors the current leg within 3 meters, advances through connected turns, and reassesses progress after missed samples or localization corrections. Reverse walking updates progress too. More than 4 meters from the route starts a 2-second off-route timer; returning within 3 meters cancels it. Forward guidance continues during that grace period. Afterward, navigation recalculates from nearby mapped edges or pauses with the specific failure reason. Arrival requires actual proximity within 1.5 meters of the final approach; projection alone cannot trigger it.

Thresholds are centralized in `NavigationTuning`. Development builds emit `[MadMaps navigation]` diagnostics for the destination, selected start edge, attachment distance, calibration scale, progress, and failure reason. Messages are throttled by state transitions and 5-meter progress intervals. These tolerances accommodate walking and localization error; the draft graph still does not encode hallway widths or wall geometry.

Guidance pauses when tracking/localization is unavailable. Same-map anchor handoffs retain the destination and reassess progress; changing maps clears the destination. A lost fix does not display a live map position. Floor transitions are unsupported.

## Verification

Automated coverage includes CSV imports, shortest paths, directionality, start projection, invalid/unreachable destinations, calibration/inverse transforms, legacy storage, turn instructions, guidance progression and loss, rerouting, image taps under zoom/letterboxing, and setup persistence. Routing regressions include University exit to Cafe across calibration scales, every mapped approach-to-approach pair, parallel walking offsets, missed turns, reverse movement, nearby parallel legs, and off-route hysteresis.

The first-floor graph has been visually overlaid on the corrected image. Verify the south lobby/stair area and destination approaches on site. Physical acceptance still requires calibrating two anchors, checking a third landmark, and walking a first-floor route with multiple turns and an anchor handoff. Serverpod/Dart MCP tools were unavailable during implementation, so app hot restart, live driver navigation, and runner/app log inspection could not be performed in this session.
