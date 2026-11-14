import 'dart:math' as math;

import 'a_star.dart';
import 'indoor_graph.dart';

class EuclideanTimeHeuristic implements RoutingHeuristic {
  const EuclideanTimeHeuristic({this.maximumWalkingSpeedMetersPerSecond = 1.6});

  final double maximumWalkingSpeedMetersPerSecond;

  @override
  String get name => 'euclidean';

  @override
  double estimate(IndoorGraph graph, String fromNodeId, String goalNodeId) =>
      graph.node(fromNodeId).planarDistanceTo(graph.node(goalNodeId)) /
      maximumWalkingSpeedMetersPerSecond;
}

class ManhattanTimeHeuristic implements RoutingHeuristic {
  const ManhattanTimeHeuristic({this.maximumWalkingSpeedMetersPerSecond = 1.6});

  final double maximumWalkingSpeedMetersPerSecond;

  @override
  String get name => 'manhattan';

  @override
  double estimate(IndoorGraph graph, String fromNodeId, String goalNodeId) =>
      graph.node(fromNodeId).manhattanDistanceTo(graph.node(goalNodeId)) /
      maximumWalkingSpeedMetersPerSecond;
}

class FloorAwareHeuristic implements RoutingHeuristic {
  const FloorAwareHeuristic({
    this.maximumWalkingSpeedMetersPerSecond = 1.6,
    this.minimumFloorTransitionSeconds = 12,
  });

  final double maximumWalkingSpeedMetersPerSecond;
  final double minimumFloorTransitionSeconds;

  @override
  String get name => 'floor-aware';

  @override
  double estimate(IndoorGraph graph, String fromNodeId, String goalNodeId) {
    final from = graph.node(fromNodeId);
    final goal = graph.node(goalNodeId);
    return from.manhattanDistanceTo(goal) / maximumWalkingSpeedMetersPerSecond +
        (from.floor - goal.floor).abs() * minimumFloorTransitionSeconds;
  }
}

/// A conservative floor heuristic for noisy, floor-local coordinates.
///
/// Cross-floor planar coordinates are not compared because individual floors
/// may use different local frames. On one floor, the configured error bound is
/// removed from both endpoint positions before deriving a distance bound.
class UncertainCoordinateFloorHeuristic implements RoutingHeuristic {
  const UncertainCoordinateFloorHeuristic({
    this.maximumWalkingSpeedMetersPerSecond = 1.6,
    this.minimumFloorTransitionSeconds = 12,
    this.maximumCoordinateErrorMeters = 4,
  });

  final double maximumWalkingSpeedMetersPerSecond;
  final double minimumFloorTransitionSeconds;
  final double maximumCoordinateErrorMeters;

  @override
  String get name => 'crowd-safe-floor';

  @override
  double estimate(IndoorGraph graph, String fromNodeId, String goalNodeId) {
    final from = graph.node(fromNodeId);
    final goal = graph.node(goalNodeId);
    final floorChanges = (from.floor - goal.floor).abs();
    var planarSeconds = 0.0;
    if (floorChanges == 0) {
      final conservativeDistance = math.max(
        0,
        from.planarDistanceTo(goal) - 2 * maximumCoordinateErrorMeters,
      );
      planarSeconds = conservativeDistance / maximumWalkingSpeedMetersPerSecond;
    }
    return planarSeconds + floorChanges * minimumFloorTransitionSeconds;
  }
}

/// Combines admissible heuristics by taking their strongest lower bound.
///
/// The maximum remains admissible. Do not sum heuristic estimates because
/// overlapping lower bounds would be counted more than once.
class MaxHeuristic implements RoutingHeuristic {
  MaxHeuristic(Iterable<RoutingHeuristic> heuristics)
    : heuristics = List.unmodifiable(heuristics) {
    if (this.heuristics.isEmpty) {
      throw ArgumentError('At least one heuristic is required.');
    }
  }

  final List<RoutingHeuristic> heuristics;

  @override
  String get name => 'hybrid-max';

  @override
  double estimate(IndoorGraph graph, String fromNodeId, String goalNodeId) {
    var strongest = 0.0;
    for (final heuristic in heuristics) {
      strongest = math.max(
        strongest,
        heuristic.estimate(graph, fromNodeId, goalNodeId),
      );
    }
    return strongest;
  }
}

/// Directed ALT (A*, landmarks, triangle inequality) heuristic.
class LandmarkHeuristic implements RoutingHeuristic {
  LandmarkHeuristic(IndoorGraph graph, {required List<String> landmarkNodeIds})
    : _landmarks = List.unmodifiable(landmarkNodeIds),
      _fromLandmark = {
        for (final id in landmarkNodeIds)
          id: _shortestDistances(graph, id, false),
      },
      _toLandmark = {
        for (final id in landmarkNodeIds)
          id: _shortestDistances(graph, id, true),
      } {
    for (final id in landmarkNodeIds) {
      graph.node(id);
    }
  }

  final List<String> _landmarks;
  final Map<String, Map<String, double>> _fromLandmark;
  final Map<String, Map<String, double>> _toLandmark;

  @override
  String get name => 'landmark-alt';

