# Setup verification — November 14, 2026

## Current local integration status

Current branch `integration/luray-maps-search` combines the visitor UI and AR
navigation with Luray's backend through `ba2537c`. The visitor shell requires a
Serverpod graph load; localization, calibration and routing remain on-device.

Verified on November 14, 2026:

- 94 Flutter tests and all 24 backend tests, including database endpoint tests, passed.
- Static analysis had no errors/warnings; informational notices remain.
- The Android debug APK built with Java 17 and AR plugin 1.1.3.
- Portable PostgreSQL 16.16 runs on this Windows ARM64 laptop: development on
  127.0.0.1:8090 and tests on 127.0.0.1:9090. Docker is not required.
- The runner started using the project-local legacy VM-service workaround and
  applied the latest migration. Floor 1 was seeded and verified repeatedly:
  20 nodes, 19 edges, 13 destinations, no wall polygons.
- A generated client read the graph and searched room 1524 through the laptop's
  LAN address, `http://10.138.33.209:8080/`.

The launcher now owns startup, log following and shutdown; Ctrl+C stops the runner
and both databases. PostgreSQL startup uses pg_ctl directly and waits for its exit
code rather than inherited pipe EOF. The direct startup helper was verified after
this fix; physical phone acceptance and a full post-fix Ctrl+C acceptance run
remain for the user. No latest physical AR accuracy result is implied.

See [Windows startup](LOCAL_WINDOWS_RUNTIME.md), [backend integration](LURAY_INTEGRATION.md),
[AR setup](AR_PROTOTYPE.md) and [testing](TESTING.md). The sections below preserve
initial scaffold history; their failures and missing features are historical,
not the current runtime status.

## Original scaffold implementation

Root-level madmaps_flutter, madmaps_server, and madmaps_client packages, generated using Serverpod 4.1.2. Flutter 3.50.0 stable and Dart 3.14.0 on Windows ARM64. PostgreSQL configuration and initial generated migration are present. Optional auth, Redis, website, and hosted webapp features were disabled.

Selected third-party AR package: ar_flutter_plugin_plus exactly 1.1.3. Dependencies resolved and the workspace lockfile is included. No AR application code or Cloud Anchor credentials were added. All domain contracts remain proposed, unimplemented, and open to team revision.

## Initial setup results

| Check | Result |
| --- | --- |
| CLI activation | Passed, serverpod_cli 4.1.2 |
| Project generator | Wrote packages, platform files, protocol, and migration; returned failure during Flutter platform setup due to symlink support |
| Flutter dependency resolution | Resolved pinned AR dependency; post-resolution plugin setup reported Windows Developer Mode/symlink requirement |
| Serverpod generation from final root layout | Passed |
| Workspace dart analyze | Exit 0, no errors; two informational material.dart deprecation warnings in generated Flutter sources |
| Dart formatting check | Passed, 15 source files, zero changes |
| Flutter test | No tests found; generated widget_test.dart contains only an empty main. Not a test pass |
| Backend dart test | Failed before endpoint assertions: embedded PostgreSQL unavailable on this platform |
| Runner startup | Server compiled, but startup failed: missing dart_runtime_service_vm.dart.snapshot / unreachable VM service. Runner also logged a Windows link registration warning |
| Android debug build | Failed: pinned AR plugin requires a Java 17 toolchain; only JDK 21 was discovered |
| Live client/server round trip | Blocked; not verified |
| Physical Android / Cloud Anchors | Not tested; no physical device connected |

## Follow-up steps recorded at initial setup

1. Enable Windows Developer Mode, then rerun flutter pub get. No OS setting was changed by this setup.
2. Install a JDK 17 toolchain discoverable by Gradle (or configure its local installation path outside tracked files), then rerun the APK build. The plugin also emits a Kotlin Gradle Plugin compatibility warning; further build compatibility is unverified.
3. Provide external PostgreSQL/Docker and follow README configuration instructions, or use a platform supported by Serverpod embedded PostgreSQL. Docker is not installed here.
4. Repair/update the local Flutter/Dart installation's missing VM service snapshot before using the runner. As an alternative after database setup, try `dart run bin/main.dart` from madmaps_server; this fallback has not been verified.
5. Rerun backend tests and perform the greeting UI round trip before declaring the full stack operational.

Generated Linux CI workflows were adjusted to use the recorded Flutter version and example-only test passwords. CI has not been run. No deployment workflow or cloud resources are configured. No domain tests, mocks, map fixtures, or Python tools are implemented.
