# First-floor navigation

Current behavior: [all-floor routing and shared AR capture](ALL_FLOOR_NAVIGATION.md). Floor-1-only statements below describe the earlier implementation.

## Current integration

Floor 1 combines the corrected 1632 by 1056 Morgridge Hall image, bundled CSV
routing graph, saved AR map poses, and local calibration/overrides. It runs
without Serverpod domain endpoints or a database. Only floor 1 is routable.
Graph edges, amenity entrances, and estimated return connectors are draft;
the graph does not describe walls, hallway widths, accessibility, or opening hours.

## Setup and legacy toggle

1. Open **Profile > Manage AR maps and calibration**. Open/create an AR map
   and save two identifiable anchors at least 2 meters apart. Wider separation generally reduces sensitivity to placement error.
2. Open **Floor 1 setup** from the map list's overflow menu or the session's
   edit-location icon. Enable **Associate this AR map with floor 1**.
3. Select each anchor and tap its physical position on the plan. Pinch/pan to
   place precisely, then select exactly two **Calibrate** chips.
4. The calibration transforms saved horizontal AR X/Z meters into image pixels;
   anchor height is ignored and no compass-north setting is required. Place a
   third anchor without selecting its calibration chip to inspect check error.
5. Return to Map and select **Find my location**, or select a destination in
   Home/Saved. A single calibrated map is searched directly; multiple calibrated
   maps use catalogue discovery. Opening an associated map from Mapping tools
   also searches its live anchors. Use **Locate** or the location icon to retry immediately. Pick a destination through
   **Rooms**, **Choose destination**, or a map marker's **Navigate** card.

Disable **Associate this AR map with floor 1** to restore the legacy AR-first
layout, direct-anchor guidance, and mini-map. This retains saved calibration,
anchor placements, and overrides. Re-enabling association restores the floor UI.
Direct anchor guidance is straight-line and ignores walls. **Navigate via hallways**
in the Anchors menu requires an explicit anchor-to-approach-node link in setup.

## Visitor tabs and saved places

Home provides search and bathroom/exit shortcuts. Saved bookmarks and aliases
stay on this phone; hold a saved row to rename it. Recent/frequent places reflect
actual arrivals, with no seeded visit history. Profile offers units, high contrast,
spoken directions, and map management. Missing calibration opens a setup sheet
without discarding the requested destination.

Changing tabs retains the navigation session; the trip summary returns to Map.
Cancel clears the trip and keeps localization active. Back from the active session
closes it and clears the trip. Mapping tools remain available in the session toolbar.
Only Floor 1 is routable; step-free alternatives and opening hours are not supplied.
See [UI integration decisions](SWARA_UI_INTEGRATION.md).

## Navigation screen and map controls

The floor plan is the main view. A blue dot/heading shows the unsnapped live
position; the remaining route is blue, traveled route is muted, and the destination
has a red marker. The turn banner shows the next maneuver and distance. The bottom
card shows destination, remaining distance (meters by default; feet via Profile),
estimated duration and arrival clock time, and **Cancel**. Estimates use a fixed walking speed of **1.2 m/s**; short
routes display **Less than 1 min**. Cancel clears the trip while localization
continues. Arrival means proximity to the approach/entrance, not the room interior.

| Control | Behavior |
| --- | --- |
| Start navigation | Enable heading-follow: center the dot and point the horizontal camera heading up |
| Pinch | Change zoom while retaining follow mode |
| Pan / two-finger rotation | Enter free browsing |
| Recenter | Restore heading-follow during navigation; position-follow otherwise |
| Heading follow | Explicitly enable centered pose-based rotation |
| Reset rotation | Select image-up position-follow |
| Map overview | Enter free browsing and fit the route plus current position, or the mapped building area |
| Place marker | Open a Floor 1 card with Navigate; overlapping places open a chooser |
| Expand/collapse AR | Switch camera viewport size while retaining the native view/session |
| Toolbar mapping menu | Open Anchors or Add anchor |

Heading changes blend over 220 ms using the short arc across angle wraparound.
A nearly vertical camera retains the previous map heading. Place markers and
labels remain upright; their tap targets do not shrink with zoom. Place cards
currently contain a name, floor, and Navigate button. Opening/closing a card does
not cancel the active trip; future details such as closing times are not supplied.
The image remains the map background; no room/wall polygons were added.

## Routing, off-route recovery, and distant starts

Dijkstra uses imported costs and directionality. Normal routing tries attachments
within **3 meters** of every walk edge, including destination and exit approaches.
The nearest attachment with a directed path wins, with route cost breaking ties.
Moving a graph node recomputes its incident edge lengths.

