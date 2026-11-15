import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/navigation_models.dart';
import 'morgridge_mock_data.dart';

const _mapWidth = 1632.0;
const _mapHeight = 1056.0;
const graphFeetPerPixel = .25;

class MorgridgeGraphData {
  MorgridgeGraphData._(
    this._locations,
    this._nodes,
    this._edges,
    this._roomCenters,
  );

  final Map<String, _GraphLocation> _locations;
  final Map<String, _GraphNode> _nodes;
  final Map<String, List<_GraphEdge>> _edges;
  final Map<String, Offset> _roomCenters;

  static Future<MorgridgeGraphData> load() async {
    final values = await Future.wait([
      rootBundle.loadString('assets/morgridge_handoff/locations.csv'),
      rootBundle.loadString('assets/morgridge_handoff/nodes.csv'),
      rootBundle.loadString('assets/morgridge_handoff/edges.csv'),
      rootBundle.loadString('assets/morgridge_handoff/room_shapes.json'),
    ]);
    final locations = <String, _GraphLocation>{};
    for (final row in _csv(values[0]).skip(1)) {
      final item = _GraphLocation.fromRow(row);
      locations[item.id] = item;
    }
    final nodes = <String, _GraphNode>{};
    for (final row in _csv(values[1]).skip(1)) {
      final item = _GraphNode.fromRow(row);
      nodes[item.id] = item;
    }
    final edges = <String, List<_GraphEdge>>{};
    for (final row in _csv(values[2]).skip(1)) {
      final edge = _GraphEdge.fromRow(row);
      edges.putIfAbsent(edge.from, () => []).add(edge);
      if (edge.bidirectional) {
        edges.putIfAbsent(edge.to, () => []).add(edge.reversed);
      }
    }
    final roomCenters = <String, Offset>{};
    final shapes = jsonDecode(values[3]) as Map<String, dynamic>;
    for (final floor in shapes['floors'] as List<dynamic>) {
      for (final room in floor['rooms'] as List<dynamic>) {
        final polygon = room['polygon'] as List<dynamic>;
        if (polygon.isEmpty) continue;
        final totalX = polygon.fold<double>(
          0,
          (sum, point) => sum + (point[0] as num).toDouble(),
        );
        final totalY = polygon.fold<double>(
          0,
          (sum, point) => sum + (point[1] as num).toDouble(),
        );
        roomCenters[room['location_id'] as String] = Offset(
          totalX / polygon.length / _mapWidth,
          totalY / polygon.length / _mapHeight,
        );
      }
    }
    return MorgridgeGraphData._(locations, nodes, edges, roomCenters);
  }

  List<Place> get places => _locations.values
      .where(
        (location) =>
            location.floor <= 3 &&
            location.routeNodeId != null &&
            _nodes.containsKey(location.routeNodeId),
      )
      .map(_toPlace)
      .toList(growable: false);

  Place? placeByName(String name) {
    for (final place in places) {
      if (place.name == name) return place;
    }
    return null;
  }

  LocationFix resolveDescription(
    String description, {
    required int preferredFloor,
  }) {
    final query = description.toLowerCase();
    final floor = _spokenFloor(query) ?? preferredFloor;
    _GraphLocation? best;
    var bestScore = -1;
    for (final location in _locations.values) {
      final node = location.routeNodeId == null
          ? null
          : _nodes[location.routeNodeId];
      if (node == null || location.floor != floor) continue;
      final words = <String>[
        location.name,
        location.room,
        location.category,
        ...location.aliases,
      ].where((value) => value.isNotEmpty).join(' ').toLowerCase();
      var score = 0;
      for (final token in query.split(RegExp(r'[^a-z0-9]+'))) {
        if (token.length > 1 && words.contains(token)) score += token.length;
      }
      if (query.contains('elevator') && location.category == 'elevator') {
        score += 40;
      }
      if (query.contains('restroom') && location.category == 'restroom') {
        score += 40;
      }
      if (query.contains('stairs') && location.category == 'stairs') {
        score += 40;
      }
      if (query.contains('exit') && location.category == 'exit') {
        score += 30;
      }
      if (score > bestScore) {
        bestScore = score;
        best = location;
      }
    }
    if (best != null) {
      final node = _nodes[best.routeNodeId]!;
      return LocationFix(
        label: best.label,
        floor: best.floor,
        point: node.normalized,
      );
    }
    final fallback = _nodes.values
        .where((node) => node.floor == floor)
        .firstOrNull;
    return LocationFix(
      label: 'Nearby hallway · Floor $floor',
      floor: floor,
      point: fallback?.normalized ?? const Offset(.5, .5),
    );
  }

