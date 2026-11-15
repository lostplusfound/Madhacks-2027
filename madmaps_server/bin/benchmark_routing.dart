// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:madmaps_server/src/routing/a_star.dart';
import 'package:madmaps_server/src/routing/heuristics.dart';
import 'package:madmaps_server/src/routing/ml_heuristic_trainer.dart';
import 'package:madmaps_server/src/routing/mock_indoor_map.dart';

void main() {
  final fixture = buildMockIndoorMap();
  final graph = fixture.graph;
  final random = math.Random(2027);
  final shuffledPairs = <(String, String)>[];
  for (var i = 0; i < 360; i++) {
    final from = fixture
        .classroomNodeIds[random.nextInt(fixture.classroomNodeIds.length)];
    var goal = fixture
        .classroomNodeIds[random.nextInt(fixture.classroomNodeIds.length)];
    while (goal == from) {
      goal = fixture
          .classroomNodeIds[random.nextInt(fixture.classroomNodeIds.length)];
    }
    shuffledPairs.add((from, goal));
  }

  const trainer = MlHeuristicTrainer();
  final training = trainer.exactExamples(graph, shuffledPairs.take(180));
  final calibration = trainer.exactExamples(
    graph,
    shuffledPairs.skip(180).take(90),
  );
  final testPairs = shuffledPairs.skip(270).toList(growable: false);
  final weights = trainer.train(
    graph,
    training,
    calibrationExamples: calibration,
  );
  final heuristics = <RoutingHeuristic>[
    const ZeroHeuristic(),
    const EuclideanTimeHeuristic(),
    const ManhattanTimeHeuristic(),
    const FloorAwareHeuristic(),
    LandmarkHeuristic(
      graph,
      landmarkNodeIds: const ['f1_h_0_0', 'f1_h_8_3', 'f4_h_0_3', 'f4_h_8_0'],
    ),
    MlBasedHeuristic(weights: weights),
  ];

  const router = AStarRouter();
  final baselines = <String, double>{};
  for (final (from, goal) in testPairs) {
    baselines['$from->$goal'] = router
        .findRoute(
          graph: graph,
          startNodeId: from,
          goalNodeId: goal,
          heuristic: const ZeroHeuristic(),
        )
        .travelTimeSeconds;
  }

  print(
    'Mock graph: ${graph.nodes.length} nodes, ${graph.edges.length} directed edges',
  );
  print(
    'Test routes: ${testPairs.length} (seed 2027; disjoint from ML training/calibration)',
  );
  print(
    'ML weights: e=${weights.euclidean.toStringAsFixed(3)}, '
    'm=${weights.manhattan.toStringAsFixed(3)}, '
    'floor=${weights.floorChanges.toStringAsFixed(3)}, '
    'bias=${weights.bias.toStringAsFixed(3)}, '
    'scale=${weights.calibrationScale.toStringAsFixed(3)}',
  );
  print(
    'heuristic       avg expanded   avg queued   optimal routes   elapsed us',
  );

  for (final heuristic in heuristics) {
    var expanded = 0;
    var queued = 0;
    var optimal = 0;
    final stopwatch = Stopwatch()..start();
    for (final (from, goal) in testPairs) {
      final route = router.findRoute(
        graph: graph,
        startNodeId: from,
        goalNodeId: goal,
        heuristic: heuristic,
      );
      expanded += route.expandedNodes;
      queued += route.queuedNodes;
      if ((route.travelTimeSeconds - baselines['$from->$goal']!).abs() < 1e-7) {
        optimal++;
      }
    }
    stopwatch.stop();
    print(
      '${heuristic.name.padRight(15)} '
      '${(expanded / testPairs.length).toStringAsFixed(1).padLeft(12)} '
      '${(queued / testPairs.length).toStringAsFixed(1).padLeft(12)} '
      '${'$optimal/${testPairs.length}'.padLeft(16)} '
      '${stopwatch.elapsedMicroseconds.toString().padLeft(12)}',
    );
  }
}
