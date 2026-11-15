import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps_client/madmaps_client.dart' as api;
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/map_repository.dart';
import 'package:madmaps/features/navigation/building_routing.dart';
import 'package:madmaps/features/navigation/routing.dart';
import 'map_repository_test.dart' show fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final floors = {
    for (final f in [0, 1, 2, 3]) f: adaptSnapshot(fixture(f), floorNumber: f),
  };
  final connectors =
      (jsonDecode(
                File(
                  '../madmaps_server/assets/floor_connectors.json',
                ).readAsStringSync(),
              )
              as List)
          .map((j) => api.FloorConnector.fromJson(j as Map<String, dynamic>))
          .toList();
  test('each declared connector has matching floor and graph endpoints', () {
    for (final c in connectors) {
      expect(floors[c.fromFloor]!.graphId, c.fromGraphId);
      expect(floors[c.toFloor]!.nodes.containsKey(c.toNodeId), isTrue);
      expect(floors[c.fromFloor]!.nodes.containsKey(c.fromNodeId), isTrue);
    }
  });
  test('reviewed lower-floor stairs use only the marked landings', () {
    final stairs = connectors.where(
      (c) => c.active && c.type == api.EdgeType.stairs,
    );
    final basement = stairs.where((c) => c.fromFloor == 0).toList();
    expect(basement.map((c) => c.connectorId), ['north-0-1']);
    expect(basement.single.fromNodeId, 'f0-stairs-landing');
    expect(basement.single.toNodeId, 'f1-university-basement-stairs');
    expect(basement.single.bidirectional, isTrue);
    final upper = stairs.where((c) => c.fromFloor == 1).toList();
    expect(upper.map((c) => c.connectorId), ['atrium-1-2']);
    expect(upper.single.fromNodeId, 'f1-main-stairs-approach');
    expect(upper.single.bidirectional, isTrue);
    expect(
      floors[1]!.nodes[basement.single.toNodeId]!.point,
      const Offset(962, 148),
    );
  });
  test('all seeded walking edges avoid registered walls', () {
    for (final g in floors.values) {
      for (final e in g.edges) {
        expect(
          g.permits(g.nodes[e.from]!.point, g.nodes[e.to]!.point),
          isTrue,
          reason: '${e.from} -> ${e.to}',
        );
      }
    }
  });
  test(
    'all floors can reach every mapped destination through stairs and elevators',
    () {
      for (final start in floors.values) {
        final origin = start.nodes.values
            .firstWhere((n) => n.kind == 'junction')
            .point;
        for (final end
            in floors.values
                .expand((g) => g.locations)
                .where((l) => l.node != null)) {
          final route = planBuildingRoute(
            floors: floors,
            connectors: connectors,
            startFloor: start.floor,
            start: origin,
            destination: end,
          );
          expect(route, isNotNull, reason: '${start.floor} -> ${end.id}');
          expect(route!.legs.last.floor, end.floor);
          expect(
            route.legs.last.points.last,
            floors[end.floor]!.nodes[end.node]!.point,
          );
          for (final leg in route.legs) {
            final g = floors[leg.floor]!;
            for (var i = 1; i < leg.points.length; i++)
              expect(g.permits(leg.points[i - 1], leg.points[i]), isTrue);
          }
        }
      }
    },
  );
  test('explicit floor travel choices constrain every transition', () {
    final destination = floors[3]!.locations.firstWhere((l) => l.node != null);
    for (final mode in [FloorTravelMode.stairs, FloorTravelMode.elevator]) {
      BuildingRoute? plan(
        List<api.FloorConnector> links, {
        bool avoid = false,
      }) => planBuildingRoute(
        floors: floors,
        connectors: links,
        startFloor: 0,
        start: floors[0]!.nodes['f0-south-hall']!.point,
        destination: destination,
        travelMode: mode,
        avoidStairs: avoid,
      );
      final expected = mode == FloorTravelMode.stairs
          ? api.EdgeType.stairs
          : api.EdgeType.elevator;
      final route = plan(connectors);
      expect(route, isNotNull);
      final exits = route!.legs.where((l) => l.exit != null);
      expect(exits, isNotEmpty);
      expect(exits.every((l) => l.exit!.type == expected), isTrue);
      expect(
        plan(connectors.where((c) => c.type != expected).toList()),
        isNull,
      );
      expect(
        plan(connectors, avoid: true)!.legs
            .where((l) => l.exit != null)
            .every((l) => l.exit!.type == api.EdgeType.elevator),
        isTrue,
      );
    }
  });
  test('avoid stairs uses the elevator and respects disabled connections', () {
    final destination = floors[3]!.locations.firstWhere((l) => l.node != null);
    BuildingRoute? route(List<api.FloorConnector> links) => planBuildingRoute(
      floors: floors,
      connectors: links,
      startFloor: 0,
      start: floors[0]!.nodes['f0-south-hall']!.point,
      destination: destination,
      avoidStairs: true,
    );
    final accessible = route(connectors)!;
    expect(
      accessible.legs
          .where((l) => l.exit != null)
          .every((l) => l.exit!.type == api.EdgeType.elevator),
      isTrue,
    );
    expect(
      route(connectors.where((c) => c.type == api.EdgeType.stairs).toList()),
      isNull,
    );
    expect(
      route(connectors.map((c) => c.copyWith(active: false)).toList()),
      isNull,
    );
  });
  test('bathroom route goes around highlighted divider', () {
    final g = floors[1]!;
    final result = findRoute(
      g,
      FloorSetup(),
      g.nodes['f1-demo-lobby']!.point,
      'f1-auditorium-restroom-1-approach',
      10,
    );
    expect(result.route, isNotNull);
    expect(
      result.route!.points,
      contains(g.nodes['f1-restroom-divider-north']!.point),
    );
    for (var i = 1; i < result.route!.points.length; i++)
      expect(
        g.permits(result.route!.points[i - 1], result.route!.points[i]),
        isTrue,
      );
  });
  test(
    'University to 1524 follows central spine without cafe backtracking',
    () {
      final g = floors[1]!;
      final result = findRoute(
        g,
        FloorSetup(),
        g.nodes['f1-exit-university']!.point,
        'f1-demo-1524',
        10,
      );
      expect(result.route, isNotNull);
      expect(
        result.route!.points,
        contains(g.nodes['f1-demo-main-hall']!.point),
      );
      expect(
        result.route!.points,
        isNot(contains(g.nodes['f1-demo-cafe-turn']!.point)),
      );
      expect(result.route!.points.last, const Offset(655, 834));
      expect(
        result.route!.points,
        contains(g.nodes['f1-1524-east-hall']!.point),
      );
    },
  );
  test('room rows use short perpendicular corridor spurs', () {
    final g = floors[2]!;
    for (final number in [
      '2513',
      '2515',
      '2517',
      '2519',
      '2521',
      '2525',
      '2527',
      '2531',
    ]) {
      final door = g.nodes['f2-room-$number']!.point,
          hall = g.nodes['f2-door-hall-$number']!.point;
      expect(door.dx, hall.dx);
      expect((door.dy - hall.dy).abs(), lessThan(25));
      expect(
        g.edges.any(
          (e) => {
            e.from,
            e.to,
          }.containsAll(['f2-room-$number', 'f2-door-hall-$number']),
        ),
        isTrue,
      );
    }
  });
}
