// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:madmaps_server/routing.dart';

void main() {
  final fixture = buildIrregularCrowdsourcedMock();
  final graph = fixture.graph;
  final random = math.Random(4040);
  final pairs = <(String, String)>[];
  while (pairs.length < 300) {
    final from = fixture
        .classroomNodeIds[random.nextInt(fixture.classroomNodeIds.length)];
    final goal = fixture
        .classroomNodeIds[random.nextInt(fixture.classroomNodeIds.length)];
    if (from != goal) pairs.add((from, goal));
  }

  const rectilinearFloor = FloorAwareHeuristic();
  const safeFloor = UncertainCoordinateFloorHeuristic();
  final preprocessing = Stopwatch()..start();
  final landmark = LandmarkHeuristic(
    graph,
    landmarkNodeIds: const [
      'cs_f1_h_0_0',
      'cs_f1_h_13_8',
      'cs_f4_h_0_8',
      'cs_f4_h_13_0',
    ],
  );
  preprocessing.stop();
  final hybrid = MaxHeuristic([safeFloor, landmark]);
  final exact = _exactCosts(graph, pairs);

  print(
    'Irregular crowdsourced fixture: ${graph.nodes.length} nodes, '
    '${graph.edges.length} directed edges, ${fixture.classroomNodeIds.length} rooms',
  );
  print(
    'Landmark preprocessing: '
    '${(preprocessing.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms',
  );
  print(
    'heuristic          mean exp   p95 exp   tightness   optimal   median 300-route ms',
  );
  for (final heuristic in [rectilinearFloor, safeFloor, landmark, hybrid]) {
    final measurement = _measure(graph, pairs, heuristic, exact);
    print(
      '${heuristic.name.padRight(18)} '
      '${measurement.meanExpanded.toStringAsFixed(1).padLeft(8)} '
      '${measurement.p95Expanded.toString().padLeft(9)} '
      '${measurement.tightness.toStringAsFixed(3).padLeft(11)} '
      '${'${measurement.optimal}/${pairs.length}'.padLeft(9)} '
      '${(measurement.medianMicroseconds / 1000).toStringAsFixed(2).padLeft(19)}',
    );
  }
}

Map<String, double> _exactCosts(
  IndoorGraph graph,
  List<(String, String)> pairs,
) {
  const router = AStarRouter();
  return {
    for (final (from, goal) in pairs)
      '$from->$goal': router
          .findRoute(
            graph: graph,
            startNodeId: from,
            goalNodeId: goal,
            heuristic: const ZeroHeuristic(),
          )
          .travelTimeSeconds,
  };
}

({
  double meanExpanded,
  int p95Expanded,
  double tightness,
  int optimal,
  int medianMicroseconds,
})
_measure(
  IndoorGraph graph,
  List<(String, String)> pairs,
  RoutingHeuristic heuristic,
  Map<String, double> exact,
) {
  const router = AStarRouter();
  final expansions = <int>[];
  var tightness = 0.0;
  var optimal = 0;
  for (final (from, goal) in pairs) {
    final route = router.findRoute(
      graph: graph,
      startNodeId: from,
      goalNodeId: goal,
      heuristic: heuristic,
    );
    final exactCost = exact['$from->$goal']!;
    expansions.add(route.expandedNodes);
    tightness += heuristic.estimate(graph, from, goal) / exactCost;
    if ((route.travelTimeSeconds - exactCost).abs() < 1e-7) optimal++;
  }
  expansions.sort();
  final timings = <int>[];
  for (var run = 0; run < 5; run++) {
    final stopwatch = Stopwatch()..start();
    for (final (from, goal) in pairs) {
      router.findRoute(
        graph: graph,
        startNodeId: from,
        goalNodeId: goal,
        heuristic: heuristic,
      );
    }
    stopwatch.stop();
    timings.add(stopwatch.elapsedMicroseconds);
  }
  timings.sort();
  return (
    meanExpanded: expansions.reduce((a, b) => a + b) / pairs.length,
    p95Expanded: expansions[(expansions.length * 0.95).floor()],
    tightness: tightness / pairs.length,
    optimal: optimal,
    medianMicroseconds: timings[timings.length ~/ 2],
  );
}
