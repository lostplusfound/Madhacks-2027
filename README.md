# MadMaps

MadMaps is an **Android indoor-navigation prototype with Serverpod map and search reads**.
See [backend integration and setup](docs/LURAY_INTEGRATION.md) and
[one-command Windows startup](docs/LOCAL_WINDOWS_RUNTIME.md).
Named AR maps, saved anchor metadata, floor calibration, and map overrides stay
on the phone. Cloud Anchor hosting/resolution uses Google directly. The visitor shell requires
a successful Serverpod map load; already-loaded maps remain usable in memory.

The visitor UI now provides Home search, Map, Saved and Profile tabs, using real
floor-1 navigation. See [Swara UI integration and feature differences](docs/SWARA_UI_INTEGRATION.md).
Home includes available backend category shortcuts; Saved supports bookmarks and aliases;
Profile offers units, high contrast, spoken directions, and **Manage AR maps and
calibration**. Set up two anchors and Floor 1 calibration there, return to Map,
then select **Find my location**. A missing-setup prompt retains the destination.
Tab changes retain the active session; Cancel clears the trip, and Back closes it.
Only Floor 1 is routable. Multi-floor/step-free routes, text-based localization,
opening hours, and report submission remain unsupported.

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

Latest recorded verification on November 14, 2026: **94 Flutter tests and 24 backend tests passed**,
`dart analyze` reported no errors or warnings (informational notices remain), and
the Android debug APK built successfully. Earlier anchor hosting was confirmed
on Pixel 6a. The user has reported positive hands-on feedback, but measured
position/heading accuracy, compact-camera localization, and the latest physical
acceptance checklist remain outstanding. All floor-1 graph geometry and the six
new amenity approaches remain draft.

Indoor navigation for MadHacks: Flutter, Serverpod/PostgreSQL, and the third-party AR package `ar_flutter_plugin_plus: 1.1.3`.

The Flutter app includes an Android AR localization prototype and first-floor graph routing with local persistence. The backend now includes Luray's graph persistence, destination search, categories, authenticated editing and reports. The visitor frontend integrates map/search reads; reporting UI and AI processing remain future work.

**All domain contracts are proposals, not set in stone.** Revise them together as features are implemented. See [the contract discussion draft](docs/CONTRACTS.md).

```text
madmaps_flutter/     Flutter app and platform scaffolds
madmaps_server/      Serverpod graph/search/report endpoints, database configuration
madmaps_client/      Generated typed client
pubspec.yaml        Dart workspace
docs/               Architecture, contracts, coordinates, schedule and validation
docs/roles/         Independent teammate handoffs
```

## Setup and commands

Tools used: Flutter 3.50.0, Dart 3.14.0, Serverpod CLI/packages 4.1.2. See [setup results and blockers](docs/SETUP_STATUS.md). Android is the initial AR target. The web greeting example cannot validate AR.

For day-to-day development on this Windows laptop, run from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start-local-backend.ps1
```

Keep this terminal open: it starts development/test PostgreSQL, starts Serverpod
without Flutter auto-launch, seeds/verifies Floor 1, and follows backend logs.
**Ctrl+C stops the runner and both databases.** Launch Flutter yourself in another
terminal after configuring [Cloud Anchor authorization](docs/AR_PROTOTYPE.md#configure-and-run):

```powershell
cd madmaps_flutter
flutter devices
flutter run -d <android-device-id> -t lib/driver.dart
```

The phone defaults to `http://10.138.33.209:8080/`. Both devices must be on a
network that permits device-to-device traffic. If the laptop IP changes, use
`--dart-define=SERVER_URL=http://<new-IP>:8080/` and fully restart the app.
See [Windows startup and troubleshooting](docs/LOCAL_WINDOWS_RUNTIME.md).

The debug APK is `madmaps_flutter/build/app/outputs/flutter-apk/app-debug.apk`.
Fully stop and rebuild/relaunch after native plugin changes; hot reload or Dart
hot restart cannot replace Android code. See [testing](docs/TESTING.md) for the
physical checklist. Use Serverpod/Dart MCP tooling for connected app control when
available, as described in `AGENTS.md`.

For a fresh clone, activate Serverpod CLI 4.1.2, resolve dependencies, and create
`madmaps_server/config/passwords.yaml` from its example only if it does not already
exist. Preserve existing database passwords; the launcher reuses persistent
clusters. See [backend integration](docs/LURAY_INTEGRATION.md) for auth secrets,
map IDs and seeding rules. Credentials and local tooling/data stay ignored.

For checks, keep the backend script running, then use separate terminals:

```powershell
# Repository root
dart analyze
# In madmaps_flutter
flutter test
flutter build apk --debug
# In madmaps_server
dart test
```

Use Serverpod MCP for migrations, restarts and logs when available, as described
in `AGENTS.md`. The runner generates protocol code and applies pending migrations
on startup. Never edit generated server/client code manually. On this Windows
SDK, use the project launcher rather than unmodified `serverpod runner start`;
it prepares the local VM-service workaround. Docker remains an alternative,
using PostgreSQL ports 8090 and 9090, but is not installed or verified here.

Earlier anchor hosting was confirmed on Pixel 6a. Measured AR accuracy and the
latest physical acceptance checklist remain outstanding; see [testing](docs/TESTING.md).

## Team handoffs

| Role | Document | First task |
| --- | --- | --- |
| AR | [Localization](docs/roles/01_AR_LOCALIZATION.md) | Host an anchor; resolve its saved ID after app restart |
| AI | [Map generation](docs/roles/02_AI_MAP_GENERATION.md) | Agree schema and manually author a small draft |
| Backend | [Serverpod](docs/roles/03_SERVERPOD_BACKEND.md) | Run the greeting endpoint and demonstrate a client response |
| Navigation | [Flutter navigation](docs/roles/04_FLUTTER_NAVIGATION.md) | Agree shared types, then create a synthetic floor and mock walk |

Read [architecture](docs/ARCHITECTURE.md), [coordinates](docs/COORDINATE_SYSTEMS.md), [24-hour plan](docs/HACKATHON_PLAN.md), [integration](docs/INTEGRATION.md), [testing](docs/TESTING.md), and [contributing](CONTRIBUTING.md). Shared/backend domain contracts remain proposals; local routing, calibration, localization, and map-interaction tests are implemented.
