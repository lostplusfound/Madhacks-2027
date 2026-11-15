# Testing

## Latest recorded verification

On November 14, 2026, after map-first navigation, interactive map controls,
compact AR rendering, route recovery, and automatic localization/heading-follow
changes: **80 Flutter tests passed**. `dart analyze` reported no errors or warnings
(informational notices remain), changed Dart sources were formatted, and
`flutter build apk --debug` succeeded. The APK is
`madmaps_flutter/build/app/outputs/flutter-apk/app-debug.apk`.

These checks are local-only. They neither require nor validate Serverpod,
PostgreSQL, a backend round trip, Cloud Anchor authorization, or physical accuracy.
Earlier successful hosting was confirmed by the user on Pixel 6a. Positive
hands-on feedback does not replace the physical acceptance checklist below.
Older result counts in the AR/setup history are snapshots, not current totals.

## Commands

```powershell
# Repository root
dart analyze
# Check formatting without rewriting unrelated files.
dart format --output=none --set-exit-if-changed madmaps_flutter/lib madmaps_flutter/test
cd madmaps_flutter
flutter test
flutter build apk --debug
```

Use Java 17 for the pinned AR plugin; see [AR configuration](AR_PROTOTYPE.md).
Native plugin changes need a full rebuild/relaunch. Dart controller/lifecycle
changes need at least an app restart to recreate state; hot reload alone can
retain an old controller. Connected app control should follow `AGENTS.md`: use
Serverpod MCP for restart/logs and DTD, then Dart MCP for driver navigation when
available. These tools were unavailable for the recorded implementation checks;
no live driver run, install, or physical verification is implied.

## Automated coverage

| Area | Scenarios covered |
| --- | --- |
| Localization math and persistence | Rotated/translated alignment, gravity/height handling, horizontal distance, calibration/inverse transforms, legacy local records |
| Cloud operations | Callback races, individual/all failures, timeout, duplicate/expired IDs, cancellation, stale callbacks, retained-anchor cleanup, draft-host retry |
| Automatic localization | 20m/20s intervals, failures retaining moving AR estimates, retries during lost/blocked camera samples, interval resets, one pending attempt, discovery retry, background reacquisition, explicit cancellation |
| Handoffs and mapping | Candidate broadening, stability validation, large corrections and blending, placement suspension/advisories, disposal of late candidates |
| Graph and guidance | CSV references, shortest paths/costs, directionality, all mapped approach pairs, University exit, distant reachable starts, disconnected alternatives, invalid/unreachable targets |
| Progress and recovery | Turn cues, parallel offsets/legs, missed samples, reverse walking, off-route hysteresis, retained routes/rejoin distance, alternate routes, tracking pause/recovery, actual-proximity arrival |
| Map and UI | Pixel transforms under zoom/letterboxing, rotation/pan/zoom marker alignment, clustered place selection, Navigate cards, heading wraparound/centering, pinch preserving follow, browsing/recenter/reset controls, large text, Cancel, setup toggle persistence |
| Compact camera | Camera-widget/session identity and pending search retained across compact/expanded layout, scrollable permission prompts; actual native frame continuity still needs device verification |

The synthetic fixtures and fake anchors used in tests do not resolve physically.
Shared/backend domain types, revision enforcement across a repository service,
publication review, accessibility rules, and multi-floor transitions remain
future work; current local routing deliberately uses a draft floor graph.

## Physical Android checklist

Use an ARCore-compatible phone and configure keyless authorization without
committing credentials. Record device/OS, plugin version, signing/build identity,
anchor expiry, network/lighting conditions, and measured position/heading error.

1. Verify permission grant/denial, session startup, horizontal/wall anchor hosting,
   saving, full app restart, and resolving each saved anchor in a fresh session.
2. Associate the map with floor 1, calibrate two separated anchors, and compare a
   third placed landmark. Recheck height-independent distance and heading.
3. Begin navigation from a place card and the searchable picker. Check dot/route
   alignment, next turn, distance, ETA, entrance proximity, and Cancel.
4. Pan, rotate, pinch, select clustered places, reset rotation, use Overview and
   Recenter. Confirm heading-follow keeps the dot centered while walking/turning,
   including heading wraparound and nearly vertical camera poses.
5. Start while away from a mapped segment, leave an established route, miss a
   turn, and walk back. Confirm the estimated return connector stays visible and
   ordinary turn instructions resume within the corridor tolerance. Inspect any
   connector against real walls; it is not a verified access path.
6. Walk through repeated failed cloud refreshes while AR tracking remains valid.
   The estimated position should continue moving and turns should remain visible;
   retries should use the normal interval without manual intervention.
7. Deliberately lose AR tracking. The dot, live directions, and ETA must disappear
   or pause, with an automatic-relocalization notice. Restore tracking and verify
   recovery without invented movement or a stale-session pose.
8. Background/resume during navigation and a pending search. Confirm same-map trip
   recovery, late-result rejection, automatic retry after failure, and Cancel
   search suppressing retries until Locate/reopening.
9. Resolve an anchor while AR is compact. Expand/collapse during a pending resolve
   and while walking. Check advancing native frame timestamps, stable session
   identity, and successful resolution in both sizes; a passing widget test does
   not establish this behavior on Android hardware.
10. Verify both Cafe restrooms, both auditorium restrooms, the elevator bank, and
    Main Stairs approaches. Check the south lobby/stair graph on site; none of
    these draft connections establishes accessibility or another-floor routing.
11. Disable/re-enable floor association and confirm legacy AR layout and saved
    calibration/overrides survive. Check anchor handoffs and adding an anchor
    after relocalization, including expired IDs and interrupted network service.

Measure outbound/return position and heading errors, correction jumps, and any
incorrect map match. Long-term 365-day authorization/expiry behavior and iOS
interoperability need separate verification. Browser tests cannot validate AR.

## Optional backend tests

The generated Serverpod stack is separate from this local integration. Run
`dart test` in `madmaps_server` only for backend changes. Follow `AGENTS.md` for
runner and migration tooling and [setup history](SETUP_STATUS.md) for recorded
platform blockers. Generated greeting tests are framework smoke tests, not proof
of map persistence or shared domain integration.
