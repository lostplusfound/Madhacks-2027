import 'dart:async';
import 'package:flutter/services.dart';
import 'package:madmaps_client/madmaps_client.dart' as api;
import '../../client.dart';
import 'floor_data.dart';

abstract class MapRepository {
  Future<FloorGraph> load();
  Future<List<String>> search(String query, {String? category});
  List<String> get categories;
  String? categoryOf(String id);
}

abstract interface class MultiFloorMapRepository implements MapRepository {
  Future<Map<int, FloorGraph>> loadFloors();
}

class ServerMapRepository implements MultiFloorMapRepository {
  ServerMapRepository({Future<api.Client> Function()? connect})
    : _connect =
          connect ??
          (() async {
            await initializeClient();
            return client;
          });
  final Future<api.Client> Function() _connect;
  void invalidate() {
    _connectionEpoch = clientRevision.value;
    _generation++;
    _activeClient = null;
    _connection = null;
    _floors.clear();
    _categories.clear();
    _supportedCategories.clear();
    _searches.clear();
  }

  void checkConnection(api.Client c) {
    if (_connectionEpoch != clientRevision.value ||
        !identical(c, _activeClient))
      throw StateError('Server address changed; retry the map load');
  }

  int _connectionEpoch = clientRevision.value;
  Future<api.Client>? _connection;
  api.Client? _activeClient;
  int _generation = 0;
  Future<api.Client> get connection {
    if (_connection != null) return _connection!;
    final generation = _generation;
    final pending = _connect();
    _connectionEpoch = clientRevision.value;
    late final Future<api.Client> future;
    future = pending
        .then((c) {
          if (generation != _generation)
            throw StateError('Server changed during connection');
          _activeClient = c;
          return c;
        })
        .catchError((Object e) {
          if (identical(_connection, future)) _connection = null;
          throw e;
        });
    return _connection = future;
  }

  static const graphId = String.fromEnvironment(
    'MAP_GRAPH_ID',
    defaultValue: 'morgridge-floor1',
  );
  final Map<String, String> _categories = {};
  List<String> _supportedCategories = [];
  final Map<String, List<String>> _searches = {};
  @override
  List<String> get categories =>
      _supportedCategories.where(_categories.containsValue).toList();
  @override
  String? categoryOf(String id) => _categories[id];
  final Map<int, FloorGraph> _floors = {};
  String graphFor(int floor) => floor == 1 ? graphId : 'morgridge-floor$floor';
  @override
  Future<FloorGraph> load() => loadFloor(1);

  Future<FloorGraph> loadFloor(int floorNumber) async {
    final c = await connection;
    final result = await c.mapGraph
        .getGraph(graphFor(floorNumber), null)
        .timeout(const Duration(seconds: 12));
    final snapshot = result.snapshot;
    if (snapshot == null)
      throw const FormatException('Server returned no map.');
    checkConnection(c);
    final graph = await adaptSnapshot(
      snapshot,
      floorNumber: floorNumber,
    ).loadRooms();
    final supported = await c.locationSearch
        .listQuickAccessCategories(graphFor(floorNumber))
        .timeout(const Duration(seconds: 12));
    checkConnection(c);
    _supportedCategories = {
      ..._supportedCategories,
      ...supported.map((c) => c.name),
    }.toList();
    _categories.addEntries(
      snapshot.locations
          .where((l) => l.floor == floorNumber)
          .map((l) => MapEntry(l.locationId, l.category?.name ?? 'other')),
    );
    _floors[floorNumber] = graph;
    _searches.clear();
    return graph;
  }

  @override
  Future<Map<int, FloorGraph>> loadFloors() async {
    for (final floor in [1, 0, 2, 3]) {
      await loadFloor(floor);
    }
    return Map.unmodifiable(_floors);
  }

