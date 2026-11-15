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

class ServerMapRepository implements MapRepository {
  ServerMapRepository({Future<api.Client> Function()? connect})
    : _connect =
          connect ??
          (() async {
            await initializeClient();
            return client;
          });
  final Future<api.Client> Function() _connect;
  Future<api.Client>? _connection;
  Future<api.Client> get connection =>
      _connection ??= _connect().catchError((Object e) {
        _connection = null;
        throw e;
      });
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
  @override
  Future<FloorGraph> load() async {
    final c = await connection;
    final result = await c.mapGraph
        .getGraph(graphId, null)
        .timeout(const Duration(seconds: 12));
    final snapshot = result.snapshot;
    if (snapshot == null)
      throw const FormatException('Server returned no map.');
    final graph = adaptSnapshot(snapshot);
    final supported = await c.locationSearch
        .listQuickAccessCategories(graphId)
        .timeout(const Duration(seconds: 12));
    _supportedCategories = supported.map((c) => c.name).toList();
    _categories.clear();
    _categories.addEntries(
      snapshot.locations
          .where((l) => l.floor == 1)
          .map((l) => MapEntry(l.locationId, l.category?.name ?? 'other')),
    );
    _searches.clear();
    return graph;
  }

  @override
  Future<List<String>> search(String query, {String? category}) async {
    final key = '${category ?? ''}:${query.trim().toLowerCase()}';
    final cached = _searches[key];
    if (cached != null) return cached;
    final c = await connection;
    final results = await c.locationSearch
        .searchLocations(
          graphId,
          query,
          category == null
              ? null
              : api.LocationCategory.values.byName(category),
          1,
          100,
        )
        .timeout(const Duration(seconds: 12));
    return _searches[key] = results.map((r) => r.location.locationId).toList();
  }
}

FloorGraph adaptSnapshot(api.MapGraphSnapshot snapshot) {
  final floor = snapshot.floors.where((f) => f.floorNumber == 1).single;
  if (floor.width != floorImageSize.width ||
      floor.height != floorImageSize.height) {
    throw const FormatException('Map dimensions do not match the floor image.');
  }
  final nodes = <String, FloorNode>{};
  for (final n in snapshot.nodes.where((n) => n.floor == 1)) {
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
  for (final l in snapshot.locations.where((l) => l.floor == 1)) {
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
      ),
    );
  }
  if (nodes.isEmpty || edges.isEmpty || locations.isEmpty)
    throw const FormatException('Floor 1 map is empty.');
  return FloorGraph(nodes, edges, locations);
}
