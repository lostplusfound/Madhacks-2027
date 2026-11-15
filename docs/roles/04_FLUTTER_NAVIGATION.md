# Role 4: Flutter navigation and routing

## Mission and current state

Local floor-1 navigation is implemented under
`madmaps_flutter/lib/features/navigation/` and integrated with the AR session.
It includes two-anchor image calibration, CSV graph loading, local overrides,
directed Dijkstra routing, progress/turns/ETA, off-route and distant-start recovery,
and a map-first UI with interactive markers and heading-follow. Disabling floor
association restores the legacy AR layout. The latest recorded combined suite
has 80 passing Flutter tests, clean analysis apart from informational notices,
and a successful Android debug APK build.

Read [current navigation behavior](../FLOOR_NAVIGATION.md), [architecture](../ARCHITECTURE.md),
and [testing/physical acceptance](../TESTING.md) before extending it. The floor
plan remains an image with interactive overlays, not wall/room polygons. All
routes and amenity approaches are draft. Shared domain types, repository/service
adapters, backend persistence, revision enforcement, and multi-floor transitions
remain future work. The proposed ownership/interface/task checklist below is a
future integration handoff, not a claim that current local features are absent.

## Ownership and proposed interface

Own madmaps_flutter/lib/features/navigation/, future routing code, and main.dart composition. Lead the future packages/indoor_core/ creation with team review. AR owns localization implementation; backend owns repository implementation. Widgets consume LocalizationService and MapRepository boundaries, never native plugin callbacks.

Inputs: published IndoorMap, room selection, and localized pose stream. Output: NavigationRoute, floor-plan overlay, tracking status, and guidance. Begin with Flutter SDK ChangeNotifier/ValueNotifier and separate graph logic from widgets.

## Task checklist

1. For shared-domain integration, agree minimal shared types and adapters with affected teammates. Preserve the implemented synthetic routing fixtures and local tests; add a mock walk stream at the agreed service boundary.
2. Render original-pixel map coordinates using a consistent image-to-screen transform for the image, nodes, route, and position.
3. Implement Dijkstra with meter-based weights derived from calibration. Snap localized position to an appropriate verified corridor edge, not an arbitrary destination node.
4. Add room selection, route polyline, distance, and explicit unreachable state. Respect directionality and agreed publication policy.
5. Preserve estimated AR movement after cloud failures; hide the dot and pause directions on actual tracking loss, with automatic recovery status.
6. Compose mock localization initially. Replace only the injected service when AR is ready; preserve the same widget inputs.
7. Replace fixture repository with backend adapter and verify map/anchor revision alignment.

## Fixtures, tests, and acceptance

Create one synthetic floor with three rooms, two intersections, multiple edges, a destination door, known calibration, and fake anchor metadata. Add mock walking positions toward a room. Test connectivity, references, shortest path, unreachable room, invalid IDs, revision mismatch, pixel transforms, and position projection.

Run Flutter analysis/tests from README. Done means a mock visitor moves visibly along a valid route and changing localization implementation needs no widget rewrite. Real demo acceptance additionally requires a physically verified hallway route.

## Debugging and integration

For drifting overlays check BoxFit scaling/letterboxing and original dimensions. For routes through walls inspect graph edges and review state. For implausible distances inspect calibration units. For jumping position check floor/revision and localization state before interpolation.

Exchange a fixture with AI/backend early. Request AR traces before live integration. Stretch goals: rerouting, multi-floor transitions, accessible-route preferences after edge data is verified, and richer instructions.
