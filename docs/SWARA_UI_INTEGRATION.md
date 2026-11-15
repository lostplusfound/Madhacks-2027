# Swara UI integration

Integrated on `integration/swara-ui` from `integration/floorplan-navigation`
(`832cb46`) and `origin/ui_swara` (`dc92422`), recorded in merge commit `6b06f84`.

## Visitor flow

Home provides destination search, bathroom/exit shortcuts, bookmarks, recently
visited places, and frequent places. Selecting a destination opens Map and starts the real AR session when a
calibrated floor-associated map exists. Otherwise a setup sheet links to existing
map creation and Floor 1 calibration, retaining the selected destination. After
setup, return to Map and select Find my location. Multiple calibrated maps are
searched using the existing Cloud Anchor discovery catalogue.

Map uses the integration's original-pixel floor image, graph, gestures, clustering,
heading-follow, and route overlay. Swara's crimson/cream theme, four-tab layout,
place cards, bottom sheets, and cross-tab trip summary surround the real navigation.
The native session stays mounted across tabs. Back from the active session closes
it and clears the trip. Cancel ends only the trip, leaving localization running.
The existing toolbar provides anchor management, calibration and AR expansion.
Profile's Mapping tools opens local map management when no visitor session is open;
during a session it directs users to that session's toolbar.

Saved bookmarks and aliases use stable FloorLocation IDs. History starts empty and
records an actual arrival once per trip, not a timer or destination selection.
Preferences, bookmarks and history use `madmaps.ui.v1`; existing anchor maps,
calibration and overrides retain their storage format/key. Units default to meters.
Large text follows the system setting. High contrast changes theme contrast, while
spoken directions announce actual maneuver/status changes and pause on background.
Speech failure leaves visible directions available. Tracking loss hides live
progress; estimated movement after cloud refresh failures remains supported.

## Conflict resolutions and unsupported features

| Source behavior/conflict | Integration decision |
| --- | --- |
| main.dart app roots | One shell, existing initialization and driver entry point retained |
| pubspec.yaml | Preserve integration assets/dependencies and AR 1.1.3; add flutter_tts |
| Root CSV add/add conflicts | Preserve integration data and the six additional amenity approaches |
| Duplicate assets/graph CSVs and graph parser | Remove; FloorGraph and existing floor assets remain authoritative |
| Mock location/route models and broad mutable demo state | Replace with preferences and a small injectable session coordinator |
| Camera permission/scan simulation | Use native camera permission and real Cloud Anchor discovery |
| Walking timer | Actual AR movement drives route progress, ETA and arrival |
| Description-based localization | Omitted; no service can derive a real pose from text |
| Floor-2 default / multi-floor simulation | Floor 1 only; no floor-transition routing |
| Quickest / step-free alternatives | Actual computed route only; accessibility is not encoded/verified |
| Blind/low-vision mode | Real spoken guidance and system text sizing; no accessibility certification claim |
| Placeholder hours and open/closed badges | Omitted; no real hours source |
| Report issue/photo flow | Omitted; original only acknowledged submission without storing/sending anything |
| Seeded saved places/history | Empty until user actions and real arrivals |
| Swara schematic map | Existing calibrated image/map renderer retained |
| material_ui imports | Existing Flutter material compatibility import retained; no additional UI dependency |

The Android manifest retains integration camera/ARCore/internet and keyless
configuration and adds the TTS service query. Flutter tooling regenerates platform
plugin registration. No Serverpod endpoint, generated client or schema changes are
needed; any future reporting/shared persistence backend must use Serverpod.

## Validation and remaining acceptance

Automated tests cover preferences persistence without modifying maps, corrupt
preferences, once-only arrival, tracking pauses, bookmark/alias flow, setup with a
pending destination, tab/session identity, system large text, and distance units.
Existing localization/routing/calibration/interaction regressions remain in place.

Physical acceptance is still required for camera permission denial/retry, saved
anchor resolution, walking/arrival, tracking recovery, speech timing, background
resume, camera expansion and session retention across tabs. Desktop/widget tests
cannot establish native camera surface stability. Serverpod and Dart MCP tools
were unavailable in the implementation session, so hot restart, connected driver
navigation and runtime log inspection could not be executed.

On this Windows machine Flutter dependency setup initially failed for symlink
privileges. Junctions in ignored desktop plugin caches allowed `flutter pub get`
to finish without changing Windows Developer Mode. Android builds emit an upstream
future-Kotlin-compatibility warning for AR and TTS plugins; neither plugin was
upgraded and the AR pin remains 1.1.3.

Recorded verification on November 14, 2026: 88 Flutter tests passed, `dart analyze`
completed without errors or warnings (informational notices remain), changed Dart
sources were formatted, and the Android debug APK built successfully.
