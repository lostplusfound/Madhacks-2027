import 'dart:math' as math;
import 'dart:ui';
import 'floor_data.dart';

Offset project(Offset p, Offset a, Offset b) {
  final d = b - a, n = d.dx * d.dx + d.dy * d.dy;
  final t = n == 0
      ? 0.0
      : (((p - a).dx * d.dx + (p - a).dy * d.dy) / n).clamp(0.0, 1.0);
  return a + d * t;
}

class NavigationRoute {
  NavigationRoute(this.points, this.cost);
  final List<Offset> points;
  final double cost;
}

NavigationRoute? findRoute(
  FloorGraph graph,
  FloorSetup setup,
  Offset start,
  String target,
  double pixelsPerMeter,
) {
  if (!graph.nodes.containsKey(target)) return null;
  FloorEdge? nearest;
  Offset? snapped;
  var best = 3 * pixelsPerMeter;
  for (final e in graph.edges) {
    if (graph.nodes[e.from]!.kind == 'approach' ||
        graph.nodes[e.to]!.kind == 'approach') {
      continue;
    }
    final p = project(
      start,
      graph.point(e.from, setup),
      graph.point(e.to, setup),
    );
    final distance = (start - p).distance;
    if (distance <= best) {
      best = distance;
      nearest = e;
      snapped = p;
    }
  }
  if (nearest == null || snapped == null) return null;
  final adjacency = <String, List<(String, double)>>{};
  void link(String a, String b, double cost) =>
      adjacency.putIfAbsent(a, () => []).add((b, cost));
  for (final e in graph.edges) {
    link(e.from, e.to, graph.cost(e, setup));
    if (e.bidirectional) link(e.to, e.from, graph.cost(e, setup));
  }
  final a = graph.point(nearest.from, setup),
      b = graph.point(nearest.to, setup);
  final length = (b - a).distance;
  final fraction = length == 0 ? 0.0 : (snapped - a).distance / length;
  link('@start', nearest.to, graph.cost(nearest, setup) * (1 - fraction));
  if (nearest.bidirectional || fraction < 1e-8) {
    link('@start', nearest.from, graph.cost(nearest, setup) * fraction);
  }
  final distances = <String, double>{'@start': 0},
      previous = <String, String>{},
      visited = <String>{};
  while (true) {
    String? current;
    for (final id in distances.keys) {
      if (!visited.contains(id) &&
          (current == null || distances[id]! < distances[current]!)) {
        current = id;
      }
    }
    if (current == null) return null;
    if (current == target) break;
    visited.add(current);
    for (final next in adjacency[current] ?? <(String, double)>[]) {
      final candidate = distances[current]! + next.$2;
      if (candidate < (distances[next.$1] ?? double.infinity)) {
        distances[next.$1] = candidate;
        previous[next.$1] = current;
      }
    }
  }
  final ids = <String>[];
  var id = target;
  while (id != '@start') {
    ids.add(id);
    id = previous[id]!;
  }
  return NavigationRoute([
    start,
    snapped,
    ...ids.reversed.map((id) => graph.point(id, setup)),
  ], distances[target]! + best);
}

String turnInstruction(Offset incoming, Offset outgoing) {
  final angle = math.atan2(
    incoming.dx * outgoing.dy - incoming.dy * outgoing.dx,
    incoming.dx * outgoing.dx + incoming.dy * outgoing.dy,
  );
  if (angle.abs() < math.pi / 6) return 'Continue';
  if (angle.abs() > math.pi * 5 / 6) return 'Turn around';
  return angle > 0 ? 'Turn right' : 'Turn left';
}

class GuidanceState {
  String? target;
  NavigationRoute? route;
  int waypoint = 1;
  DateTime? offRouteSince;
  String status = 'Select a room';
  Offset? next;
  double? remainingMeters;
  void select(String id) {
    target = id;
    reset();
  }

  void reset() {
    route = null;
    waypoint = 1;
    offRouteSince = null;
    next = null;
    remainingMeters = null;
  }

  void update(
    FloorGraph graph,
    FloorSetup setup,
    FloorCalibration? calibration,
    Offset? position,
    DateTime now,
  ) {
    next = null;
    remainingMeters = null;
    if (target == null) return;
    if (calibration == null || position == null) {
      offRouteSince = null;
      status = 'Guidance paused — calibrate and localize';
      return;
    }
    if (route == null) {
      route = findRoute(graph, setup, position, target!, calibration.scale);
      waypoint = 1;
      if (route == null) {
        status = 'No route here — return to a mapped hallway';
        return;
      }
    }
    var points = route!.points;
    var distance = double.infinity;
    // Only consider the current and next segments, avoiding jumps across loops.
    for (var i = waypoint; i < points.length && i <= waypoint + 1; i++) {
      distance = math.min(
        distance,
        (position - project(position, points[i - 1], points[i])).distance,
      );
    }
    if (distance > 3 * calibration.scale) {
      offRouteSince ??= now;
      status = 'Off route — return to a mapped hallway';
      if (now.difference(offRouteSince!) >= const Duration(seconds: 2)) {
        route = findRoute(graph, setup, position, target!, calibration.scale);
        waypoint = 1;
        offRouteSince = null;
      }
      return;
    }
    offRouteSince = null;
    points = route!.points;
    bool passedWaypoint() {
      final incoming = points[waypoint] - points[waypoint - 1];
      final beyond = position - points[waypoint];
      final forward = incoming.dx * beyond.dx + incoming.dy * beyond.dy;
      return incoming.distance > 0 &&
          forward >= 0 &&
          (position - project(position, points[waypoint], points[waypoint + 1]))
                  .distance <=
              1.5 * calibration.scale;
    }

    while (waypoint < points.length - 1 &&
        ((position - points[waypoint]).distance <= 1.5 * calibration.scale ||
            passedWaypoint())) {
      waypoint++;
    }
    if (waypoint == points.length - 1 &&
        (position - points.last).distance <= 1.5 * calibration.scale) {
      status = 'Near entrance (estimated)';
      remainingMeters = (position - points.last).distance / calibration.scale;
      return;
    }
    next = points[waypoint];
    var remaining = (position - next!).distance;
    for (var i = waypoint + 1; i < points.length; i++) {
      remaining += (points[i] - points[i - 1]).distance;
    }
    remainingMeters = remaining / calibration.scale;
    var instruction = 'Continue';
    for (var i = waypoint; i < points.length - 1; i++) {
      final turn = turnInstruction(
        points[i] - points[i - 1],
        points[i + 1] - points[i],
      );
      if (turn != 'Continue') {
        var until = (position - points[waypoint]).distance;
        for (var j = waypoint; j < i; j++) {
          until += (points[j + 1] - points[j]).distance;
        }
        instruction =
            '$turn in ${(until / calibration.scale).toStringAsFixed(1)} m';
        break;
      }
    }
    status = instruction;
  }
}
