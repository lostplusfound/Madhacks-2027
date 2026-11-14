# First-floor navigation

The integration combines the existing AR prototype with the first-floor graph from main and the corrected 1632 × 1056 Morgridge Hall image. Only floor 1 is enabled. All graph edges are draft: an image overlay is not evidence of physical walkability, entrance accuracy, or accessibility.

## Setup on the phone

1. Open or create an AR map and save at least two anchors at identifiable landmarks, at least 2 meters apart. A larger separation generally makes placement errors less influential.
2. Open **Floor 1 setup** from the map's home-screen menu or the edit-location icon in the AR session.
3. Enable **Associate this AR map with floor 1**. Select each anchor and tap its physical location on the plan. Pinch and pan to place points precisely.
4. Select exactly two **Calibrate** chips. The transform is derived from their saved horizontal AR positions and image points; height is ignored. No compass north setting is required.
5. Place a third anchor as a check without selecting its calibration chip. Its check error compares its measured AR position against the independently placed image point. Recheck placement if the error is excessive for the hallway being used.
6. Return to the AR session, localize near a saved anchor, and open **Rooms** using the directions icon. Search by name, room number, or alias and select a mapped destination.

Existing maps and direct anchor guidance continue to work without calibration. In the Anchors menu, **Navigate via hallways** is available after explicitly linking that anchor to an approach node in setup. Tapping the anchor itself retains direct, straight-line guidance.

## Draft editing

Setup can move an existing graph node or associate a room/anchor with an approach node. Changes are local overrides; source CSVs remain unchanged. Moving a node recalculates incident edge lengths. Repositioning or deleting either calibration anchor invalidates the calibration. Editing a third check anchor does not invalidate the selected pair.

The bundled CSVs are snapshots of the root `nodes.csv`, `edges.csv`, and `locations.csv`. After teammate updates, refresh their copies in `madmaps_flutter/assets/floor1/` together and rerun the asset/import tests. The loader validates references and imports floor 1 only. Other-floor rooms are omitted from the current destination picker.

## Guidance behavior

Dijkstra respects imported costs and directionality. The user's position is projected to a corridor within 3 meters; room approach spurs are excluded from automatic start snapping. Rooms without an assigned route node show **Not mapped yet**. No corridor match or disconnected target produces an explicit no-route state.

The compass points to the next waypoint, with left/right instructions for bends of at least 30 degrees. Waypoints advance within 1.5 meters or when forward progress onto the next segment is detected. More than 3 meters off the route for 2 seconds triggers recalculation. Arrival means an estimated position within 1.5 meters of the destination approach, not confirmed entry into the room.

Guidance pauses when tracking/localization is unavailable. Same-map anchor handoffs retain the destination and reassess progress; changing maps clears the destination. A lost fix does not display a live map position. Floor transitions are unsupported.

## Verification

Automated coverage includes CSV imports, shortest paths, directionality, start projection, invalid/unreachable destinations, calibration/inverse transforms, legacy storage, turn instructions, guidance progression and loss, rerouting, image taps under zoom/letterboxing, and setup persistence.

The first-floor graph has been visually overlaid on the corrected image. Verify the south lobby/stair area and destination approaches on site. Physical acceptance still requires calibrating two anchors, checking a third landmark, and walking a first-floor route with multiple turns and an anchor handoff. Serverpod/Dart MCP tools were unavailable during implementation, so app hot restart, live driver navigation, and runner/app log inspection could not be performed in this session.
