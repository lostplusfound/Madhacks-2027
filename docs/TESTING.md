# Testing

## Initialization

Run package dependency installation, analysis, generated Flutter tests, Serverpod generation, and generated backend tests. README.md gives commands; SETUP_STATUS.md records actual results. Database-dependent tests require the test database configuration, not just package installation. Do not treat generated starter tests as domain coverage.

## AR prototype checks

The localization prototype has 36 passing Flutter tests covering transforms,
horizontal distances, persistence, map UI, callback races, concurrent discovery,
cancellation, reference handoffs, and tracking/lifecycle recovery. Scheduling tests
verify repeated 20m/20s retries after attempt completion, including authorization,
quota, timeout, and network failures. Mapping tests cover advisory quality checks
and rejecting late handoffs during placement or candidate validation. Large stable
position/heading corrections are accepted and blended automatically.

Run `flutter test --no-pub` in `madmaps_flutter`; run `dart analyze` and format
changed Dart sources from the repository root. See
[AR prototype verification](AR_PROTOTYPE.md#verification) for setup and results.

On November 14, 2026, the user reported that the updated flow works well in
hands-on use, following confirmed anchor saving on Pixel 6a. This qualitative
report does not replace measured position/heading errors or the physical checklist
below. Native plugin changes were compiled successfully in an Android debug build;
subsequent scheduling/UI changes are Dart-only. Restart the app to recreate the
controller after these changes. Do not rebuild, install, or launch the app without
an explicit user request.

## Future automated acceptance tests

Create a clearly synthetic floor with three rooms, two corridor intersections, a destination doorway, multiple edges, one fake Cloud Anchor record, and known calibration. Never imply its anchor resolves physically. Add a mock walk sequence.

Test pixel/meter round trips; anchor-relative transforms; valid node and room references; graph connectivity; route correctness and distance; unreachable destinations; map/anchor revision mismatch; rejection of invalid graph IDs; and exclusion of unverified connections. Those routing, image-calibration, and publication fixtures remain future work.

## Physical Android checklist

Use an ARCore-compatible phone. Verify permissions, session start, anchor hosting, saving its ID, full app restart, resolving the saved ID, anchor-relative camera pose, calibrated alignment, horizontal distance, and tracking loss/recovery. Record device, plugin version, anchor expiry, network conditions, and observed error. Fresh-session persistence is unverified until this passes.

Cloud credentials must follow the plugin/Google configuration instructions and stay outside tracked files. Verify iOS separately; it is not an MVP gate. No physical AR test can be replaced by a browser or unit test.
