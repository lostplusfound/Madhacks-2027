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
  FloorLocation(this.id, this.label, this.aliases, this.node);
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
  FloorGraph(this.nodes, this.edges, this.locations);
  final Map<String, FloorNode> nodes;
  final List<FloorEdge> edges;
  final List<FloorLocation> locations;
  static Future<FloorGraph> load() async => parse(
    await rootBundle.loadString('assets/floor1/nodes.csv'),
    await rootBundle.loadString('assets/floor1/edges.csv'),
    await rootBundle.loadString('assets/floor1/locations.csv'),
  );
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

  Offset point(String id, FloorSetup setup) =>
      setup.nodePoints[id] ?? nodes[id]!.point;
  double cost(FloorEdge e, FloorSetup s) =>
      s.nodePoints.containsKey(e.from) || s.nodePoints.containsKey(e.to)
      ? (point(e.from, s) - point(e.to, s)).distance
      : e.cost;
}