  @override
  double estimate(IndoorGraph graph, String fromNodeId, String goalNodeId) {
    var best = 0.0;
    for (final landmark in _landmarks) {
      final fromLandmark = _fromLandmark[landmark]!;
      final toLandmark = _toLandmark[landmark]!;
      final landmarkToGoal = fromLandmark[goalNodeId];
      final landmarkToFrom = fromLandmark[fromNodeId];
      if (landmarkToGoal != null && landmarkToFrom != null) {
        best = math.max(best, landmarkToGoal - landmarkToFrom);
      }
      final fromToLandmark = toLandmark[fromNodeId];
      final goalToLandmark = toLandmark[goalNodeId];
      if (fromToLandmark != null && goalToLandmark != null) {
        best = math.max(best, fromToLandmark - goalToLandmark);
      }
    }
    return best;
  }
}

class MlHeuristicWeights {
  const MlHeuristicWeights({
    required this.euclidean,
    required this.manhattan,
    required this.floorChanges,
    required this.bias,
    required this.calibrationScale,
  });

  final double euclidean;
  final double manhattan;
  final double floorChanges;
  final double bias;
  final double calibrationScale;
}

/// A tiny non-negative linear regression model suitable for offline training.
///
/// [calibrationScale] can be chosen from held-out exact routes to lower-bound
/// those routes. Production must retrain and recalibrate when map costs change.
class MlBasedHeuristic implements RoutingHeuristic {
  const MlBasedHeuristic({
    required this.weights,
    this.maximumWalkingSpeedMetersPerSecond = 1.6,
    this.minimumFloorTransitionSeconds = 12,
  });

  final MlHeuristicWeights weights;
  final double maximumWalkingSpeedMetersPerSecond;
  final double minimumFloorTransitionSeconds;

  @override
  String get name => 'ml-linear';

  @override
  double estimate(IndoorGraph graph, String fromNodeId, String goalNodeId) {
    if (fromNodeId == goalNodeId) return 0;
    final features = heuristicFeatures(
      graph,
      fromNodeId,
      goalNodeId,
      maximumWalkingSpeedMetersPerSecond: maximumWalkingSpeedMetersPerSecond,
      minimumFloorTransitionSeconds: minimumFloorTransitionSeconds,
    );
    final raw =
        weights.euclidean * features[0] +
        weights.manhattan * features[1] +
        weights.floorChanges * features[2] +
        weights.bias;
    return math.max(0, raw * weights.calibrationScale);
  }
}

List<double> heuristicFeatures(
  IndoorGraph graph,
  String fromNodeId,
  String goalNodeId, {
  double maximumWalkingSpeedMetersPerSecond = 1.6,
  double minimumFloorTransitionSeconds = 12,
}) {
  final from = graph.node(fromNodeId);
  final goal = graph.node(goalNodeId);
  return [
    from.planarDistanceTo(goal) / maximumWalkingSpeedMetersPerSecond,
    from.manhattanDistanceTo(goal) / maximumWalkingSpeedMetersPerSecond,
    (from.floor - goal.floor).abs() * minimumFloorTransitionSeconds,
  ];
}

Map<String, double> _shortestDistances(
  IndoorGraph graph,
  String start,
  bool reverse,
) {
  final distances = <String, double>{start: 0};
  final pending = _DistanceHeap()..add(_DistanceEntry(start, 0));
  while (pending.isNotEmpty) {
    final current = pending.removeFirst();
    if (current.distance > (distances[current.nodeId] ?? double.infinity)) {
      continue;
    }
    final edges = reverse
        ? graph.incoming(current.nodeId)
        : graph.outgoing(current.nodeId);
    for (final edge in edges) {
      final next = reverse ? edge.from : edge.to;
      final candidate = current.distance + edge.travelTimeSeconds;
      if (candidate < (distances[next] ?? double.infinity)) {
        distances[next] = candidate;
        pending.add(_DistanceEntry(next, candidate));
      }
    }
  }
  return distances;
}

class _DistanceEntry {
  const _DistanceEntry(this.nodeId, this.distance);

  final String nodeId;
  final double distance;
}

class _DistanceHeap {
  final List<_DistanceEntry> _items = [];

  bool get isNotEmpty => _items.isNotEmpty;

  void add(_DistanceEntry entry) {
    _items.add(entry);
    var index = _items.length - 1;
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_items[parent].distance <= _items[index].distance) break;
      final temporary = _items[parent];
      _items[parent] = _items[index];
      _items[index] = temporary;
      index = parent;
    }
  }

  _DistanceEntry removeFirst() {
    final result = _items.first;
    final last = _items.removeLast();
    if (_items.isEmpty) return result;
    _items[0] = last;
    var index = 0;
    while (true) {
      final left = index * 2 + 1;
      if (left >= _items.length) break;
      final right = left + 1;
      var child = left;
      if (right < _items.length &&
          _items[right].distance < _items[left].distance) {
        child = right;
      }
      if (_items[index].distance <= _items[child].distance) break;
      final temporary = _items[index];
      _items[index] = _items[child];
      _items[child] = temporary;
      index = child;
    }
    return result;
  }
}
