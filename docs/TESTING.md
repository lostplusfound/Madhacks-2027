# Testing

## Initialization

Run package dependency installation, analysis, generated Flutter tests, Serverpod generation, and generated backend tests. README.md gives commands; SETUP_STATUS.md records actual results. Database-dependent tests require the test database configuration, not just package installation. Do not treat generated starter tests as domain coverage.

## Future automated acceptance tests

Create a clearly synthetic floor with three rooms, two corridor intersections, a destination doorway, multiple edges, one fake Cloud Anchor record, and known calibration. Never imply its anchor resolves physically. Add a mock walk sequence.

Test pixel/meter round trips; anchor-relative transforms; valid node and room references; graph connectivity; route correctness and distance; unreachable destinations; map/anchor revision mismatch; rejection of invalid graph IDs; and exclusion of unverified connections. No such domain tests or fixtures are implemented in this initialization.

## Physical Android checklist

Use an ARCore-compatible phone. Verify permissions, session start, anchor hosting, saving its ID, full app restart, resolving the saved ID, anchor-relative camera pose, calibrated alignment, horizontal distance, and tracking loss/recovery. Record device, plugin version, anchor expiry, network conditions, and observed error. Fresh-session persistence is unverified until this passes.

Cloud credentials must follow the plugin/Google configuration instructions and stay outside tracked files. Verify iOS separately; it is not an MVP gate. No physical AR test can be replaced by a browser or unit test.
