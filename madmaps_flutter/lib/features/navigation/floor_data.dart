import 'dart:convert';
import 'dart:ui' show Path;
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../localization/map_data.dart';

const floorImageSize = Size(1632, 1056);

class FloorCalibration {
  FloorCalibration(this.origin, this.imageOrigin, this.a, this.b);
  final Offset origin, imageOrigin;
  final double a, b;
  double get scale => math.sqrt(a * a + b * b);
  factory FloorCalibration.pair(Offset p, Offset q, Offset u, Offset v) {
    final d = q - p, e = v - u;
    if (d.distance < 2 || e.distance < 1) {
      throw StateError(
        'Choose anchors at least 2 meters apart and distinct image points.',
      );
    }
    final n = d.dx * d.dx + d.dy * d.dy;
    return FloorCalibration(
      p,
      u,
      (e.dx * d.dx + e.dy * d.dy) / n,
      (e.dy * d.dx - e.dx * d.dy) / n,
    );
  }
  Offset toImage(Offset p) {
    final d = p - origin;
    return imageOrigin + Offset(a * d.dx - b * d.dy, b * d.dx + a * d.dy);
  }

  Offset toMap(Offset p) {
    final d = p - imageOrigin, n = a * a + b * b;
    return origin +
        Offset((a * d.dx + b * d.dy) / n, (-b * d.dx + a * d.dy) / n);
  }
}

/// Optional local additions; the original AR map frame never changes.
class FloorSetup {
  bool enabled = false;
  int floorNumber = 1;
  final Map<String, Offset> anchorPoints = {}, nodePoints = {};
  final Map<String, String> locationNodes = {}, anchorNodes = {};
  final List<String> calibrationIds = [];
  FloorCalibration? calibration(AnchorMap map) {
    if (!enabled || calibrationIds.length != 2) return null;
    final anchors = <SavedAnchor>[];
    for (final id in calibrationIds) {
      final matches = map.anchors.where((a) => a.id == id);
      if (matches.isEmpty || !anchorPoints.containsKey(id)) return null;
      anchors.add(matches.first);
    }
    try {
      return FloorCalibration.pair(
        anchorPosition(anchors[0]),
        anchorPosition(anchors[1]),
        anchorPoints[anchors[0].id]!,
        anchorPoints[anchors[1].id]!,
      );
    } on StateError {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'floorNumber': floorNumber,
    'anchors': anchorPoints.map((k, v) => MapEntry(k, [v.dx, v.dy])),
    'nodes': nodePoints.map((k, v) => MapEntry(k, [v.dx, v.dy])),
    'locations': locationNodes,
    'anchorNodes': anchorNodes,
    'calibration': calibrationIds,
  };
  static FloorSetup fromJson(Map<String, dynamic>? j) {
    final s = FloorSetup();
    if (j == null) return s;
    s.enabled = j['enabled'] == true;
    s.floorNumber = j['floorNumber'] as int? ?? 1;
    for (final entry in [
      ('anchors', s.anchorPoints),
      ('nodes', s.nodePoints),
    ]) {
      for (final e in (j[entry.$1] as Map? ?? {}).entries) {
        final p = e.value as List;
        final point = Offset(
          (p[0] as num).toDouble(),
          (p[1] as num).toDouble(),
        );
        if (!point.dx.isFinite || !point.dy.isFinite) {
          throw const FormatException('Invalid map point');
        }
        entry.$2[e.key as String] = point;
      }
    }
    s.locationNodes.addAll(
      Map<String, String>.from(j['locations'] as Map? ?? {}),
    );
    s.anchorNodes.addAll(
      Map<String, String>.from(j['anchorNodes'] as Map? ?? {}),
    );
    s.calibrationIds.addAll(List<String>.from(j['calibration'] as List? ?? []));
    return s;
  }
}

Offset anchorPosition(SavedAnchor a) =>
    Offset(a.pose.entry(0, 3), a.pose.entry(2, 3));

class FloorNode {
  FloorNode(this.id, this.point, this.kind, {this.status = 'draft'});
  final String id, kind, status;
  final Offset point;
}

class FloorEdge {
  FloorEdge(
    this.from,
    this.to,
    this.cost,
    this.bidirectional, {
    this.status = 'draft',
    this.type = 'walk',
  });
  final String from, to, status, type;
  final double cost;
  final bool bidirectional;
}

class FloorLocation {
  FloorLocation(
    this.id,
    this.label,
    this.aliases,
    this.node, {
    this.floor = 1,
    this.buildingName = 'Morgridge Hall',
    this.placeMapId,
    this.mapFloorLabel,
  });
  final String buildingName;
  final String? placeMapId, mapFloorLabel;
  final int floor;
  String get floorLabel =>
      mapFloorLabel ?? (floor == 0 ? 'Basement' : 'Floor $floor');
  final String id, label, aliases;
  final String? node;
}

/// RFC-style quoted fields, including commas, escaped quotes and newlines.
List<List<String>> readCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[], field = '', quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '"') {
      if (quoted && i + 1 < text.length && text[i + 1] == '"') {
        field += '"';
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (!quoted && (c == ',' || c == '\n')) {
      row.add(field.replaceAll('\r', ''));
      field = '';
      if (c == '\n') {
        if (row.any((v) => v.isNotEmpty)) rows.add(row);
        row = [];
      }
    } else {
      field += c;
    }
  }
  if (quoted) throw const FormatException('Unclosed CSV quote');
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field);
    rows.add(row);
  }
  return rows;
}

