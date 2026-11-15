import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps_client/madmaps_client.dart' as api;
import 'package:madmaps/features/navigation/building_routing.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/shell/manual_route_steps.dart';

void main() {
  final floors = {
    for (final f in [0, 1])
      f: FloorGraph({}, [], [], floor: f, metersPerPixel: .1),
  };
  test('manual steps retain turn positions, floor transitions and arrival', () {
    final stairs = api.FloorConnector(
      connectorId: 'up',
      buildingId: 'hall',
      label: 'Stairs',
      fromGraphId: 'lower',
      fromFloor: 0,
      fromNodeId: 'a',
      toGraphId: 'upper',
      toFloor: 1,
      toNodeId: 'b',
      type: api.EdgeType.stairs,
      seconds: 15,
      bidirectional: true,
      active: true,
    );
    final route = BuildingRoute([
      BuildingLeg(
        0,
        [Offset.zero, const Offset(100, 0), const Offset(100, 100)],
        'a',
        20,
        stairs,
      ),
      BuildingLeg(
        1,
        [const Offset(20, 20), const Offset(80, 20)],
        'end',
        6,
        null,
      ),
    ], 45);
    final steps = manualRouteSteps(
      route,
      floors,
      'Room 100',
      (m) => '${m.round()} m',
    );
    expect(steps.first.pointIndex, 0);
    expect(steps.first.instruction, contains('10 m'));
    expect(steps[1].pointIndex, 1);
    expect(steps[1].instruction.toLowerCase(), contains('turn'));
    final transition = steps.singleWhere(
      (step) => step.instruction.contains('Take the stairs'),
    );
    expect(transition.legIndex, 0);
    expect(transition.pointIndex, 2);
    expect(steps[steps.indexOf(transition) + 1].legIndex, 1);
    expect(steps.last.instruction, 'Reach the entrance to Room 100.');
    expect(steps.last.pointIndex, 1);
  });
  test('identical start and destination produce a single arrival step', () {
    final route = BuildingRoute([
      BuildingLeg(1, [const Offset(20, 20)], 'same', 0, null),
    ], 0);
    final steps = manualRouteSteps(
      route,
      floors,
      'Room 100',
      (m) => '${m.round()} m',
    );
    expect(steps, hasLength(1));
    expect(steps.single.pointIndex, 0);
    expect(steps.single.legIndex, 0);
  });
}
