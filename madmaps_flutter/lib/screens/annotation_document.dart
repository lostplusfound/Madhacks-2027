import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

const annotationCategories = [
  'bathroom',
  'studySpace',
  'exit',
  'entrance',
  'elevator',
  'stairs',
  'classroom',
  'auditorium',
  'food',
  'office',
  'accessibilityService',
  'landmark',
  'other',
];
const annotationGroups = ['rooms', 'walls', 'doors', 'walkable_areas'];

const annotationCategoryLabels = {
  'bathroom': 'Restroom',
  'studySpace': 'Study space',
  'exit': 'Exit',
  'entrance': 'Entrance',
  'elevator': 'Elevator',
  'stairs': 'Stairs',
  'classroom': 'Classroom',
  'auditorium': 'Auditorium',
  'food': 'Food / cafe',
  'office': 'Office',
  'accessibilityService': 'Accessibility service',
  'landmark': 'Landmark',
  'other': 'Other / room',
};
String categoryLabel(String category) =>
    annotationCategoryLabels[category] ?? category;
double normalizedRotation(double degrees) =>
    ((degrees + 180) % 360 + 360) % 360 - 180;
Offset rotatePixel(Offset point, Offset center, double degrees) {
  final theta = degrees * math.pi / 180, delta = point - center;
  return center +
      Offset(
        delta.dx * math.cos(theta) - delta.dy * math.sin(theta),
        delta.dx * math.sin(theta) + delta.dy * math.cos(theta),
      );
}

Offset roomCenter(Map<String, dynamic> item) {
  final b = item['bbox'] as List;
  return Offset(
    ((b[0] as num) + (b[2] as num)) / 2,
    ((b[1] as num) + (b[3] as num)) / 2,
  );
}

List<Offset> roomVertices(Map<String, dynamic> item) {
  final b = item['bbox'] as List, center = roomCenter(item);
  final angle = (item['rotation_deg'] as num? ?? 0).toDouble();
  return [
    for (final p in [
      Offset((b[0] as num).toDouble(), (b[1] as num).toDouble()),
      Offset((b[2] as num).toDouble(), (b[1] as num).toDouble()),
      Offset((b[2] as num).toDouble(), (b[3] as num).toDouble()),
      Offset((b[0] as num).toDouble(), (b[3] as num).toDouble()),
    ])
      rotatePixel(p, center, angle),
  ];
}

List<double> resizedRoomBox(
  Map<String, dynamic> item,
  int corner,
  Offset point,
) {
  final opposite = roomVertices(item)[(corner + 2) % 4],
      center = (point + opposite) / 2;
  final local = rotatePixel(
    point - opposite,
    Offset.zero,
    -(item['rotation_deg'] as num? ?? 0).toDouble(),
  );
  final w = local.dx.abs(), h = local.dy.abs();
  return [
    center.dx - w / 2,
    center.dy - h / 2,
    center.dx + w / 2,
    center.dy + h / 2,
  ];
}

Offset roomRotationHandle(Map<String, dynamic> item, double gap) {
  final b = item['bbox'] as List, center = roomCenter(item);
  return rotatePixel(
    Offset(center.dx, (b[1] as num).toDouble() - gap),
    center,
    (item['rotation_deg'] as num? ?? 0).toDouble(),
  );
}

class AnnotationSelection {
  const AnnotationSelection(this.group, this.id);
  final String group;
  final String id;
}

/// Reviewed geometry is a separate copy of the prediction, in canonical pixels.
class AnnotationDocument extends ChangeNotifier {
  AnnotationDocument(Map<String, dynamic> source) : _data = _copy(source) {
    _validate(_data);
    width = (_data['width'] as num).toDouble();
    height = (_data['height'] as num).toDouble();
  }

  Map<String, dynamic> _data;
  late final double width, height;
  final _undo = <String>[], _redo = <String>[];
  AnnotationSelection? selection;
  int revision = 0;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  Map<String, dynamic> get data => _copy(_data);
  String get json => const JsonEncoder.withIndent('  ').convert(_data);
  Map<String, dynamic>? get selected {
    final s = selection;
    if (s == null) return null;
    return Map<String, dynamic>.from(_find(_data, s));
  }

