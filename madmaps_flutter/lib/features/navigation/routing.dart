import 'dart:math' as math;
import 'dart:ui';
import 'floor_data.dart';

class NavigationTuning {
  static const attachmentMeters = 3.0;
  static const corridorMeters = 3.0;
  static const offRouteMeters = 4.0;
  static const offRouteFor = Duration(seconds: 2);
  static const lookAheadMeters = 2.0;
  static const turnMeters = 1.5;
  static const arrivalMeters = 1.5;
}

Offset project(Offset p, Offset a, Offset b) {
  final d = b - a, n = d.dx * d.dx + d.dy * d.dy;
  final t = n == 0
      ? 0.0
      : (((p - a).dx * d.dx + (p - a).dy * d.dy) / n).clamp(0.0, 1.0);
  return a + d * t;
}

enum RouteFailure {
  invalidDestination,
  unmappedDestination,
  noNearbyEdge,
  disconnected,
}

class NavigationRoute {
  NavigationRoute(
    this.points,
    this.cost,
    this.startEdge,
    this.attachmentPixels,
  );

  /// Graph geometry only: the projection is not a compulsory access waypoint.
  final List<Offset> points;
  final double cost, attachmentPixels;
  final String startEdge;
}

class RouteResult {
  RouteResult.success(this.route)
    : failure = null,
      nearestPixels = route!.attachmentPixels,
      startEdge = route.startEdge;
  RouteResult.failure(this.failure, {this.nearestPixels, this.startEdge})
    : route = null;
  final NavigationRoute? route;
  final RouteFailure? failure;
  final double? nearestPixels;
  final String? startEdge;
  String get message => switch (failure) {
    RouteFailure.invalidDestination =>
      'Destination is no longer in this map. Choose another destination.',
    RouteFailure.unmappedDestination =>
      'Not mapped yet — assign a destination approach point in setup.',
    RouteFailure.noNearbyEdge =>
      'No mapped walkway nearby. Move closer or check floor calibration.',
    RouteFailure.disconnected =>
      'No connected route to this destination. Check the draft graph connections.',
    null => 'Route ready',
  };
}

