import 'dart:math' as math;

import 'a_star.dart';
import 'heuristics.dart';
import 'indoor_graph.dart';

class HeuristicTrainingExample {
  const HeuristicTrainingExample({
    required this.fromNodeId,
    required this.goalNodeId,
    required this.actualCostSeconds,
  });

  final String fromNodeId;
  final String goalNodeId;
  final double actualCostSeconds;
}

class MlHeuristicTrainer {
  const MlHeuristicTrainer();

  MlHeuristicWeights train(
    IndoorGraph graph,
    List<HeuristicTrainingExample> trainingExamples, {
    required List<HeuristicTrainingExample> calibrationExamples,
    int epochs = 1200,
    double learningRate = 0.015,
  }) {
    if (trainingExamples.isEmpty || calibrationExamples.isEmpty) {
      throw ArgumentError('Training and calibration examples cannot be empty.');
    }
    var weights = <double>[0.4, 0.4, 0.8, 0];
    final maximumCost = trainingExamples
        .map((example) => example.actualCostSeconds)
        .reduce(math.max);

    for (var epoch = 0; epoch < epochs; epoch++) {
      final gradients = <double>[0, 0, 0, 0];
      for (final example in trainingExamples) {
        final features = heuristicFeatures(
          graph,
          example.fromNodeId,
          example.goalNodeId,
        );
        final normalized = [
          ...features.map((value) => value / maximumCost),
          1.0,
        ];
        final target = example.actualCostSeconds / maximumCost;
        final prediction = _dot(weights, normalized);
        final error = prediction - target;
        for (var i = 0; i < gradients.length; i++) {
          gradients[i] += 2 * error * normalized[i] / trainingExamples.length;
        }
      }
      for (var i = 0; i < weights.length; i++) {
        weights[i] = math.max(0, weights[i] - learningRate * gradients[i]);
      }
    }

    // The bias was trained against normalized targets and must be unscaled.
    var result = MlHeuristicWeights(
      euclidean: weights[0],
      manhattan: weights[1],
      floorChanges: weights[2],
      bias: weights[3] * maximumCost,
      calibrationScale: 1,
    );
    final uncalibrated = MlBasedHeuristic(weights: result);
    var scale = 1.0;
    for (final example in calibrationExamples) {
      final estimate = uncalibrated.estimate(
        graph,
        example.fromNodeId,
        example.goalNodeId,
      );
      if (estimate > 0) {
        scale = math.min(scale, example.actualCostSeconds / estimate);
      }
    }
    result = MlHeuristicWeights(
      euclidean: result.euclidean,
      manhattan: result.manhattan,
      floorChanges: result.floorChanges,
      bias: result.bias,
      calibrationScale: math.max(0, math.min(1, scale)) * 0.999999,
    );
    return result;
  }

  List<HeuristicTrainingExample> exactExamples(
    IndoorGraph graph,
    Iterable<(String, String)> pairs,
  ) {
    const router = AStarRouter();
    return [
      for (final (from, goal) in pairs)
        if (from != goal)
          _example(
            router.findRoute(
              graph: graph,
              startNodeId: from,
              goalNodeId: goal,
              heuristic: const ZeroHeuristic(),
            ),
            from,
            goal,
          ),
    ];
  }

  HeuristicTrainingExample _example(
    RouteResult route,
    String from,
    String goal,
  ) {
    if (!route.found) {
      throw StateError('Cannot train on unreachable pair $from -> $goal.');
    }
    return HeuristicTrainingExample(
      fromNodeId: from,
      goalNodeId: goal,
      actualCostSeconds: route.travelTimeSeconds,
    );
  }

  double _dot(List<double> left, List<double> right) {
    var result = 0.0;
    for (var i = 0; i < left.length; i++) {
      result += left[i] * right[i];
    }
    return result;
  }
}
