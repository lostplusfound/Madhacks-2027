# Setup verification — November 14, 2026

## Current local integration status

This file preserves the **initial scaffold setup history** below. It is not the
current feature or Android-build status. Later implementation added local AR map
storage, Cloud Anchor discovery/handoffs, floor calibration, graph routing,
interactive map-first navigation, compact AR, automatic recovery, and heading-follow.

Latest recorded checks on November 14, 2026: **80 Flutter tests passed**, analysis
reported no errors/warnings (informational notices remain), and the Android debug
APK built with the configured Java 17 toolchain. The local-only AR/map flow needs
no Serverpod backend or database. Earlier hosting was confirmed on Pixel 6a;
physical navigation accuracy and the latest compact/localization acceptance
checks remain outstanding. Backend/runner blockers below were recorded at initial
setup and were not revalidated by these Flutter checks.

See [README](../README.md), [AR setup](AR_PROTOTYPE.md),
[floor navigation](FLOOR_NAVIGATION.md), and [testing](TESTING.md).

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
