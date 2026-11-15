import 'dart:math' as math;

/// A point in a floor's local 2D coordinate system.
class FloorPoint {
  const FloorPoint(this.x, this.y);

  final double x;
  final double y;
}

/// An area that navigation geometry must not enter, such as a wall or column.
class ExclusionPolygon {
  const ExclusionPolygon({
    required this.id,
    required this.floorId,
    required this.vertices,
  });

  final String id;
  final String floorId;
  final List<FloorPoint> vertices;
}

/// A deterministic validation failure suitable for turning into an API error.
class DataSafetyViolation implements Exception {
  const DataSafetyViolation({
    required this.code,
    required this.message,
    this.entityId,
    this.obstacleId,
  });

  final String code;
  final String message;
  final String? entityId;
  final String? obstacleId;

  @override
  String toString() => message;
}

/// Validates floor geometry before it is persisted or used for routing.
///
/// The service intentionally rejects unsafe geometry instead of silently
/// moving it. Automatic snapping can put a point on the wrong side of a wall
/// and needs map-specific semantics (doors, corridors, and room boundaries).
class DataSafetyService {
  const DataSafetyService({this.clearanceMeters = 0});

  /// Optional physical clearance from floor edges and exclusion polygons.
  final double clearanceMeters;

  void validateFloor({
    required String floorId,
    required double width,
    required double height,
    required double metersPerUnit,
    Iterable<ExclusionPolygon> obstacles = const [],
  }) {
    if (!width.isFinite ||
        width <= 0 ||
        !height.isFinite ||
        height <= 0 ||
        !metersPerUnit.isFinite ||
        metersPerUnit <= 0) {
      throw const DataSafetyViolation(
        code: 'invalid_floor_geometry',
        message: 'Floor dimensions and scale must be positive finite values.',
      );
    }
    if (!clearanceMeters.isFinite || clearanceMeters < 0) {
      throw const DataSafetyViolation(
        code: 'invalid_clearance',
        message: 'Geometry clearance must be a non-negative finite value.',
      );
    }

    for (final obstacle in obstacles.where(
      (obstacle) => obstacle.floorId == floorId,
    )) {
      _validatePolygon(obstacle, width: width, height: height);
    }
  }

  void validatePoint({
    required String entityId,
    required String floorId,
    required FloorPoint point,
    required double floorWidth,
    required double floorHeight,
    required double metersPerUnit,
    Iterable<ExclusionPolygon> obstacles = const [],
  }) {
    validateFloor(
      floorId: floorId,
      width: floorWidth,
      height: floorHeight,
      metersPerUnit: metersPerUnit,
      obstacles: obstacles,
    );
    if (!point.x.isFinite || !point.y.isFinite) {
      throw DataSafetyViolation(
        code: 'invalid_point',
        message: 'Point $entityId must have finite coordinates.',
        entityId: entityId,
      );
    }

    final clearance = clearanceMeters / metersPerUnit;
    if (point.x <= clearance ||
        point.y <= clearance ||
        point.x >= floorWidth - clearance ||
        point.y >= floorHeight - clearance) {
      throw DataSafetyViolation(
        code: 'point_outside_safe_floor_area',
        message: 'Point $entityId touches or crosses the floor perimeter.',
        entityId: entityId,
      );
    }

    for (final obstacle in obstacles.where(
      (obstacle) => obstacle.floorId == floorId,
    )) {
      if (_containsOrTouches(obstacle.vertices, point) ||
          _distanceToPolygon(obstacle.vertices, point) <= clearance) {
        throw DataSafetyViolation(
          code: 'point_in_exclusion_area',
          message: 'Point $entityId is inside or too close to ${obstacle.id}.',
          entityId: entityId,
          obstacleId: obstacle.id,
        );
      }
    }
  }

  void validateSegment({
    required String entityId,
    required String floorId,
    required FloorPoint start,
    required FloorPoint end,
    Iterable<ExclusionPolygon> obstacles = const [],
  }) {
    if (!_isFinite(start) || !_isFinite(end)) {
      throw DataSafetyViolation(
        code: 'invalid_segment',
        message: 'Segment $entityId must have finite coordinates.',
        entityId: entityId,
      );
    }
    if (_samePoint(start, end)) {
      throw DataSafetyViolation(
        code: 'zero_length_segment',
        message: 'Segment $entityId has zero length.',
        entityId: entityId,
      );
    }

    for (final obstacle in obstacles.where(
      (obstacle) => obstacle.floorId == floorId,
    )) {
      if (_containsOrTouches(obstacle.vertices, start) ||
          _containsOrTouches(obstacle.vertices, end) ||
          _segmentCrossesPolygon(start, end, obstacle.vertices)) {
        throw DataSafetyViolation(
          code: 'segment_crosses_exclusion_area',
          message: 'Segment $entityId crosses ${obstacle.id}.',
          entityId: entityId,
          obstacleId: obstacle.id,
        );
      }
    }
  }

