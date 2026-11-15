# MadMaps

MadMaps currently runs as a **local-only Android indoor-navigation prototype**.
Named AR maps, saved anchor metadata, floor calibration, and map overrides stay
on the phone. Cloud Anchor hosting/resolution uses Google directly; these flows
do not require the Serverpod backend, PostgreSQL, or a backend round trip.

Floor-associated maps provide a full-screen floor plan, live position/heading,
highlighted remaining route, turn instructions, distance, estimated walking time
and arrival time, Cancel, and an expandable AR camera. The map supports pan,
pinch, rotation, tappable places, clustered markers, and Navigate cards.
Navigation automatically keeps the dot centered and rotates the map to the phone's
horizontal camera heading. Disable **Associate this AR map with floor 1** to
restore the legacy AR-first layout without deleting calibration or overrides.
See [floor navigation and controls](docs/FLOOR_NAVIGATION.md).

Localization refreshes after **20 meters traveled or 20 seconds** from the previous
attempt's completion. Failed cloud refreshes retain alignment and continue
estimated AR movement. Tracking loss hides the dot and pauses directions/ETA;
automatic retries continue, and background/resume restarts discovery. Initial
searches cover all live saved anchors in batches of at most 20. Off-route and
distant-start guidance use estimated connectors back to reachable hallway routes.
See [AR setup and recovery](docs/AR_PROTOTYPE.md).

Latest recorded verification on November 14, 2026: **80 Flutter tests passed**,
`dart analyze` reported no errors or warnings (informational notices remain), and
the Android debug APK built successfully. Earlier anchor hosting was confirmed
on Pixel 6a. The user has reported positive hands-on feedback, but measured
position/heading accuracy, compact-camera localization, and the latest physical
acceptance checklist remain outstanding. All floor-1 graph geometry and the six
new amenity approaches remain draft.

Indoor navigation for MadHacks: Flutter, Serverpod/PostgreSQL, and the third-party AR package `ar_flutter_plugin_plus: 1.1.3`.

The Flutter app includes an Android AR localization prototype and first-floor graph routing with local persistence. The backend remains a generated framework starter. Backend map persistence, AI processing, and shared domain types remain future work.

**All domain contracts are proposals, not set in stone.** Revise them together as features are implemented. See [the contract discussion draft](docs/CONTRACTS.md).

```text
madmaps_flutter/     Flutter app and platform scaffolds
madmaps_server/      Serverpod server, greeting endpoint, database configuration
madmaps_client/      Generated typed client
pubspec.yaml        Dart workspace
docs/               Architecture, contracts, coordinates, schedule and validation
docs/roles/         Independent teammate handoffs
```

## Setup and commands

Tools used: Flutter 3.50.0, Dart 3.14.0, Serverpod CLI/packages 4.1.2. See [setup results and blockers](docs/SETUP_STATUS.md). Android is the initial AR target. The web greeting example cannot validate AR.

For the local Android prototype, configure keyless Cloud Anchor authorization
using the [AR guide](docs/AR_PROTOTYPE.md#configure-and-run), then run:

```powershell
# Repository root
dart analyze
# Flutter package
cd madmaps_flutter
flutter test
flutter build apk --debug
# Standalone physical Android run; no SERVER_URL is needed for the AR/map flow.
flutter run -d <android-device-id> -t lib/driver.dart
```

The debug APK is `madmaps_flutter/build/app/outputs/flutter-apk/app-debug.apk`.
Fully stop and rebuild/relaunch after native plugin changes; hot reload or Dart
hot restart cannot replace Android code. See [testing](docs/TESTING.md) for the
physical checklist. Use Serverpod/Dart MCP tooling for connected app control when
available, as described in `AGENTS.md`.

The commands below concern the optional generated backend/greeting example.
From repository root in PowerShell:

```powershell
dart pub global activate serverpod_cli 4.1.2
flutter pub get
# Fresh clone only: do not overwrite an existing local password file.
Copy-Item madmaps_server/config/passwords.yaml.example madmaps_server/config/passwords.yaml
dart analyze
dart format --output=none --set-exit-if-changed madmaps_flutter/lib madmaps_client/lib madmaps_server/lib madmaps_server/bin
```

Use Serverpod MCP for generation/migrations, restarts, and logs as specified in AGENTS.md. Generation is normally handled by the runner. The following CLI commands are fallbacks when MCP is unavailable or the runner cannot start; the initial setup machine required an explicit global-run entry point:

```powershell
cd madmaps_server
dart pub global run serverpod_cli:serverpod_cli --no-analytics generate
dart test
dart pub global run serverpod_cli:serverpod_cli --no-analytics runner start
```

The runner normally manages PostgreSQL through database.dataPath. Embedded PostgreSQL is unavailable on this Windows ARM64 machine. For external PostgreSQL, remove dataPath from development.yaml and test.yaml, configure database host/port/name/user, and match passwords.yaml to those databases. For Docker use development port 8090 and test port 9090:

```powershell
# In madmaps_server; match your ignored passwords.yaml values.
$env:MADMAPS_DATABASE_PASSWORD = 'your-local-development-password'
$env:MADMAPS_TEST_DATABASE_PASSWORD = 'your-local-test-password'
docker compose up -d postgres postgres_test
dart test
dart pub global run serverpod_cli:serverpod_cli --no-analytics runner start
```

Initial setup recorded Docker unavailable; this alternative was not verified. Start the database before attempting a backend round trip. In another terminal:

```powershell
cd madmaps_flutter
flutter test
flutter run -d chrome --dart-define=SERVER_URL=http://localhost:8080/
# Physical Android: replace with your computer's LAN address.
flutter run --dart-define=SERVER_URL=http://192.168.1.100:8080/
flutter build apk --debug
```

Use flutter devices to select a phone. Configure keyless Cloud Anchor authorization as described in the AR prototype guide before hosting or resolving anchors. Anchor saving is confirmed on Pixel 6a; the remaining physical acceptance checks are pending. No Python tooling or map validator exists yet.

## Team handoffs

| Role | Document | First task |
| --- | --- | --- |
| AR | [Localization](docs/roles/01_AR_LOCALIZATION.md) | Host an anchor; resolve its saved ID after app restart |
| AI | [Map generation](docs/roles/02_AI_MAP_GENERATION.md) | Agree schema and manually author a small draft |
| Backend | [Serverpod](docs/roles/03_SERVERPOD_BACKEND.md) | Run the greeting endpoint and demonstrate a client response |
| Navigation | [Flutter navigation](docs/roles/04_FLUTTER_NAVIGATION.md) | Agree shared types, then create a synthetic floor and mock walk |

Read [architecture](docs/ARCHITECTURE.md), [coordinates](docs/COORDINATE_SYSTEMS.md), [24-hour plan](docs/HACKATHON_PLAN.md), [integration](docs/INTEGRATION.md), [testing](docs/TESTING.md), and [contributing](CONTRIBUTING.md). Shared/backend domain contracts remain proposals; local routing, calibration, localization, and map-interaction tests are implemented.
