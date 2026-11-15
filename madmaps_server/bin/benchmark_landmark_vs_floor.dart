// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:madmaps_server/routing.dart';

void main() {
  final fixture = buildMockIndoorMap();
  final graph = fixture.graph;
  final pairs = <(String, String)>[
    for (final from in fixture.classroomNodeIds)
      for (final goal in fixture.classroomNodeIds)
        if (from != goal) (from, goal),
  ];

  const floorAware = FloorAwareHeuristic();
  final preprocessing = Stopwatch()..start();
  final landmark = LandmarkHeuristic(
    graph,
    landmarkNodeIds: const [
      'f1_h_0_0',
      'f1_h_8_3',
      'f4_h_0_3',
      'f4_h_8_0',
    ],
  );
  preprocessing.stop();
  final hybrid = MaxHeuristic([floorAware, landmark]);

  const router = AStarRouter();
  final scenarios = <String, List<(String, String)>>{
    'all routes': pairs,
    'same floor': [
      for (final pair in pairs)
        if (graph.node(pair.$1).floor == graph.node(pair.$2).floor) pair,
    ],
    'one floor apart': [
      for (final pair in pairs)
        if ((graph.node(pair.$1).floor - graph.node(pair.$2).floor).abs() == 1)
          pair,
    ],
    '2+ floors apart': [
      for (final pair in pairs)
        if ((graph.node(pair.$1).floor - graph.node(pair.$2).floor).abs() >= 2)
          pair,
    ],
  };

  print(
    'Exhaustive classroom benchmark: ${graph.nodes.length} nodes, '
    '${graph.edges.length} directed edges, ${pairs.length} ordered routes',
  );
  print(
    'Landmark preprocessing: ${preprocessing.elapsedMicroseconds} us; '
    '4 landmarks; about ${4 * 2 * graph.nodes.length} stored distances',
  );

  for (final scenario in scenarios.entries) {
    final baselineCosts = <String, double>{};
    for (final (from, goal) in scenario.value) {
      baselineCosts['$from->$goal'] = router
          .findRoute(
            graph: graph,
            startNodeId: from,
            goalNodeId: goal,
            heuristic: const ZeroHeuristic(),
          )
          .travelTimeSeconds;
    }

    // Warm the shared search code before timing each heuristic.
    for (final (from, goal) in scenario.value.take(50)) {
      router.findRoute(
        graph: graph,
        startNodeId: from,
        goalNodeId: goal,
        heuristic: floorAware,
      );
      router.findRoute(
        graph: graph,
        startNodeId: from,
        goalNodeId: goal,
        heuristic: landmark,
      );
    }

    final floorResult = _measure(
      graph,
      scenario.value,
      floorAware,
      baselineCosts,
    );
    final landmarkResult = _measure(
      graph,
      scenario.value,
      landmark,
      baselineCosts,
    );
    final hybridResult = _measure(
      graph,
      scenario.value,
      hybrid,
      baselineCosts,
    );
    final headToHead = _headToHead(graph, scenario.value, floorAware, landmark);

    print('\n${scenario.key} (${scenario.value.length})');
    print(
      'heuristic       mean exp   p50   p95   mean queued   tightness   '
      'optimal   elapsed us',
    );
    print(floorResult.row);
    print(landmarkResult.row);
    print(hybridResult.row);
    print(
      'expansion wins: floor-aware ${headToHead.floorWins}, '
      'landmark ${headToHead.landmarkWins}, ties ${headToHead.ties}; '
      'landmark reduction ${_percentReduction(floorResult.meanExpanded, landmarkResult.meanExpanded)}; '
      'hybrid vs landmark ${_percentReduction(landmarkResult.meanExpanded, hybridResult.meanExpanded)}',
    );
  }
}

_Measurement _measure(
  IndoorGraph graph,
  List<(String, String)> pairs,
  RoutingHeuristic heuristic,
  Map<String, double> baselineCosts,
) {
  const router = AStarRouter();
  final expansions = <int>[];
  var queued = 0;
  var optimal = 0;
  var tightness = 0.0;
  for (final (from, goal) in pairs) {
    final route = router.findRoute(
      graph: graph,
      startNodeId: from,
      goalNodeId: goal,
      heuristic: heuristic,
    );
    final exact = baselineCosts['$from->$goal']!;
    expansions.add(route.expandedNodes);
    queued += route.queuedNodes;
    tightness += heuristic.estimate(graph, from, goal) / exact;
    if ((route.travelTimeSeconds - exact).abs() < 1e-7) optimal++;
  }
  expansions.sort();
  final timings = <int>[];
  for (var run = 0; run < 7; run++) {
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
  return _Measurement(
    name: heuristic.name,
    meanExpanded:
        expansions.reduce((left, right) => left + right) / pairs.length,
    medianExpanded: _percentile(expansions, 0.50),
    p95Expanded: _percentile(expansions, 0.95),
    meanQueued: queued / pairs.length,
    meanTightness: tightness / pairs.length,
    optimal: optimal,
    routes: pairs.length,
    elapsedMicroseconds: timings[timings.length ~/ 2],
  );
}

({int floorWins, int landmarkWins, int ties}) _headToHead(
  IndoorGraph graph,
  List<(String, String)> pairs,
  RoutingHeuristic floorAware,
  RoutingHeuristic landmark,
) {
  const router = AStarRouter();
  var floorWins = 0;
  var landmarkWins = 0;
  var ties = 0;
  for (final (from, goal) in pairs) {
    final floorExpanded = router
        .findRoute(
          graph: graph,
          startNodeId: from,
          goalNodeId: goal,
          heuristic: floorAware,
        )
        .expandedNodes;
    final landmarkExpanded = router
        .findRoute(
          graph: graph,
          startNodeId: from,
          goalNodeId: goal,
          heuristic: landmark,
        )
        .expandedNodes;
    if (floorExpanded < landmarkExpanded) {
      floorWins++;
    } else if (landmarkExpanded < floorExpanded) {
      landmarkWins++;
    } else {
      ties++;
    }
  }
  return (floorWins: floorWins, landmarkWins: landmarkWins, ties: ties);
}

int _percentile(List<int> sorted, double percentile) {
  final index = math.min(
    sorted.length - 1,
    (sorted.length * percentile).floor(),
  );
  return sorted[index];
}

String _percentReduction(double baseline, double candidate) =>
    '${((baseline - candidate) / baseline * 100).toStringAsFixed(1)}%';

class _Measurement {
  const _Measurement({
    required this.name,
    required this.meanExpanded,
    required this.medianExpanded,
    required this.p95Expanded,
    required this.meanQueued,
    required this.meanTightness,
    required this.optimal,
    required this.routes,
    required this.elapsedMicroseconds,
  });

  final String name;
  final double meanExpanded;
  final int medianExpanded;
  final int p95Expanded;
  final double meanQueued;
  final double meanTightness;
  final int optimal;
  final int routes;
  final int elapsedMicroseconds;

  String get row =>
      '${name.padRight(15)} '
      '${meanExpanded.toStringAsFixed(1).padLeft(8)} '
      '${medianExpanded.toString().padLeft(5)} '
      '${p95Expanded.toString().padLeft(5)} '
      '${meanQueued.toStringAsFixed(1).padLeft(13)} '
      '${meanTightness.toStringAsFixed(3).padLeft(11)} '
      '${'$optimal/$routes'.padLeft(9)} '
      '${elapsedMicroseconds.toString().padLeft(12)}';
}
