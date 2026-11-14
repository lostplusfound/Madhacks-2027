# Role 4: Flutter navigation and routing

## Mission and current state

Build map navigation independently of physical AR. The app currently contains only a generated Serverpod greeting example. No shared models, fixtures, mocks, routing, or map UI exist. ../CONTRACTS.md and coordinate rules are proposals; settle the first revision with teammates before implementing them.

## Ownership and proposed interface

Own madmaps_flutter/lib/features/navigation/, future routing code, and main.dart composition. Lead the future packages/indoor_core/ creation with team review. AR owns localization implementation; backend owns repository implementation. Widgets consume LocalizationService and MapRepository boundaries, never native plugin callbacks.

Inputs: published IndoorMap, room selection, and localized pose stream. Output: NavigationRoute, floor-plan overlay, tracking status, and guidance. Begin with Flutter SDK ChangeNotifier/ValueNotifier and separate graph logic from widgets.

## Task checklist

1. First task: agree and implement minimal shared types plus a synthetic floor and mock walk stream, with affected teammates reviewing the proposed contracts.
2. Render original-pixel map coordinates using a consistent image-to-screen transform for the image, nodes, route, and position.
3. Implement Dijkstra with meter-based weights derived from calibration. Snap localized position to an appropriate verified corridor edge, not an arbitrary destination node.
4. Add room selection, route polyline, distance, and explicit unreachable state. Respect directionality and agreed publication policy.
5. Hide precise live location before localization and show limited/lost states honestly.
6. Compose mock localization initially. Replace only the injected service when AR is ready; preserve the same widget inputs.
7. Replace fixture repository with backend adapter and verify map/anchor revision alignment.

## Fixtures, tests, and acceptance

Create one synthetic floor with three rooms, two intersections, multiple edges, a destination door, known calibration, and fake anchor metadata. Add mock walking positions toward a room. Test connectivity, references, shortest path, unreachable room, invalid IDs, revision mismatch, pixel transforms, and position projection.

Run Flutter analysis/tests from README. Done means a mock visitor moves visibly along a valid route and changing localization implementation needs no widget rewrite. Real demo acceptance additionally requires a physically verified hallway route.

## Debugging and integration

For drifting overlays check BoxFit scaling/letterboxing and original dimensions. For routes through walls inspect graph edges and review state. For implausible distances inspect calibration units. For jumping position check floor/revision and localization state before interpolation.

Exchange a fixture with AI/backend early. Request AR traces before live integration. Stretch goals: rerouting, multi-floor transitions, accessible-route preferences after edge data is verified, and richer instructions.