RouteResult findRoute(
  FloorGraph graph,
  FloorSetup setup,
  Offset start,
  String? target,
  double pixelsPerMeter,
) {
  if (target == null) {
    return RouteResult.failure(RouteFailure.unmappedDestination);
  }
  if (!graph.nodes.containsKey(target)) {
    return RouteResult.failure(RouteFailure.invalidDestination);
  }
  final adjacency = <String, List<(String, double)>>{};
  void link(String a, String b, double cost) =>
      adjacency.putIfAbsent(a, () => []).add((b, cost));
  for (final e in graph.edges) {
    link(e.from, e.to, graph.cost(e, setup));
    if (e.bidirectional) link(e.to, e.from, graph.cost(e, setup));
  }
  NavigationRoute? best;
  var nearestPixels = double.infinity;
  String? nearestEdge;
  for (final edge in graph.edges) {
    // Approaches are real walk edges too, including University exit -> hallway.
    final a = graph.point(edge.from, setup), b = graph.point(edge.to, setup);
    final snapped = project(start, a, b), distance = (start - snapped).distance;
    if (distance < nearestPixels) {
      nearestPixels = distance;
      nearestEdge = '${edge.from}->${edge.to}';
    }
    if (distance > NavigationTuning.attachmentMeters * pixelsPerMeter) continue;
    final length = (b - a).distance;
    final fraction = length == 0 ? 0.0 : (snapped - a).distance / length;
    final distances = <String, double>{
      edge.to: graph.cost(edge, setup) * (1 - fraction),
    };
    if (edge.bidirectional || fraction < 1e-8) {
      distances[edge.from] = graph.cost(edge, setup) * fraction;
    }
    final previous = <String, String>{}, visited = <String>{};
    while (true) {
      String? current;
      for (final id in distances.keys) {
        if (!visited.contains(id) &&
            (current == null || distances[id]! < distances[current]!)) {
          current = id;
        }
      }
      if (current == null || current == target) break;
      visited.add(current);
      for (final next in adjacency[current] ?? <(String, double)>[]) {
        final candidate = distances[current]! + next.$2;
        if (candidate < (distances[next.$1] ?? double.infinity)) {
          distances[next.$1] = candidate;
          previous[next.$1] = current;
        }
      }
    }
    if (!distances.containsKey(target)) continue;
    final ids = <String>[target];
    while (previous.containsKey(ids.last)) {
      ids.add(previous[ids.last]!);
    }
    final points = <Offset>[snapped];
    for (final id in ids.reversed) {
      final p = graph.point(id, setup);
      if ((p - points.last).distance > 1e-8) points.add(p);
    }
    final cost = distances[target]! + distance;
    if (best == null ||
        distance < best.attachmentPixels - 1e-6 ||
        ((distance - best.attachmentPixels).abs() <= 1e-6 &&
            cost < best.cost)) {
      best = NavigationRoute(
        points,
        cost,
        '${edge.from}->${edge.to}',
        distance,
      );
    }
  }
  if (best != null) return RouteResult.success(best);
  return RouteResult.failure(
    nearestPixels > NavigationTuning.attachmentMeters * pixelsPerMeter
        ? RouteFailure.noNearbyEdge
        : RouteFailure.disconnected,
    nearestPixels: nearestPixels,
    startEdge: nearestEdge,
  );
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

enum NavigationPhase {
  idle,
  paused,
  unavailable,
  navigating,
  rerouting,
  returningToRoute,
  arrived,
}

class GuidanceState {
  GuidanceState({this.onDiagnostic});
  final void Function(String)? onDiagnostic;
  String? target;
  NavigationRoute? route;
  RouteResult? result;
  int segment = 0;
  double progressPixels = 0;
  Offset? projected;
  DateTime? offRouteSince;
  String status = 'Select a room';

  /// Virtual compass aim point; not a vertex that the pedestrian must visit.
  Offset? next;
  double? remainingMeters;
  String maneuver = 'Continue';
  double? maneuverMeters;
  bool arrived = false;
  bool _localizationPaused = false;
  Offset? rejoinPoint;
  double? rejoinMeters;
  DateTime? _lastReroute;
  NavigationPhase get phase => target == null
      ? NavigationPhase.idle
      : _localizationPaused
      ? NavigationPhase.paused
      : arrived
      ? NavigationPhase.arrived
      : remainingMeters == null
      ? (result?.failure == null
            ? NavigationPhase.paused
            : NavigationPhase.unavailable)
      : rejoinPoint != null
      ? NavigationPhase.returningToRoute
      : offRouteSince != null
      ? NavigationPhase.rerouting
      : NavigationPhase.navigating;
  Duration? get estimatedDuration => remainingMeters == null
      ? null
      : Duration(seconds: (remainingMeters! / 1.2).ceil());
  String? _diagnosticKey;
  void select(String id) {
    target = id;
    reset();
  }

  void reset() {
    route = null;
    result = null;
    segment = 0;
    progressPixels = 0;
    projected = null;
    offRouteSince = null;
    next = null;
    remainingMeters = null;
    maneuverMeters = null;
    arrived = false;
    rejoinPoint = null;
    rejoinMeters = null;
    _lastReroute = null;
    _localizationPaused = false;
    _diagnosticKey = null;
  }

  void _diagnose(double scale) {
    final key =
        '$phase|${result?.failure}|${result?.startEdge}|${(progressPixels / scale / 5).floor()}|${next == null}|${offRouteSince != null}';
    if (key == _diagnosticKey) return;
    _diagnosticKey = key;
    onDiagnostic?.call(
      '[MadMaps navigation] destination=$target startEdge=${result?.startEdge} '
      'attachmentMeters=${result?.nearestPixels == null ? null : result!.nearestPixels! / scale} '
      'pixelsPerMeter=$scale progressMeters=${progressPixels / scale} failure=${result?.failure} status=$status',
    );
  }

  bool _recalculate(
    FloorGraph graph,
    FloorSetup setup,
    Offset position,
    double scale,
  ) {
    result = findRoute(graph, setup, position, target, scale);
    if (result!.route == null) {
      status = result!.message;
      return false;
    }
    route = result!.route;
    segment = 0;
    progressPixels = 0;
    projected = null;
    rejoinPoint = null;
    rejoinMeters = null;
    return true;
  }

  void update(
    FloorGraph graph,
    FloorSetup setup,
    FloorCalibration? calibration,
    Offset? position,
    DateTime now, {
    bool relocalized = false,
  }) {
    next = null;
    remainingMeters = null;
    maneuver = 'Continue';
    maneuverMeters = null;
    arrived = false;
    if (target == null) return;
    _localizationPaused = calibration == null || position == null;
    if (calibration == null || position == null) {
      offRouteSince = null;
      status = 'Guidance paused — calibrate and localize';
      return;
    }
    final scale = calibration.scale;
    if (!graph.nodes.containsKey(target)) {
      route = null;
      result = RouteResult.failure(RouteFailure.invalidDestination);
      status = result!.message;
      return;
    }
    if (route != null && result?.failure == RouteFailure.disconnected) {
      if (_lastReroute != null &&
          now.difference(_lastReroute!) < NavigationTuning.offRouteFor) {
        status = result!.message;
        return;
      }
      _lastReroute = now;
      if (!_recalculate(graph, setup, position, scale)) return;
    }
    if (route == null && !_recalculate(graph, setup, position, scale)) {
      _diagnose(scale);
      return;
    }
    var points = route!.points;
    if (points.length == 1) {
      remainingMeters = (position - points.single).distance / scale;
      if (remainingMeters! <= NavigationTuning.arrivalMeters) {
        projected = points.single;
        status = 'Near entrance (estimated)';
        arrived = true;
        _diagnose(scale);
        return;
      }
      // A route selected while already at its endpoint may later need a new start.
      if (!_recalculate(graph, setup, position, scale)) {
        if (result!.failure != RouteFailure.noNearbyEdge) {
          remainingMeters = null;
          return;
        }
        rejoinPoint = points.single;
        rejoinMeters = (position - points.single).distance / scale;
        next = rejoinPoint;
        maneuver = 'Return to route';
        maneuverMeters = rejoinMeters;
        status =
            'Return to route - ${rejoinMeters!.toStringAsFixed(1)} m (estimated)';
        _diagnose(scale);
        return;
      }
      points = route!.points;
      if (points.length == 1) {
        status = 'Move toward the entrance';
        next = points.single;
        _diagnose(scale);
        return;
      }
    }
    Offset projection(int i) => project(position, points[i], points[i + 1]);
    double distance(int i) => (position - projection(i)).distance;
    bool beyond(Offset start, Offset end) {
      final d = end - start, p = position - end;
      return d.dx * p.dx + d.dy * p.dy >= 0;
    }

    // Hold the recovery leg unless localization was corrected or it was rejoined.
    final holdRecovery =
        rejoinPoint != null &&
        !relocalized &&
        distance(segment) > NavigationTuning.corridorMeters * scale;
    if (!holdRecovery) {
      // Preserve the current leg near parallel lines; only advance across connected turns.
      while (segment < points.length - 2 &&
          (beyond(points[segment], points[segment + 1]) ||
              (position - points[segment + 1]).distance <=
                  NavigationTuning.turnMeters * scale) &&
          distance(segment + 1) <= NavigationTuning.corridorMeters * scale &&
          distance(segment + 1) <= distance(segment) + 1e-6) {
        segment++;
      }
      while (segment > 0 &&
          beyond(points[segment + 1], points[segment]) &&
          distance(segment - 1) < distance(segment) &&
          distance(segment - 1) <= NavigationTuning.corridorMeters * scale) {
        segment--;
      }
      // Recover missed samples/corrections, without jumping to a parallel leg while
      // the current segment is still a plausible match.
      if (distance(segment) > NavigationTuning.corridorMeters * scale) {
        var best = segment;
        for (var i = 0; i < points.length - 1; i++) {
          if (distance(i) < distance(best) - 1e-6 ||
              (relocalized &&
                  (distance(i) - distance(best)).abs() < 1e-6 &&
                  (i - segment).abs() < (best - segment).abs())) {
            best = i;
          }
        }
        if (relocalized ||
            distance(best) <= NavigationTuning.corridorMeters * scale) {
          segment = best;
        }
      }
    }
    final lateral = distance(segment) / scale;
    if (lateral <= NavigationTuning.corridorMeters) {
      rejoinPoint = null;
      rejoinMeters = null;
      result = RouteResult.success(route!);
    }
    if (lateral <= NavigationTuning.corridorMeters) offRouteSince = null;
    if (lateral > NavigationTuning.offRouteMeters) offRouteSince ??= now;
    if (offRouteSince != null &&
        now.difference(offRouteSince!) >= NavigationTuning.offRouteFor &&
        (_lastReroute == null ||
            now.difference(_lastReroute!) >= NavigationTuning.offRouteFor)) {
      _lastReroute = now;
      if (_recalculate(graph, setup, position, scale)) {
        offRouteSince = null;
        update(graph, setup, calibration, position, now);
        return;
      }
      if (result!.failure != RouteFailure.noNearbyEdge) {
        _diagnose(scale);
        return;
      }
      rejoinPoint = projection(segment);
    }
    projected = projection(segment);
    progressPixels = (projected! - points[segment]).distance;
    for (var i = 0; i < segment; i++) {
      progressPixels += (points[i + 1] - points[i]).distance;
    }
    var remaining = (points[segment + 1] - projected!).distance;
    for (var i = segment + 1; i < points.length - 1; i++) {
      remaining += (points[i + 1] - points[i]).distance;
    }
    remainingMeters = remaining / scale;
    if (rejoinPoint != null) {
      rejoinPoint = projected;
      rejoinMeters = (position - rejoinPoint!).distance / scale;
      remainingMeters = remainingMeters! + rejoinMeters!;
      next = rejoinPoint;
      maneuver = 'Return to route';
      maneuverMeters = rejoinMeters;
      status =
          'Return to route - ${rejoinMeters!.toStringAsFixed(1)} m (estimated)';
      _diagnose(scale);
      return;
    }
    if (segment == points.length - 2 &&
        (position - points.last).distance <=
            NavigationTuning.arrivalMeters * scale) {
      status = 'Near entrance (estimated)';
      arrived = true;
      _diagnose(scale);
      return;
    }
    final vector = points[segment + 1] - projected!;
    if (vector.distance > 1e-8) {
      // Translate the forward vector to the actual pedestrian position. Walking
      // beside the centerline therefore does not produce a sideways correction.
      next =
          position +
          vector /
              vector.distance *
              math.min(
                vector.distance,
                NavigationTuning.lookAheadMeters * scale,
              );
    } else {
      // At the end plane but outside arrival tolerance, the approach itself is
      // meaningful; unlike internal centerline projections it may need reaching.
      next = points[segment + 1];
    }
    status = offRouteSince == null
        ? 'Continue'
        : 'Rechecking route — continue toward the next turn';
    if (offRouteSince == null) {
      var until = (points[segment + 1] - projected!).distance;
      for (var i = segment + 1; i < points.length - 1; i++) {
        final turn = turnInstruction(
          points[i] - points[i - 1],
          points[i + 1] - points[i],
        );
        if (turn != 'Continue') {
          maneuver = turn;
          maneuverMeters = until / scale;
          status = '$turn in ${(until / scale).toStringAsFixed(1)} m';
          break;
        }
        until += (points[i + 1] - points[i]).distance;
      }
    }
    _diagnose(scale);
  }
}