  static Map<String, dynamic> _copy(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  static Map<String, dynamic> _find(
    Map<String, dynamic> data,
    AnnotationSelection s,
  ) => (data[s.group] as List).cast<Map<String, dynamic>>().firstWhere(
    (item) => item['id'] == s.id,
  );

  void select(AnnotationSelection? value) {
    selection = value;
    notifyListeners();
  }

  void _commit(Map<String, dynamic> next, {AnnotationSelection? select}) {
    _validate(next);
    if (next['width'] != width || next['height'] != height) {
      throw const FormatException(
        'Image dimensions cannot change during annotation.',
      );
    }
    if (jsonEncode(next) == jsonEncode(_data)) return;
    _undo.add(jsonEncode(_data));
    if (_undo.length > 50) _undo.removeAt(0);
    _redo.clear();
    _data = next;
    selection = select;
    revision++;
    notifyListeners();
  }

  void replace(Map<String, dynamic> next) => _commit(_copy(next));

  String _id(String group) {
    final prefix = {
      'rooms': 'room',
      'walls': 'wall',
      'doors': 'door',
      'walkable_areas': 'walkable',
    }[group]!;
    final ids = (_data[group] as List).map((e) => e['id']).toSet();
    var n = 1;
    while (ids.contains('${prefix}_$n')) {
      n++;
    }
    return '${prefix}_$n';
  }

  void addPolygon(String group, List<Offset> points) {
    if (!{'walls', 'walkable_areas'}.contains(group))
      throw ArgumentError('Unsupported polygon layer');
    final next = data, id = _id(group);
    (next[group] as List).add({
      'id': id,
      'polygon': [
        for (final p in points) [p.dx, p.dy],
      ],
      'confidence': 1.0,
    });
    _commit(next, select: AnnotationSelection(group, id));
  }

  void addRoom(Offset start, Offset end, {String category = 'other'}) {
    final next = data, id = _id('rooms');
    (next['rooms'] as List).add({
      'id': id,
      'label': category == 'other'
          ? 'Room ${(_data['rooms'] as List).length + 1}'
          : categoryLabel(category),
      'category': category,
      'rotation_deg': 0.0,
      'bbox': [
        math.min(start.dx, end.dx),
        math.min(start.dy, end.dy),
        math.max(start.dx, end.dx),
        math.max(start.dy, end.dy),
      ],
      'confidence': 1.0,
    });
    _commit(next, select: AnnotationSelection('rooms', id));
  }

  void addDoor(Offset point, String roomId) {
    final next = data, id = _id('doors');
    (next['doors'] as List).add({
      'id': id,
      'room_id': roomId,
      'point': [point.dx, point.dy],
      'confidence': 1.0,
    });
    _commit(next, select: AnnotationSelection('doors', id));
  }

  void updateRoom(String label, String category) {
    final s = selection;
    if (s?.group != 'rooms') return;
    final next = data, item = _find(next, s!);
    item.addAll({
      'label': label.trim(),
      'category': category,
      'confidence': 1.0,
    });
    _commit(next, select: s);
  }

  void rotateSelected(double degrees) {
    if (!degrees.isFinite)
      throw const FormatException('Rotation must be a finite number.');
    final s = selection;
    if (s?.group != 'rooms') return;
    final next = data;
    _find(
      next,
      s!,
    ).addAll({'rotation_deg': normalizedRotation(degrees), 'confidence': 1.0});
    _commit(next, select: s);
  }

  void updateDoorRoom(String roomId) {
    final s = selection;
    if (s?.group != 'doors') return;
    final next = data;
    _find(next, s!).addAll({'room_id': roomId, 'confidence': 1.0});
    _commit(next, select: s);
  }

  List<Offset> vertices(AnnotationSelection s) {
    final item = _find(_data, s);
    if (s.group == 'rooms') return roomVertices(item);
    final coordinates = s.group == 'doors'
        ? [item['point']]
        : item['polygon'] as List;
    final points = [
      for (final p in coordinates)
        Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];
    if (points.length > 1 && points.first == points.last) points.removeLast();
    return points;
  }

  void moveVertex(int index, Offset point) {
    final s = selection;
    if (s == null) return;
    final next = data, item = _find(next, s);
    if (s.group == 'rooms') {
      item['bbox'] = resizedRoomBox(item, index, point);
    } else if (s.group == 'doors') {
      item['point'] = [point.dx, point.dy];
    } else {
      final points = vertices(s)..[index] = point;
      item['polygon'] = [
        for (final p in points) [p.dx, p.dy],
      ];
    }
    item['confidence'] = 1.0;
    _commit(next, select: s);
  }

  void insertVertex(int after) {
    final s = selection;
    if (s == null || !{'walls', 'walkable_areas'}.contains(s.group)) return;
    final points = vertices(s);
    final a = points[after], b = points[(after + 1) % points.length];
    points.insert(after + 1, (a + b) / 2);
    final next = data;
    _find(next, s).addAll({
      'polygon': [
        for (final p in points) [p.dx, p.dy],
      ],
      'confidence': 1.0,
    });
    _commit(next, select: s);
  }

  void removeVertex(int index) {
    final s = selection;
    if (s == null || !{'walls', 'walkable_areas'}.contains(s.group)) return;
    final points = vertices(s)..removeAt(index);
    final next = data;
    _find(next, s).addAll({
      'polygon': [
        for (final p in points) [p.dx, p.dy],
      ],
      'confidence': 1.0,
    });
    _commit(next, select: s);
  }

  void deleteSelected() {
    final s = selection;
    if (s == null) return;
    final next = data;
    (next[s.group] as List).removeWhere((item) => item['id'] == s.id);
    if (s.group == 'rooms')
      (next['doors'] as List).removeWhere((item) => item['room_id'] == s.id);
    _commit(next);
  }

  void undo() {
    if (!canUndo) return;
    _redo.add(jsonEncode(_data));
    _data = jsonDecode(_undo.removeLast()) as Map<String, dynamic>;
    selection = null;
    revision++;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(jsonEncode(_data));
    _data = jsonDecode(_redo.removeLast()) as Map<String, dynamic>;
    selection = null;
    revision++;
    notifyListeners();
  }

  static void _validate(Map<String, dynamic> data) {
    double number(dynamic value) {
      if (value is! num || !value.isFinite)
        throw const FormatException('Coordinates must be finite numbers.');
      return value.toDouble();
    }

    final w = number(data['width']), h = number(data['height']);
    if (w <= 0 ||
        h <= 0 ||
        w != w.roundToDouble() ||
        h != h.roundToDouble() ||
        data['schema_version'] != 1 ||
        data['coordinate_origin'] != 'top-left' ||
        data['coordinate_units'] != 'pixels') {
      throw const FormatException(
        'Use the original image frame and pixel coordinate contract.',
      );
    }
    Offset point(dynamic raw) {
      if (raw is! List || raw.length != 2)
        throw const FormatException('Each vertex needs [x, y].');
      final p = Offset(number(raw[0]), number(raw[1]));
      if (p.dx < 0 || p.dx > w || p.dy < 0 || p.dy > h)
        throw const FormatException('A vertex is outside the image.');
      return p;
    }

    final roomIds = <String>{};
    for (final group in annotationGroups) {
      if (data[group] is! List) throw FormatException('Missing $group array.');
      final ids = <String>{};
      for (final raw in data[group] as List) {
        if (raw is! Map) throw FormatException('Invalid $group entry.');
        final id = raw['id'];
        if (id is! String ||
            !RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$').hasMatch(id) ||
            !ids.add(id))
          throw FormatException('Invalid or duplicate $group ID.');
        final confidence = number(raw['confidence']);
        if (confidence < 0 || confidence > 1)
          throw const FormatException('Confidence must be between 0 and 1.');
        if (group == 'rooms') {
          roomIds.add(id);
          if (raw['label'] is! String ||
              (raw['label'] as String).trim().isEmpty ||
              !annotationCategories.contains(raw['category']))
            throw const FormatException(
              'A room needs a label and valid category.',
            );
          final b = raw['bbox'];
          if (b is! List || b.length != 4)
            throw const FormatException('Room boxes need four coordinates.');
          final a = Offset(number(b[0]), number(b[1])),
              c = Offset(number(b[2]), number(b[3]));
          final angle = number(
            raw.containsKey('rotation_deg') ? raw['rotation_deg'] : 0,
          );
          if (angle < -180 || angle > 180)
            throw const FormatException(
              'Rotation must be between -180 and 180 degrees.',
            );
          for (final p in roomVertices(Map<String, dynamic>.from(raw))) {
            if (p.dx < -1e-7 ||
                p.dx > w + 1e-7 ||
                p.dy < -1e-7 ||
                p.dy > h + 1e-7)
              throw const FormatException(
                'The rotated box extends outside the image.',
              );
          }
          if (a.dx >= c.dx || a.dy >= c.dy)
            throw const FormatException(
              'A room box must have positive width and height.',
            );
        } else if (group == 'doors') {
          final p = point(raw['point']);
          if (!roomIds.contains(raw['room_id']))
            throw const FormatException(
              'Choose an existing room for each door.',
            );
          if (p.dx <= 0 || p.dx >= w || p.dy <= 0 || p.dy >= h)
            throw const FormatException(
              'Doors must be inside the image perimeter.',
            );
        } else {
          if (raw['polygon'] is! List)
            throw const FormatException('A polygon needs a list of vertices.');
          final points = [for (final p in raw['polygon'] as List) point(p)];
          if (points.length > 1 && points.first == points.last)
            points.removeLast();
          if (points.length < 3 || points.toSet().length != points.length)
            throw const FormatException(
              'Use at least three distinct polygon vertices.',
            );
          double cross(Offset a, Offset b, Offset c) =>
              (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
          bool onSegment(Offset a, Offset b, Offset p) =>
              cross(a, b, p).abs() < 1e-8 &&
              p.dx >= math.min(a.dx, b.dx) &&
              p.dx <= math.max(a.dx, b.dx) &&
              p.dy >= math.min(a.dy, b.dy) &&
              p.dy <= math.max(a.dy, b.dy);
          bool intersects(Offset a, Offset b, Offset c, Offset d) =>
              (cross(a, b, c) * cross(a, b, d) < 0 &&
                  cross(c, d, a) * cross(c, d, b) < 0) ||
              onSegment(a, b, c) ||
              onSegment(a, b, d) ||
              onSegment(c, d, a) ||
              onSegment(c, d, b);
          var area = 0.0;
          for (var i = 0; i < points.length; i++) {
            final a = points[i], b = points[(i + 1) % points.length];
            area += a.dx * b.dy - b.dx * a.dy;
            for (var j = i + 1; j < points.length; j++) {
              if (j == i + 1 || (i == 0 && j == points.length - 1)) continue;
              if (intersects(a, b, points[j], points[(j + 1) % points.length]))
                throw const FormatException(
                  'Polygon edges cannot cross or touch themselves.',
                );
            }
          }
          if (area.abs() < 1e-8)
            throw const FormatException('A polygon must enclose an area.');
        }
      }
    }
  }
}