If a trip starts too far from a usable segment, or nearby segments cannot reach
the destination, navigation searches for the nearest reachable attachment across
the graph. Directed edges also consider valid endpoint entry. Guidance starts
with **Return to route**, a directional arrow, distance, and an orange dashed
connector. Return distance contributes to the remaining distance and ETA. The
connector is estimated: arbitrary access to a hallway is not verified walkability.
Truly unreachable or invalid destinations still have explicit failure messages.

On an established route, segment matching favors the current leg within 3 meters,
advances through connected turns, supports reverse walking, and reassesses after
missed samples or localization corrections. Parallel walking uses a translated
forward vector instead of aiming sideways at the route centerline. A 2-meter
lookahead stops at the next turn; bends of at least 30 degrees produce turn cues.

More than **4 meters** off-route starts a **2-second** grace timer. Forward guidance
continues during that grace period. Recalculation replaces the route only on
success. If no walkway is close enough, the existing trip remains visible and
guidance points back to its matched segment. Recovery holds that segment to avoid
jumping between parallel legs, while allowing localization corrections to reassess
it. Rejoining within **3 meters** resumes ordinary turns. A reachable alternative
route can replace recovery guidance. Arrival requires actual position within
**1.5 meters** of the final approach; projection alone cannot trigger arrival.

`NavigationTuning` centralizes thresholds. `GuidanceState` exposes maneuver,
maneuver distance, remaining distance, estimated duration, phase, and rejoin
point/distance. Debug `[MadMaps navigation]` messages report phase, selected edge,
attachment distance, calibration scale, progress, and failure reason.

## Localization and automatic recovery

Refresh is scheduled after **20 seconds or 20 meters**, measured from the previous
attempt's completion. Failure does not advance fix freshness. Time-based retries
run even if no valid camera sample arrives, and only one cloud operation runs at
a time. Adding anchors and background suspension pause cloud refresh work.

A failed cloud refresh retains the accepted alignment. While AR tracking is
valid, movement continues as an estimated position and turn instructions remain
visible; the estimate/retry notice appears separately. Actual tracking loss hides
the dot, freezes map orientation, pauses directions/ETA, and announces automatic
relocalization. No frozen last-known dot or invented movement is displayed.

When no reference remains, discovery automatically searches the selected map's
unexpired anchors in batches of up to 20; automatic batches have 10-second
timeouts. Failed discovery retries after 20 seconds. Background/resume clears the
old pose and restarts discovery; same-map destinations survive. A different map
clears session-local guidance. In the visitor shell, the selected floor-1
destination is reapplied using the matched map's calibration and overrides.
**Cancel search** stops automatic discovery until Locate or reopening the map.
The Mapping tools map-list **Find my location** searches saved maps;
there is no continuous floor detection or cross-floor route guidance.

## Amenities, local editing, and source data

Both Cafe restroom symbols, both auditorium restroom symbols, the elevator bank,
and Main Stairs now have draft entrance approaches and hallway connections.
Their earlier **Not mapped yet** labels came from blank `route_node_id` assignments,
not from insufficient nearby anchors. Anchors locate the user; graph assignments
connect destinations. New approaches need entrance/walkability checks on site.
Stair/elevator destinations stop at their floor-1 approaches.

Floor setup can move existing nodes and associate rooms/anchors with approach
nodes. Changes are phone-local overrides; they do not edit source CSVs. Moving or
deleting a calibration anchor invalidates its selected pair; editing a third
check anchor does not. Existing local destination links take precedence over
bundled assignments.

The root `nodes.csv`, `edges.csv`, and `locations.csv` are mirrored under
`madmaps_flutter/assets/floor1/`. Update all three source/asset copies together.
The loader validates references and imports floor 1 only. It does not establish
physical walkability or publication review. Shared/backend contracts remain
proposals rather than the current local data model.

## Compact AR implementation and verification

The compact camera has a real **140 by 170 logical-pixel viewport**, replacing a
crop of a full-screen native view. The keyed Android view and ARCore session
survive expansion/collapse. The local plugin rebinds camera textures and updates
display geometry after rendering-surface replacement. Debug logs include viewport,
surface generation, session identity, frame timestamps/tracking, and resolve
completion. Camera permission prompts scroll within the compact viewport.
Native changes require a full Android rebuild/relaunch; hot reload is insufficient.

Latest recorded checks on November 14, 2026: **88 Flutter tests passed**, analysis
reported no errors/warnings, formatting completed, and the Android debug APK
built. This verifies automated behavior and compilation, not physical AR accuracy.
Earlier hosting was confirmed on Pixel 6a; later UI feedback is qualitative.
Follow the [physical checklist](TESTING.md#physical-android-checklist) for compact
localization, multi-turn walking, anchor handoffs, recovery, heading-follow, and
all six new approaches. See [AR setup and patch history](AR_PROTOTYPE.md).
