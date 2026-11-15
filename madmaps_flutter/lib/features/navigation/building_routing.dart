import 'dart:ui';
import 'package:madmaps_client/madmaps_client.dart' as api;
import 'floor_data.dart';
import 'routing.dart';

class BuildingLeg {
  BuildingLeg(this.floor, this.points, this.targetNode, this.meters, this.exit);
  final int floor;
  final List<Offset> points;
  final String targetNode;
  final double meters;
  final api.FloorConnector? exit;
}

class BuildingRoute {
  BuildingRoute(this.legs, this.seconds);
  final List<BuildingLeg> legs;
  final double seconds;
  double get meters => legs.fold(0, (sum, l) => sum + l.meters);
}

class _Link {
  _Link(this.to, this.seconds, [this.connector]);
  final String to;
  final double seconds;
  final api.FloorConnector? connector;
}

/// Floor-qualified node references; connector traversal never joins image pixels.
BuildingRoute? planBuildingRoute({
  required Map<int, FloorGraph> floors,
  required List<api.FloorConnector> connectors,
  required int startFloor,
  required Offset start,
  required FloorLocation destination,
  Map<int, FloorSetup> setups = const {},
  Map<int, double> measuredScales = const {},
  bool avoidStairs = false,
}) {
  final source = floors[startFloor], target = floors[destination.floor];
  if (source == null ||
      target == null ||
      destination.node == null ||
      !target.nodes.containsKey(destination.node))
    return null;
  String ref(int floor, String node) => '$floor:$node';
  final adjacency = <String, List<_Link>>{};
  final points = <String, Offset>{},
      floorOf = <String, int>{},
      nodeOf = <String, String>{};
  double scale(int floor) =>
      measuredScales[floor] ?? floors[floor]!.metersPerPixel;
  void link(String a, String b, double cost, [api.FloorConnector? connector]) =>
      adjacency.putIfAbsent(a, () => []).add(_Link(b, cost, connector));
  for (final entry in floors.entries) {
    final f = entry.key, g = entry.value, setup = setups[f] ?? FloorSetup();
    for (final n in g.nodes.values) {
      final id = ref(f, n.id);
      points[id] = g.point(n.id, setup);
      floorOf[id] = f;
      nodeOf[id] = n.id;
    }
    for (final e in g.walkEdges(setup, avoidStairs: avoidStairs)) {
      final a = ref(f, e.from),
          b = ref(f, e.to),
          seconds = g.cost(e, setup) * scale(f) / 1.2;
      link(a, b, seconds);
      if (e.bidirectional) link(b, a, seconds);
    }
  }
  for (final c in connectors) {
    if (!c.active ||
        !c.seconds.isFinite ||
        c.seconds <= 0 ||
        (avoidStairs &&
            c.type != api.EdgeType.elevator &&
            c.type != api.EdgeType.ramp))
      continue;
    if (floors[c.fromFloor]?.graphId != c.fromGraphId ||
        floors[c.toFloor]?.graphId != c.toGraphId)
      continue;
    final a = ref(c.fromFloor, c.fromNodeId), b = ref(c.toFloor, c.toNodeId);
    if (!points.containsKey(a) || !points.containsKey(b)) continue;
    link(a, b, c.seconds, c);
    if (c.bidirectional)
      link(
        b,
        a,
        c.seconds,
        c.copyWith(
          fromGraphId: c.toGraphId,
          fromFloor: c.toFloor,
          fromNodeId: c.toNodeId,
          toGraphId: c.fromGraphId,
          toFloor: c.fromFloor,
          toNodeId: c.fromNodeId,
        ),
      );
  }
  // Choose the nearest wall-visible corridor before optimizing the trip.
  final setup = setups[startFloor] ?? FloorSetup();
  var nearest = double.infinity;
  final attachments = <(FloorEdge, Offset)>[];
  for (final e in source.walkEdges(setup, avoidStairs: avoidStairs)) {
    final p = project(
      start,
      source.point(e.from, setup),
      source.point(e.to, setup),
    );
    if (!source.permits(start, p)) continue;
    final distance = (start - p).distance;
    if (distance < nearest - 1e-6) {
      nearest = distance;
      attachments.clear();
    }
    if ((distance - nearest).abs() < 1e-6) attachments.add((e, p));
  }
  const root = '@start';
  for (final (e, p) in attachments) {
    final a = source.point(e.from, setup),
        b = source.point(e.to, setup),
        length = (a - b).distance;
    final fraction = length == 0 ? 0.0 : (p - a).distance / length;
    // Separate synthetic vertices retain the chosen projection in reconstruction.
    final snap = '@snap${adjacency[root]?.length ?? 0}';
    points[snap] = p;
    floorOf[snap] = startFloor;
    nodeOf[snap] = e.to;
    link(root, snap, nearest * scale(startFloor) / 1.2);
    link(
      snap,
      ref(startFloor, e.to),
      source.cost(e, setup) * (1 - fraction) * scale(startFloor) / 1.2,
    );
    if (e.bidirectional || fraction < 1e-8)
      link(
        snap,
        ref(startFloor, e.from),
        source.cost(e, setup) * fraction * scale(startFloor) / 1.2,
      );
  }
  final goal = ref(destination.floor, destination.node!);
  final distance = <String, double>{root: 0},
      previous = <String, (String, _Link)>{},
      visited = <String>{};
  while (true) {
    String? current;
    for (final id in distance.keys) {
      if (!visited.contains(id) &&
          (current == null || distance[id]! < distance[current]!))
        current = id;
    }
    if (current == null || current == goal) break;
    visited.add(current);
    for (final e in adjacency[current] ?? <_Link>[]) {
      final cost = distance[current]! + e.seconds;
      if (cost < (distance[e.to] ?? double.infinity)) {
        distance[e.to] = cost;
        previous[e.to] = (current, e);
      }
    }
  }
  if (!distance.containsKey(goal)) return null;
  final reversed = <String>[goal];
  while (previous.containsKey(reversed.last))
    reversed.add(previous[reversed.last]!.$1);
  final path = reversed.reversed.where((id) => id != root).toList();
  final legs = <BuildingLeg>[];
  var floor = startFloor, legPoints = <Offset>[], meters = 0.0;
  for (var i = 0; i < path.length; i++) {
    final id = path[i], p = points[id]!;
    final connector = previous[id]?.$2.connector;
    if (connector != null) {
      legs.add(
        BuildingLeg(floor, legPoints, nodeOf[path[i - 1]]!, meters, connector),
      );
      floor = floorOf[id]!;
      legPoints = [];
      meters = 0;
    }
    if (legPoints.isNotEmpty)
      meters += (p - legPoints.last).distance * scale(floor);
    if (legPoints.isEmpty || (p - legPoints.last).distance > 1e-6)
      legPoints.add(p);
  }
  legs.add(BuildingLeg(floor, legPoints, destination.node!, meters, null));
  return BuildingRoute(legs, distance[goal]!);
}
