import 'package:madmaps_server/src/endpoints/data_safety_service.dart';
import 'package:test/test.dart';

void main() {
  const safety = DataSafetyService();
  const wall = ExclusionPolygon(
    id: 'wall',
    floorId: '1',
    vertices: [
      FloorPoint(4, 2),
      FloorPoint(6, 2),
      FloorPoint(6, 8),
      FloorPoint(4, 8),
    ],
  );
  void point(FloorPoint p, {String floor = '1'}) => safety.validatePoint(
    entityId: 'node',
    floorId: floor,
    point: p,
    floorWidth: 10,
    floorHeight: 10,
    metersPerUnit: 1,
    obstacles: [wall],
  );
  void segment(FloorPoint a, FloorPoint b, {String floor = '1'}) =>
      safety.validateSegment(
        entityId: 'edge',
        floorId: floor,
        start: a,
        end: b,
        obstacles: [wall],
      );
  test('rejects points inside or touching a wall', () {
    expect(
      () => point(const FloorPoint(5, 5)),
      throwsA(isA<DataSafetyViolation>()),
    );
    expect(
      () => point(const FloorPoint(4, 5)),
      throwsA(isA<DataSafetyViolation>()),
    );
    expect(() => point(const FloorPoint(3, 5)), returnsNormally);
    expect(() => point(const FloorPoint(5, 5), floor: '2'), returnsNormally);
  });
  test('rejects routes crossing or touching walls', () {
    expect(
      () => segment(const FloorPoint(2, 5), const FloorPoint(8, 5)),
      throwsA(isA<DataSafetyViolation>()),
    );
    expect(
      () => segment(const FloorPoint(2, 2), const FloorPoint(4, 2)),
      throwsA(isA<DataSafetyViolation>()),
    );
    expect(
      () => segment(const FloorPoint(2, 1), const FloorPoint(8, 1)),
      returnsNormally,
    );
    expect(
      () => segment(const FloorPoint(2, 5), const FloorPoint(8, 5), floor: '2'),
      returnsNormally,
    );
  });
  test('rejects malformed polygons', () {
    const invalid = ExclusionPolygon(
      id: 'invalid',
      floorId: '1',
      vertices: [
        FloorPoint(1, 1),
        FloorPoint(9, 9),
        FloorPoint(1, 9),
        FloorPoint(9, 1),
      ],
    );
    expect(
      () => safety.validateFloor(
        floorId: '1',
        width: 10,
        height: 10,
        metersPerUnit: 1,
        obstacles: [invalid],
      ),
      throwsA(isA<DataSafetyViolation>()),
    );
  });
}