  void _validatePolygon(
    ExclusionPolygon polygon, {
    required double width,
    required double height,
  }) {
    if (polygon.vertices.length < 3) {
      throw DataSafetyViolation(
        code: 'invalid_exclusion_polygon',
        message: 'Exclusion polygon ${polygon.id} needs at least 3 vertices.',
        obstacleId: polygon.id,
      );
    }
    for (final vertex in polygon.vertices) {
      if (!_isFinite(vertex) ||
          vertex.x < 0 ||
          vertex.y < 0 ||
          vertex.x > width ||
          vertex.y > height) {
        throw DataSafetyViolation(
          code: 'invalid_exclusion_polygon',
          message: 'Exclusion polygon ${polygon.id} leaves its floor bounds.',
          obstacleId: polygon.id,
        );
      }
    }
    if (_signedArea(polygon.vertices).abs() <= _epsilon) {
      throw DataSafetyViolation(
        code: 'invalid_exclusion_polygon',
        message: 'Exclusion polygon ${polygon.id} has no area.',
        obstacleId: polygon.id,
      );
    }
    if (_selfIntersects(polygon.vertices)) {
      throw DataSafetyViolation(
        code: 'invalid_exclusion_polygon',
        message: 'Exclusion polygon ${polygon.id} intersects itself.',
        obstacleId: polygon.id,
      );
    }
  }
}

const _epsilon = 1e-9;

bool _isFinite(FloorPoint point) => point.x.isFinite && point.y.isFinite;

bool _samePoint(FloorPoint a, FloorPoint b) =>
    (a.x - b.x).abs() <= _epsilon && (a.y - b.y).abs() <= _epsilon;

double _cross(FloorPoint a, FloorPoint b, FloorPoint c) =>
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);

bool _pointOnSegment(FloorPoint point, FloorPoint a, FloorPoint b) {
  if (_cross(a, b, point).abs() > _epsilon) return false;
  return point.x >= math.min(a.x, b.x) - _epsilon &&
      point.x <= math.max(a.x, b.x) + _epsilon &&
      point.y >= math.min(a.y, b.y) - _epsilon &&
      point.y <= math.max(a.y, b.y) + _epsilon;
}

bool _segmentsIntersect(
  FloorPoint a,
  FloorPoint b,
  FloorPoint c,
  FloorPoint d,
) {
  final abC = _cross(a, b, c);
  final abD = _cross(a, b, d);
  final cdA = _cross(c, d, a);
  final cdB = _cross(c, d, b);
  if (((abC > _epsilon && abD < -_epsilon) ||
          (abC < -_epsilon && abD > _epsilon)) &&
      ((cdA > _epsilon && cdB < -_epsilon) ||
          (cdA < -_epsilon && cdB > _epsilon))) {
    return true;
  }
  return (abC.abs() <= _epsilon && _pointOnSegment(c, a, b)) ||
      (abD.abs() <= _epsilon && _pointOnSegment(d, a, b)) ||
      (cdA.abs() <= _epsilon && _pointOnSegment(a, c, d)) ||
      (cdB.abs() <= _epsilon && _pointOnSegment(b, c, d));
}

bool _containsOrTouches(List<FloorPoint> vertices, FloorPoint point) {
  var inside = false;
  for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
    final a = vertices[j];
    final b = vertices[i];
    if (_pointOnSegment(point, a, b)) return true;
    final crossesRay = (a.y > point.y) != (b.y > point.y);
    if (crossesRay &&
        point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

double _distanceToPolygon(List<FloorPoint> vertices, FloorPoint point) {
  var result = double.infinity;
  for (var i = 0; i < vertices.length; i++) {
    result = math.min(
      result,
      _distanceToSegment(
        point,
        vertices[i],
        vertices[(i + 1) % vertices.length],
      ),
    );
  }
  return result;
}

double _distanceToSegment(FloorPoint point, FloorPoint a, FloorPoint b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared <= _epsilon) {
    return math.sqrt(math.pow(point.x - a.x, 2) + math.pow(point.y - a.y, 2));
  }
  final projection =
      ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared;
  final t = projection.clamp(0.0, 1.0);
  final nearestX = a.x + t * dx;
  final nearestY = a.y + t * dy;
  return math.sqrt(
    math.pow(point.x - nearestX, 2) + math.pow(point.y - nearestY, 2),
  );
}

bool _segmentCrossesPolygon(
  FloorPoint start,
  FloorPoint end,
  List<FloorPoint> vertices,
) {
  for (var i = 0; i < vertices.length; i++) {
    if (_segmentsIntersect(
      start,
      end,
      vertices[i],
      vertices[(i + 1) % vertices.length],
    )) {
      return true;
    }
  }
  final midpoint = FloorPoint((start.x + end.x) / 2, (start.y + end.y) / 2);
  return _containsOrTouches(vertices, midpoint);
}

double _signedArea(List<FloorPoint> vertices) {
  var area = 0.0;
  for (var i = 0; i < vertices.length; i++) {
    final current = vertices[i];
    final next = vertices[(i + 1) % vertices.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area / 2;
}

bool _selfIntersects(List<FloorPoint> vertices) {
  for (var i = 0; i < vertices.length; i++) {
    final a = vertices[i];
    final b = vertices[(i + 1) % vertices.length];
    for (var j = i + 1; j < vertices.length; j++) {
      final adjacent =
          j == i ||
          (j + 1) % vertices.length == i ||
          (i + 1) % vertices.length == j;
      if (adjacent) continue;
      final c = vertices[j];
      final d = vertices[(j + 1) % vertices.length];
      if (_segmentsIntersect(a, b, c, d)) return true;
    }
  }
  return false;
}