class FloorGraph {
  FloorGraph(
    this.nodes,
    this.edges,
    this.locations, {
    this.floor = 1,
    this.imageSize = floorImageSize,
    this.rooms = const [],
    this.barriers = const [],
    this.graphId = '',
    this.version = 1,
    this.metersPerPixel = .1,
  });
  final int floor;
  final String graphId;
  final int version;

  /// Floor-plan estimate until an AR capture provides a measured scale.
  final double metersPerPixel;
  final List<List<Offset>> barriers;
  final Size imageSize;
  final List<RoomPolygon> rooms;
  String get imageAsset =>
      floor == 1 ? 'assets/floor1/plan.png' : 'assets/maps/floor$floor.png';
  String get floorLabel => floor == 0 ? 'Basement' : 'Floor $floor';
  FloorGraph withRooms(List<RoomPolygon> shapes) => FloorGraph(
    nodes,
    edges,
    locations,
    floor: floor,
    imageSize: imageSize,
    rooms: shapes,
    barriers: barriers,
    graphId: graphId,
    version: version,
    metersPerPixel: metersPerPixel,
  );
  FloorLocation? roomAt(Offset point) {
    final hits = rooms.where((r) => r.path.contains(point)).toList()
      ..sort((a, b) => a.area.compareTo(b.area));
    for (final room in hits) {
      for (final location in locations) {
        if (location.id == room.locationId) return location;
      }
    }
    return null;
  }