  @override
  Future<List<String>> search(String query, {String? category}) async {
    final key = '${category ?? ''}:${query.trim().toLowerCase()}';
    final cached = _searches[key];
    if (cached != null) return cached;
    final c = await connection;
    final ids = <String>{};
    for (final floor in _floors.isEmpty ? [1] : _floors.keys) {
      final results = await c.locationSearch
          .searchLocations(
            graphFor(floor),
            query,
            category == null
                ? null
                : api.LocationCategory.values.byName(category),
            floor,
            100,
          )
          .timeout(const Duration(seconds: 12));
      checkConnection(c);
      ids.addAll(results.map((r) => r.location.locationId));
    }
    return _searches[key] = ids.toList();
  }
}

FloorGraph adaptSnapshot(api.MapGraphSnapshot snapshot, {int floorNumber = 1}) {
  final floor = snapshot.floors
      .where((f) => f.floorNumber == floorNumber)
      .single;
  if (floor.width != floorImageSize.width ||
      floor.height != floorImageSize.height) {
    throw const FormatException('Map dimensions do not match the floor image.');
  }
  final barriers = <List<Offset>>[];
  for (final wall in snapshot.walls.where((w) => w.floorId == floor.floorId)) {
    final points = wall.vertices.map((p) => Offset(p.x, p.y)).toList();
    if (points.length < 3 ||
        points.any(
          (p) =>
              !p.dx.isFinite ||
              !p.dy.isFinite ||
              p.dx < 0 ||
              p.dy < 0 ||
              p.dx > floor.width ||
              p.dy > floor.height,
        )) {
      throw const FormatException('Invalid wall geometry');
    }
    barriers.add(points);
  }
  final nodes = <String, FloorNode>{};
  for (final n in snapshot.nodes.where((n) => n.floor == floorNumber)) {
    if (nodes.containsKey(n.nodeId) ||
        !n.x.isFinite ||
        !n.y.isFinite ||
        n.x < 0 ||
        n.y < 0 ||
        n.x > floor.width ||
        n.y > floor.height)
      throw const FormatException('Invalid map node.');
    nodes[n.nodeId] = FloorNode(n.nodeId, Offset(n.x, n.y), n.kind.name);
  }
  final allNodes = {for (final n in snapshot.nodes) n.nodeId: n};
  final edges = <FloorEdge>[];
  for (final e in snapshot.edges) {
    if (!allNodes.containsKey(e.fromNodeId) ||
        !allNodes.containsKey(e.toNodeId) ||
        !e.costPx.isFinite ||
        e.costPx <= 0)
      throw const FormatException('Invalid map edge.');
    if (nodes.containsKey(e.fromNodeId) && nodes.containsKey(e.toNodeId))
      edges.add(
        FloorEdge(
          e.fromNodeId,
          e.toNodeId,
          e.costPx,
          e.bidirectional,
          type: e.type.name,
        ),
      );
  }
  final ids = <String>{};
  final locations = <FloorLocation>[];
  for (final l in snapshot.locations.where((l) => l.floor == floorNumber)) {
    if (!ids.add(l.locationId) ||
        (l.routeNodeId != null && !nodes.containsKey(l.routeNodeId)))
      throw const FormatException('Invalid destination reference.');
    locations.add(
      FloorLocation(
        l.locationId,
        l.name ??
            (l.roomNumber == null ? l.locationId : 'Room ${l.roomNumber}'),
        l.aliases ?? '',
        l.routeNodeId,
        floor: floorNumber,
      ),
    );
  }
  if (nodes.isEmpty || edges.isEmpty || locations.isEmpty)
    throw const FormatException('Floor map is empty.');
  return FloorGraph(
    nodes,
    edges,
    locations,
    floor: floorNumber,
    graphId: snapshot.graph.graphId,
    version: snapshot.graph.version,
    metersPerPixel: floor.metersPerUnit == 1
        ? const {0: .07, 1: .11, 2: .09, 3: .07}[floorNumber] ?? .1
        : floor.metersPerUnit,
    barriers: barriers,
    imageSize: Size(floor.width, floor.height),
  );
}
