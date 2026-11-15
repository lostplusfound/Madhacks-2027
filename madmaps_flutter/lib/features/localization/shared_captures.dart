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
  static String get editsKey => 'madmaps.pendingCaptureEdits.v1:$serverUrl';
  static String get publishedIdsKey =>
      'madmaps.publishedCaptureIds.v1:$serverUrl';

  Future<void> _rememberPublished(Iterable<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    final known =
        preferences.getStringList(publishedIdsKey)?.toSet() ?? <String>{};
    known.addAll(ids);
    await preferences.setStringList(publishedIdsKey, known.toList());
  }

  /// Prefer shared versions, but never identify shared records by an ID prefix.
  /// Explicitly known published IDs cannot fall back to stale local copies after
  /// a shared scan is removed or becomes incompatible with the loaded graph.
  Future<List<AnchorMap>> navigationMaps(
    List<AnchorMap> local,
    List<AnchorMap> shared,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final known =
        preferences.getStringList(publishedIdsKey)?.toSet() ?? <String>{};
    final sharedIds = shared.map((m) => m.id).toSet();
    return [
      ...local.where((m) => !known.contains(m.id) && !sharedIds.contains(m.id)),
      ...shared,
    ];
  }

  Future<void> discardEdit(String captureId) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = Map<String, dynamic>.from(
      jsonDecode(prefs.getString(editsKey) ?? '{}') as Map,
    );
    pending.remove(captureId);
    await prefs.setString(editsKey, jsonEncode(pending));
  }

  /// The exact server payload is the optimistic concurrency token.
  Future<String> originalJson(String captureId) async {
    final preferences = await SharedPreferences.getInstance();
    final records = jsonDecode(preferences.getString(cacheKey) ?? '[]') as List;
    return api.ArCapture.fromJson(
      Map<String, dynamic>.from(
        records.firstWhere((r) => r['captureId'] == captureId) as Map,
      ),
    ).anchorMapJson;
  }

  Future<void> edit(
    AnchorMap map,
    FloorGraph graph,
    String expected, {
    bool delete = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = Map<String, dynamic>.from(
      jsonDecode(prefs.getString(editsKey) ?? '{}') as Map,
    );
    final capture = api.ArCapture(
      captureId: map.id,
      graphId: graph.graphId,
      graphVersion: graph.version,
      floorNumber: graph.floor,
      anchorMapJson: jsonEncode(map.toJson()),
      expiresAt: DateTime.now(),
    );
    pending[map.id] = {
      'capture': capture.toJson(),
      'expected': expected,
      'delete': delete,
    };
    if (!await prefs.setString(editsKey, jsonEncode(pending)))
      throw StateError('Could not save edit for retry');
    await _sendEdit(pending[map.id] as Map<String, dynamic>);
    pending.remove(map.id);
    await prefs.setString(editsKey, jsonEncode(pending));
  }

  Future<void> _sendEdit(Map<String, dynamic> edit) async {
    final connection = await _connect();
    final capture = api.ArCapture.fromJson(
      Map<String, dynamic>.from(edit['capture'] as Map),
    );
    await _rememberPublished([capture.captureId]);
    api.ArCapture? updated;
    if (edit['delete'] == true) {
      await connection.buildingMap
          .deleteCapture(capture.captureId, edit['expected'] as String)
          .timeout(const Duration(seconds: 20));
    } else {
      updated = await connection.buildingMap
          .updateCapture(capture, edit['expected'] as String)
          .timeout(const Duration(seconds: 20));
    }
    final preferences = await SharedPreferences.getInstance();
    final records =
        (jsonDecode(preferences.getString(cacheKey) ?? '[]') as List)
            .where((r) => r['captureId'] != capture.captureId)
            .toList();
    if (updated != null) records.add(updated.toJson());
    await preferences.setString(cacheKey, jsonEncode(records));
  }

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
    await _rememberPublished(records.map((r) => r.captureId));
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
      await _rememberPublished(fresh.map((r) => r.captureId));
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
    await _rememberPublished([capture.captureId]);
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
    final edits = Map<String, dynamic>.from(
      jsonDecode(preferences.getString(editsKey) ?? '{}') as Map,
    );
    for (final id in edits.keys.toList()) {
      await _sendEdit(Map<String, dynamic>.from(edits[id] as Map));
      edits.remove(id);
      await preferences.setString(editsKey, jsonEncode(edits));
    }
  }
}
