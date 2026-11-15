import '../navigation/building_routing.dart';
import '../navigation/floor_data.dart';
import '../navigation/routing.dart';

class ManualRouteStep {
  const ManualRouteStep(this.legIndex, this.pointIndex, this.instruction);
  final int legIndex, pointIndex;
  final String instruction;
}

List<ManualRouteStep> manualRouteSteps(
  BuildingRoute route,
  Map<int, FloorGraph> floors,
  String destination,
  String Function(double) distanceLabel,
) {
  final steps = <ManualRouteStep>[];
  for (var legIndex = 0; legIndex < route.legs.length; legIndex++) {
    final leg = route.legs[legIndex];
    final graph = floors[leg.floor]!;
    var distance = 0.0;
    var action = 'Follow the highlighted path';
    var segmentStart = 0;
    for (var i = 1; i < leg.points.length; i++) {
      distance +=
          (leg.points[i] - leg.points[i - 1]).distance * graph.metersPerPixel;
      final turn = i + 1 < leg.points.length
          ? turnInstruction(
              leg.points[i] - leg.points[i - 1],
              leg.points[i + 1] - leg.points[i],
            )
          : null;
      if (turn != 'Continue') {
        steps.add(
          ManualRouteStep(
            legIndex,
            segmentStart,
            '${graph.floorLabel}: $action for about ${distanceLabel(distance)}.',
          ),
        );
        segmentStart = i;
        action = turn ?? 'Continue';
        distance = 0;
      }
    }
    if (leg.exit case final exit?) {
      steps.add(
        ManualRouteStep(
          legIndex,
          leg.points.length - 1,
          '${floorTransitionInstruction(exit)}.',
        ),
      );
    }
  }
  final last = route.legs.last;
  steps.add(
    ManualRouteStep(
      route.legs.length - 1,
      last.points.length - 1,
      'Reach the entrance to $destination.',
    ),
  );
  return steps;
}