  Future<FloorGraph> loadRooms() async {
    final data =
        jsonDecode(await rootBundle.loadString('assets/maps/room_shapes.json'))
            as Map<String, dynamic>;
    if (data['version'] != 1)
      throw const FormatException('Unsupported polygon version');
    final metadata = (data['floors'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((f) => f['floor'] == floor);
    if (metadata['width'] != imageSize.width ||
        metadata['height'] != imageSize.height) {
      throw const FormatException('Polygon image dimensions do not match');
    }
    final ids = <String>{};
    final shapes = <RoomPolygon>[];
    for (final value in metadata['rooms'] as List) {
      final id = value['location_id'] as String;
      if (!ids.add(id) || !locations.any((l) => l.id == id)) {
        throw const FormatException('Invalid polygon destination');
      }
      shapes.add(RoomPolygon.parse(id, value['polygon'] as List, imageSize));
    }
    return withRooms(shapes);
  }

  final Map<String, FloorNode> nodes;
  final List<FloorEdge> edges;
  final List<FloorLocation> locations;
  static Future<FloorGraph> load() async {
    final graph = parse(
      await rootBundle.loadString('assets/floor1/nodes.csv'),
      await rootBundle.loadString('assets/floor1/edges.csv'),
      await rootBundle.loadString('assets/floor1/locations.csv'),
    );
    final walls =
        jsonDecode(await rootBundle.loadString('assets/floor1/barriers.json'))
            as List;
    return FloorGraph(
      graph.nodes,
      graph.edges,
      graph.locations,
      graphId: 'morgridge-floor1',
      metersPerPixel: .11,
      barriers: [
        for (final wall in walls)
          [
            for (final point in wall['vertices'])
              Offset(
                (point['x'] as num).toDouble(),
                (point['y'] as num).toDouble(),
              ),
          ],
      ],
    );
  }

  static FloorGraph parse(String ns, String es, String ls) {
    final nodes = <String, FloorNode>{}, allFloors = <String, String>{};
    for (final r in readCsv(ns).skip(1)) {
      if (r.length != 7 || r[0].isEmpty || allFloors.containsKey(r[0])) {
        throw const FormatException('Invalid or duplicate node');
      }
      allFloors[r[0]] = r[1];
      final p = Offset(double.parse(r[2]), double.parse(r[3]));
      if (!p.dx.isFinite || !p.dy.isFinite) {
        throw const FormatException('Invalid coordinates');
      }
      if (r[1] == '1') {
        nodes[r[0]] = FloorNode(r[0], p, r[5], status: r[6]);
      }
    }
    final edges = <FloorEdge>[];
    for (final r in readCsv(es).skip(1)) {
      if (r.length != 6 ||
          !allFloors.containsKey(r[0]) ||
          !allFloors.containsKey(r[1]) ||
          allFloors[r[0]] != allFloors[r[1]]) {
        throw const FormatException('Invalid edge references');
      }
      final cost = double.parse(r[3]);
      if (!cost.isFinite || cost <= 0 || !['true', 'false'].contains(r[4])) {
        throw const FormatException('Invalid edge cost or direction');
      }
      if (allFloors[r[0]] == '1') {
        if (r[2] != 'walk') {
          throw const FormatException('Unsupported first-floor edge type');
        }
        edges.add(
          FloorEdge(r[0], r[1], cost, r[4] == 'true', status: r[5], type: r[2]),
        );
      }
    }
    final locations = <FloorLocation>[], ids = <String>{};
    for (final r in readCsv(ls).skip(1)) {
      if (r.length != 8 ||
          !ids.add(r[0]) ||
          (r[6].isNotEmpty && allFloors[r[6]] != r[1])) {
        throw const FormatException('Invalid location reference');
      }
      if (r[1] == '1') {
        locations.add(
          FloorLocation(
            r[0],
            r[3].isEmpty ? 'Room ${r[2]}' : r[3],
            r[5],
            r[6].isEmpty ? null : r[6],
          ),
        );
      }
    }
    return FloorGraph(nodes, edges, locations);
  }

  bool permits(Offset a, Offset b) =>
      !barriers.any((polygon) => segmentHitsPolygon(a, b, polygon));

  Iterable<FloorEdge> walkEdges(FloorSetup setup, {bool avoidStairs = false}) =>
      edges.where(
        (e) =>
            (!avoidStairs || !['stairs', 'escalator'].contains(e.type)) &&
            permits(point(e.from, setup), point(e.to, setup)),
      );

  Offset point(String id, FloorSetup setup) =>
      setup.nodePoints[id] ?? nodes[id]!.point;
  double cost(FloorEdge e, FloorSetup s) =>
      s.nodePoints.containsKey(e.from) || s.nodePoints.containsKey(e.to)
      ? (point(e.from, s) - point(e.to, s)).distance
      : e.cost;
}

class RoomPolygon {
  RoomPolygon(this.locationId, this.points);
  final String locationId;
  final List<Offset> points;
  Path get path => Path()..addPolygon(points, true);
  double get area {
    var sum = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum.abs() / 2;
  }

  static RoomPolygon parse(String id, List values, Size bounds) {
    final points = <Offset>[];
    for (final value in values) {
      if (value is! List ||
          value.length != 2 ||
          value[0] is! num ||
          value[1] is! num) {
        throw const FormatException('Invalid polygon vertex');
      }
      final p = Offset(
        (value[0] as num).toDouble(),
        (value[1] as num).toDouble(),
      );
      if (!p.dx.isFinite ||
          !p.dy.isFinite ||
          p.dx < 0 ||
          p.dy < 0 ||
          p.dx > bounds.width ||
          p.dy > bounds.height) {
        throw const FormatException('Polygon vertex outside image');
      }
      points.add(p);
    }
    final room = RoomPolygon(id, List.unmodifiable(points));
    if (points.length < 3 || room.area <= 0)
      throw const FormatException('Empty polygon');
    return room;
  }
}

/// Includes boundary contact, so smoothing/snapping cannot cut a wall corner.
bool segmentHitsPolygon(Offset a, Offset b, List<Offset> polygon) {
  if (polygon.length < 3) return false;
  if ((Path()..addPolygon(polygon, true)).contains(a) ||
      (Path()..addPolygon(polygon, true)).contains(b))
    return true;
  double cross(Offset u, Offset v, Offset w) =>
      (v.dx - u.dx) * (w.dy - u.dy) - (v.dy - u.dy) * (w.dx - u.dx);
  bool on(Offset u, Offset v, Offset p) =>
      cross(u, v, p).abs() < 1e-7 &&
      p.dx >= math.min(u.dx, v.dx) - 1e-7 &&
      p.dx <= math.max(u.dx, v.dx) + 1e-7 &&
      p.dy >= math.min(u.dy, v.dy) - 1e-7 &&
      p.dy <= math.max(u.dy, v.dy) + 1e-7;
  for (var i = 0; i < polygon.length; i++) {
    final c = polygon[i], d = polygon[(i + 1) % polygon.length];
    final x = cross(a, b, c),
        y = cross(a, b, d),
        z = cross(c, d, a),
        w = cross(c, d, b);
    if ((x * y < 0 && z * w < 0) ||
        on(a, b, c) ||
        on(a, b, d) ||
        on(c, d, a) ||
        on(c, d, b))
      return true;
  }
  return false;
}
