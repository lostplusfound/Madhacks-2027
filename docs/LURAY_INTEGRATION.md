# Serverpod map and search integration

Branch: `integration/luray-maps-search`. Merged Luray through commit `ba2537c` after
checking the remote branch again during implementation. The visitor UI remains the Swara integration.
The latest backend supports wall polygons, but our seed contains an empty wall list.
No wall data is invented and no wall UI is added. The frontend rejects Floor 1
snapshots containing walls until its local router supports those constraints.

## Behavior

The app requires Serverpod to load graph `morgridge-floor1` and quick-access
categories at startup. It does not substitute bundled CSVs on failure. Retry
handles connection errors, missing graphs and incompatible map data.

Home searches Serverpod after a 300 ms debounce, adds matching personal aliases,
and ignores late responses from older queries. Quick-access categories come from
the backend and appear only if the loaded floor has matching destinations.
Bookmarks and history retain their existing stable location IDs.

The loaded graph is shared with the map, AR navigation and calibration tools for
the lifetime of the shell. Navigation continues from that in-memory graph if the
server becomes unreachable. Successful query/category responses are also cached
in memory; uncached requests display an error and Retry on failure. Nothing is
persisted as an offline map cache. Restart the app to load a new graph revision.

Routing, anchor records, calibration, local overrides, preferences, aliases and
history remain on the phone. Cloud Anchor services still need their own network
connection. Backend graph coordinates and edge costs are image pixels. Walking
distances use the existing local calibration; the seed's `metersPerUnit: 1` is a
placeholder and is not used as a physical distance measurement.

## Initialize a database

Configure `madmaps_server/config/passwords.yaml` using the example; Luray's auth
services need `serverSideSessionKeyHashPepper` and `emailSecretHashPepper` in
addition to the existing database/service secrets. Use independent random values.
The visitor app does not require sign-in. Map writes remain authenticated.

Start the runner in `madmaps_server` with `serverpod runner start`. It applies
Luray's pending migrations on boot. Then, from that package, run:

```powershell
dart run bin/seed_floor1.dart
```

This explicit operator command uses an internal authenticated session, creates the
building/graph if absent, and preserves draft review notes. Repeated invocations
verify the existing data and fail if it differs; they do not replace an existing
graph. The fixture is `assets/floor1_seed.json`, copied from the current frontend
Floor 1 CSVs, including the added amenity approaches. Geometry remains draft even
though database rows have active lifecycle status. Seed fidelity tests detect
future divergence from the frontend assets.

Launch/build the Android app with the server address reachable from the phone:

```powershell
flutter run -t lib/driver.dart --dart-define=SERVER_URL=http://<computer-LAN-IP>:8080/
```

Use the actual address reported by the runner. `MAP_GRAPH_ID` optionally overrides
the graph ID; any replacement must match the bundled 1632×1056 Floor 1 image and
retain compatible IDs/coordinates for existing local calibration and overrides.

## Validation and local blockers

Serverpod generation, static analysis, Flutter tests, server unit tests and an
Android debug APK build were exercised during integration. Runtime backend
acceptance remains pending on this machine: the runner compiles but fails to
launch its VM service because `dart_runtime_service_vm.dart.snapshot` is missing
from the installed Dart SDK. Database integration tests also fail during setup
because embedded PostgreSQL is unavailable on this platform. Migrations and the
seed have therefore not been applied to a live database here.

Serverpod/Dart MCP tools were unavailable in this session, preventing connected
driver checks, hot restart and runtime server/Flutter log inspection. Once the
runtime is available, verify anonymous map/search requests, seed twice, navigate
with existing calibration, disconnect the backend, confirm the loaded route stays
usable and an uncached search reports connection loss, then restore connectivity
and Retry. Physical AR walking and calibration acceptance remain required.

Reporting/sign-in UI, shared anchors, graph editing, server routing and multi-floor
guidance are outside this integration.
