# Maps and Swara UI integration

The integration continues the recovered local changes on
`integration/maps-swara-recovery`, based on `abd7405`. Source map handoff:
`origin/main` at `36b57cc`; UI reference: `origin/ui_swara` at `e1b36cf`.
The original unfinished source/assets were copied outside the repository to
`C:/Users/lijia/Dev/MadMaps-backup-20261114-222821` before edits.

## Maps and persistence

The Serverpod repository loads separate `morgridge-floor0` through
`morgridge-floor3` graphs and searches all loaded floors. Floor 1 retains its
existing graph IDs, geometry, extra amenity approaches, image and calibration.
Basement and floors 2?3 use the new handoff images; all room outlines match the
handoff JSON. There are 64 selectable room polygons. Unsupported handoff node
kinds `stairs_landing` and `elevator_landing` are represented by the existing
Serverpod `landmark` kind; coordinates and IDs are preserved. These are browsing
landmarks, not cross-floor routing connections.

`bin/seed_all_floors.dart` seeds missing graphs and verifies existing graphs
without replacing edits. The normal Windows launcher runs it. A mismatch stops
startup with an explicit message; resolve the conflicting data intentionally,
without deleting database clusters or forcing seed replacement. No schema or
migration changes are required.

Floor 1 supports real AR navigation. Other floors support browsing, search,
bookmarks and room details with a View on map action. They explicitly state
that navigation is available on Floor 1 only. Browsing another floor preserves
the pending Floor 1 trip and navigator; Return to navigation restores it.

## UI changes

Swara's updated room highlighting, map help/overview controls, animated browse
panel, saved-place details/bookmark controls and suggestions, arrival feedback,
and card-based Profile preferences are adapted to the working visitor shell.
The units selector controls actual guidance. Existing localization, TTS,
calibration, backend search, and session identity remain in place. Mock location,
photo check-in, simulated cross-floor arrival, opening hours and pretend report
submission are not enabled. System reduced-animation preferences apply to the
new browse-panel animation.

## Validation

Automated coverage includes geometry validation, transformed room/marker taps,
floor browsing with a retained trip, all-floor repository loading/search, offline
cached results, missing-floor retry, and the existing AR/routing regressions.
Physical phone checks remain necessary for native camera/anchor behavior.
Serverpod/Dart MCP tools were unavailable in this session, so the documented
local CLI fallback was used. See LOCAL_WINDOWS_RUNTIME.md for crash evidence
and the build memory limits.

Recorded November 14, 2026: **102 Flutter tests and 27 backend tests passed**.
`dart analyze` found no errors or warnings (62 informational notices).
`dart format` and `git diff --check` completed. The Android debug APK built
successfully with the reduced Gradle limits. The build Gradle daemon's peak
resident working set was 1,165 MB; this is not total system/build memory.
All four live graphs were read and searched successfully, and the launcher
verified 85 destinations in total. No new Windows bugcheck events were recorded
during validation; this observation does not prove the driver fault is resolved.
The backend launcher remains running; launch/restart the phone app manually to
load the new assets and repository initialization.
