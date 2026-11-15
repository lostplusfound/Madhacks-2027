import 'dart:convert';
import 'package:madmaps_client/madmaps_client.dart' as api;
import 'package:shared_preferences/shared_preferences.dart';
import '../../client.dart';
import '../navigation/floor_data.dart';
import 'map_data.dart';

class SharedCaptures {
  SharedCaptures({Future<api.Client> Function()? connect})
    : _connect = connect ?? _defaultConnect;
  final Future<api.Client> Function() _connect;
  static Future<api.Client> _defaultConnect() async {
    await initializeClient();
    return client;
  }

  static String get cacheKey => 'madmaps.sharedCaptures.v1:$serverUrl';
  static String get pendingKey => 'madmaps.pendingCaptures.v1:$serverUrl';

  Future<List<AnchorMap>> load(Map<int, FloorGraph> floors) async {
    final preferences = await SharedPreferences.getInstance();
    var records = <api.ArCapture>[];
    final cached = preferences.getString(cacheKey);
    if (cached != null) {
      try {
        records = (jsonDecode(cached) as List)
            .map((j) => api.ArCapture.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (_) {
        /* Ignore corrupt remote cache. */
      }
    }
    try {
      final connection = await _connect();
      final revision = clientRevision.value;
      final fresh = <api.ArCapture>[];
      for (final graph in floors.values) {
        fresh.addAll(
          await connection.buildingMap
              .listCaptures(graph.graphId, graph.version)
              .timeout(const Duration(seconds: 12)),
        );
      }
      if (revision != clientRevision.value) throw StateError('Server changed');
      records = fresh;
      await preferences.setString(
        cacheKey,
        jsonEncode(records.map((c) => c.toJson()).toList()),
      );
    } catch (_) {
      /* Use compatible cached metadata offline. */
    }
    final maps = <AnchorMap>[];
    for (final record in records) {
      final g = floors[record.floorNumber];
      if (g == null ||
          g.graphId != record.graphId ||
          g.version != record.graphVersion ||
          !record.expiresAt.isAfter(DateTime.now()))
        continue;
      try {
        final map = AnchorMap.fromJson(
          jsonDecode(record.anchorMapJson) as Map<String, dynamic>,
        );
        if (map.floor.floorNumber == record.floorNumber &&
            map.anchors.every((a) => !a.expired) &&
            map.floor.calibration(map) != null)
          maps.add(map);
      } catch (_) {
        /* A malformed contribution must not break discovery. */
      }
    }
    return maps;
  }

  Future<void> publish(AnchorMap map, FloorGraph graph) async {
    final calibration = map.floor.calibration(map);
    if (calibration == null || map.floor.floorNumber != graph.floor)
      throw StateError('Finish the two-point calibration first');
    final capture = api.ArCapture(
      captureId: map.id,
      graphId: graph.graphId,
      graphVersion: graph.version,
      floorNumber: graph.floor,
      anchorMapJson: jsonEncode(map.toJson()),
      expiresAt: map.anchors
          .map((a) => a.expiresAt)
          .reduce((a, b) => a.isBefore(b) ? a : b),
    );
    final preferences = await SharedPreferences.getInstance();
    final pending = Map<String, dynamic>.from(
      jsonDecode(preferences.getString(pendingKey) ?? '{}') as Map,
    );
    pending[map.id] = capture.toJson();
    if (!await preferences.setString(pendingKey, jsonEncode(pending)))
      throw StateError('Could not save upload for retry');
    await upload(capture);
    pending.remove(map.id);
    await preferences.setString(pendingKey, jsonEncode(pending));
  }

  Future<void> upload(api.ArCapture capture) async {
    final connection = await _connect();
    await connection.buildingMap
        .publishCapture(capture)
        .timeout(const Duration(seconds: 20));
  }

  Future<void> retryPending() async {
    final preferences = await SharedPreferences.getInstance();
    final pending = Map<String, dynamic>.from(
      jsonDecode(preferences.getString(pendingKey) ?? '{}') as Map,
    );
    for (final id in pending.keys.toList()) {
      await upload(api.ArCapture.fromJson(pending[id] as Map<String, dynamic>));
      pending.remove(id);
      await preferences.setString(pendingKey, jsonEncode(pending));
    }
  }
}
