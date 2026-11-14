# MadMaps

The Android localization prototype supports local named maps, automatic Cloud
Anchor discovery across saved maps/floors, horizontal and vertical placement,
nearby-anchor handoffs, camera arrow guidance, and a bird's-eye mini-map.
Regular use and navigation refresh after 20 meters traveled or 20 seconds from
the previous attempt's completion. Failed refreshes retain the old fix and retry;
adding an anchor pauses refreshes, and mapping quality warnings are advisory.
See [AR prototype setup and usage](docs/AR_PROTOTYPE.md).

On November 14, 2026, the user reported that the updated flow works well in
hands-on use, following earlier confirmed hosting on Pixel 6a. All 36 Flutter
tests pass. Measured position/heading accuracy and the full physical acceptance
checklist remain outstanding; this is not a measured accuracy claim.

Indoor navigation for MadHacks: Flutter, Serverpod/PostgreSQL, and the third-party AR package `ar_flutter_plugin_plus: 1.1.3`.

The Flutter app includes an Android AR localization prototype with local map persistence. The backend remains a generated framework starter. Corridor routing, backend map persistence, AI processing, and shared domain types remain future work.

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

From repository root in PowerShell:

```powershell
dart pub global activate serverpod_cli 4.1.2
flutter pub get
# Fresh clone only: do not overwrite an existing local password file.
Copy-Item madmaps_server/config/passwords.yaml.example madmaps_server/config/passwords.yaml
dart analyze
dart format --output=none --set-exit-if-changed madmaps_flutter/lib madmaps_client/lib madmaps_server/lib madmaps_server/bin
```

The CLI executable is not on PATH on the setup machine, so use its explicit global-run entry point:

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

Docker is not installed here; this alternative is untested. Start the database before attempting a backend round trip. In another terminal:

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

Read [architecture](docs/ARCHITECTURE.md), [coordinates](docs/COORDINATE_SYSTEMS.md), [24-hour plan](docs/HACKATHON_PLAN.md), [integration](docs/INTEGRATION.md), [testing](docs/TESTING.md), and [contributing](CONTRIBUTING.md). Domain contracts and domain tests are future work.