  GraphPath? findPath(LocationFix origin, Place destination) {
    final target = _locations.values
        .where(
          (location) =>
              location.room == destination.room ||
              location.name == destination.name,
        )
        .firstOrNull;
    final targetNode = target?.routeNodeId == null
        ? null
        : _nodes[target!.routeNodeId];
    if (targetNode == null || origin.floor != destination.floor) return null;
    final start = _nearestNode(origin.point, origin.floor);
    if (start == null) return null;
    final distances = <String, double>{start.id: 0};
    final previous = <String, String>{};
    final pending = <_QueueEntry>[_QueueEntry(start.id, 0)];
    while (pending.isNotEmpty) {
      pending.sort((a, b) => a.cost.compareTo(b.cost));
      final current = pending.removeAt(0);
      if (current.cost != distances[current.node]) continue;
      if (current.node == targetNode.id) break;
      for (final edge in _edges[current.node] ?? const []) {
        final candidate = current.cost + edge.cost;
        if (candidate < (distances[edge.to] ?? double.infinity)) {
          distances[edge.to] = candidate;
          previous[edge.to] = current.node;
          pending.add(_QueueEntry(edge.to, candidate));
        }
      }
    }
    if (!distances.containsKey(targetNode.id)) return null;
    final ids = <String>[targetNode.id];
    while (ids.last != start.id) {
      ids.add(previous[ids.last]!);
    }
    final points = ids.reversed.map((id) => _nodes[id]!.normalized).toList();
    return GraphPath(
      points,
      (distances[targetNode.id]! * graphFeetPerPixel).round(),
    );
  }

  _GraphNode? _nearestNode(Offset point, int floor) => _nodes.values
      .where((node) => node.floor == floor)
      .fold<_GraphNode?>(
        null,
        (best, node) =>
            best == null ||
                (node.normalized - point).distance <
                    (best.normalized - point).distance
            ? node
            : best,
      );

  Place _toPlace(_GraphLocation location) {
    final node = _nodes[location.routeNodeId]!;
    final name = location.name.isNotEmpty
        ? location.name
        : 'Room ${location.room}';
    final category = location.category.isEmpty ? 'Room' : location.category;
    return Place(
      name: name,
      subtitle: '${_title(category)} · Floor ${location.floor}',
      room: location.room.isEmpty ? name : location.room,
      floor: location.floor,
      icon: _icon(category),
      color: _color(category),
      point: _roomCenters[location.id] ?? node.normalized,
      category: _title(category),
      hours: location.room == '2532'
          ? const PlaceHours(Availability.closed)
          : name == 'Learning Center'
          ? const PlaceHours(Availability.closingSoon, minutesUntilClose: 45)
          : const PlaceHours(Availability.open),
    );
  }
}

class GraphPath {
  const GraphPath(this.points, this.distanceFeet);
  final List<Offset> points;
  final int distanceFeet;
}

class _GraphLocation {
  _GraphLocation(
    this.id,
    this.floor,
    this.room,
    this.name,
    this.category,
    this.aliases,
    this.routeNodeId,
  );
  final String id, room, name, category;
  final int floor;
  final List<String> aliases;
  final String? routeNodeId;
  String get label => name.isNotEmpty ? name : 'Room $room';
  factory _GraphLocation.fromRow(List<String> r) => _GraphLocation(
    r[0],
    int.parse(r[1]),
    r[2],
    r[3],
    r[4],
    r[5].split(';').where((v) => v.isNotEmpty).toList(),
    r[6].isEmpty ? null : r[6],
  );
}

class _GraphNode {
  _GraphNode(this.id, this.floor, this.x, this.y);
  final String id;
  final int floor;
  final double x, y;
  Offset get normalized => Offset(x / _mapWidth, y / _mapHeight);
  factory _GraphNode.fromRow(List<String> r) =>
      _GraphNode(r[0], int.parse(r[1]), double.parse(r[2]), double.parse(r[3]));
}

class _GraphEdge {
  _GraphEdge(this.from, this.to, this.cost, this.bidirectional);
  final String from, to;
  final double cost;
  final bool bidirectional;
  _GraphEdge get reversed => _GraphEdge(to, from, cost, bidirectional);
  factory _GraphEdge.fromRow(List<String> r) =>
      _GraphEdge(
        r[0],
        r[1],
        double.tryParse(r[3]) ?? 1,
        r[4].toLowerCase() == 'true',
      );
}

class _QueueEntry {
  const _QueueEntry(this.node, this.cost);
  final String node;
  final double cost;
}

List<List<String>> _csv(String source) => source
    .split(RegExp(r'\r?\n'))
    .where((line) => line.isNotEmpty)
    .map((line) => line.split(','))
    .toList();
int? _spokenFloor(String text) =>
    text.contains('third') || text.contains('floor 3') || text.contains('3rd')
    ? 3
    : text.contains('first') || text.contains('floor 1') || text.contains('1st')
    ? 1
    : text.contains('second') ||
          text.contains('floor 2') ||
          text.contains('2nd')
    ? 2
    : null;
String _title(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
IconData _icon(String category) => switch (category) {
  'elevator' => Icons.elevator_rounded,
  'restroom' => Icons.wc_rounded,
  'exit' => Icons.exit_to_app_rounded,
  'stairs' => Icons.stairs_rounded,
  'cafe' => Icons.local_cafe_rounded,
  'library' || 'study_room' || 'learning_center' => Icons.menu_book_rounded,
  'lounge' => Icons.weekend_rounded,
  _ => Icons.meeting_room_outlined,
};

// End of handoff graph helpers.
Color _color(String category) => switch (category) {
  'elevator' || 'restroom' || 'exit' => const Color(0xff16817a),
  'cafe' || 'library' || 'study_room' || 'learning_center' => amber,
  'lounge' => loungeSlate,
  _ => mapTeal,
};

// End map category styling.
