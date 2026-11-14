// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:madmaps_server/routing.dart';

void main() {
  const configurations = [
    _Configuration('small', 4, 9, 4, 2),
    _Configuration('medium', 4, 20, 12, 3),
    _Configuration('large', 5, 40, 24, 4),
    _Configuration('xlarge', 5, 60, 32, 5),
  ];
  print(
    'size       nodes   edges  preprocess ms  heuristic      mean exp  '
    'optimal  median batch ms',
  );
  for (var index = 0; index < configurations.length; index++) {
    final config = configurations[index];
    final fixture = buildScalableMockIndoorMap(
      floors: config.floors,
      xCount: config.xCount,
      zCount: config.zCount,
      classroomStride: config.classroomStride,
    );
    final graph = fixture.graph;
    final random = math.Random(2027 + index);
    final pairs = <(String, String)>[];
    while (pairs.length < 120) {
      final from = fixture
          .classroomNodeIds[random.nextInt(fixture.classroomNodeIds.length)];
      final goal = fixture
          .classroomNodeIds[random.nextInt(fixture.classroomNodeIds.length)];
      if (from != goal) pairs.add((from, goal));
    }

    const floorAware = FloorAwareHeuristic();
    final preprocessing = Stopwatch()..start();
    final landmark = LandmarkHeuristic(
      graph,
      landmarkNodeIds: [
        'f1_h_0_0',
        'f1_h_${config.xCount - 1}_${config.zCount - 1}',
        'f${config.floors}_h_0_${config.zCount - 1}',
        'f${config.floors}_h_${config.xCount - 1}_0',
      ],
    );
    preprocessing.stop();
    final hybrid = MaxHeuristic([floorAware, landmark]);
    final exact = _exactCosts(graph, pairs);

    for (final heuristic in [floorAware, landmark, hybrid]) {
      final result = _measure(graph, pairs, heuristic, exact);
      print(
        '${config.name.padRight(10)} '
        '${graph.nodes.length.toString().padLeft(6)} '
        '${graph.edges.length.toString().padLeft(7)} '
        '${(preprocessing.elapsedMicroseconds / 1000).toStringAsFixed(2).padLeft(14)} '
        '${heuristic.name.padRight(14)} '
        '${result.meanExpanded.toStringAsFixed(1).padLeft(9)} '
        '${'${result.optimal}/${pairs.length}'.padLeft(8)} '
        '${(result.medianMicroseconds / 1000).toStringAsFixed(2).padLeft(16)}',
      );
    }
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

({double meanExpanded, int optimal, int medianMicroseconds}) _measure(
  IndoorGraph graph,
  List<(String, String)> pairs,
  RoutingHeuristic heuristic,
  Map<String, double> exact,
) {
  const router = AStarRouter();
  var expansions = 0;
  var optimal = 0;
  for (final (from, goal) in pairs) {
    final route = router.findRoute(
      graph: graph,
      startNodeId: from,
      goalNodeId: goal,
      heuristic: heuristic,
    );
    expansions += route.expandedNodes;
    if ((route.travelTimeSeconds - exact['$from->$goal']!).abs() < 1e-7) {
      optimal++;
    }
  }

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
    meanExpanded: expansions / pairs.length,
    optimal: optimal,
    medianMicroseconds: timings[timings.length ~/ 2],
  );
}

class _Configuration {
  const _Configuration(
    this.name,
    this.floors,
    this.xCount,
    this.zCount,
    this.classroomStride,
  );

  final String name;
  final int floors;
  final int xCount;
  final int zCount;
  final int classroomStride;
}
