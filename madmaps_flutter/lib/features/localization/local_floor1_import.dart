import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../client.dart';
import '../navigation/floor_data.dart';
import 'map_data.dart';
import 'shared_captures.dart';

/// One snapshot per phone/backend. Retry the same payloads after interruption;
/// never rescan, reset local data, or import another floor.
class LocalFloor1Import {
  static String get key => 'madmaps.localFloor1CommunityImport.v1:$serverUrl';

  Future<String?> run(
    List<AnchorMap> local,
    FloorGraph floor,
    SharedCaptures captures,
  ) async {
    if (floor.floor != 1) return null;
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(key);
    final state = stored == null
        ? <String, dynamic>{}
        : jsonDecode(stored) as Map<String, dynamic>;
    if (state['done'] == true) return state['message'] as String?;
    if (state.isEmpty) {
      final payloads = <Map<String, dynamic>>[];
      final warnings = <String>[];
      final cached =
          jsonDecode(preferences.getString(SharedCaptures.cacheKey) ?? '[]')
              as List;
      for (final source in local.where(
        (m) => m.floor.floorNumber == 1 && m.anchors.isNotEmpty,
      )) {
        if (cached.any(
          (r) =>
              r['captureId'] == source.id &&
              r['graphId'] == floor.graphId &&
              r['graphVersion'] == floor.version,
        ))
          continue;
        final calibration = source.floor.calibration(source);
        if (calibration == null) {
          warnings.add('${source.name}: floor calibration needed');
          continue;
        }
        final map = AnchorMap.fromJson(source.toJson());
        map.anchors.removeWhere((a) => a.expired);
        final expired = source.anchors.length - map.anchors.length;
        if (expired > 0)
          warnings.add(
            '${source.name}: $expired expired points kept on this phone',
          );
        map.floor.nodePoints.clear();
        map.floor.locationNodes.clear();
        map.floor.anchorNodes.clear();
        map.floor.anchorPoints.clear();
        for (final anchor in map.anchors) {
          final point =
              source.floor.anchorPoints[anchor.id] ??
              calibration.toImage(anchorPosition(anchor));
          if (point.dx < 0 ||
              point.dy < 0 ||
              point.dx > floor.imageSize.width ||
              point.dy > floor.imageSize.height) {
            throw StateError(
              '${source.name}: a point falls outside Floor 1. Local points were preserved; check calibration before importing.',
            );
          }
          map.floor.anchorPoints[anchor.id] = point;
        }
        if (!repairCaptureCalibration(map)) {
          warnings.add('${source.name}: two live calibration points needed');
          continue;
        }
        final pair = map.anchors
            .where((a) => map.floor.calibrationIds.contains(a.id))
            .toList();
        final remaining = map.anchors
            .where((a) => !map.floor.calibrationIds.contains(a.id))
            .toList();
        // Every batch retains the same calibration frame and at most 20 anchors.
        for (
          var offset = 0;
          offset < remaining.length || offset == 0;
          offset += 18
        ) {
          final group = [...pair, ...remaining.skip(offset).take(18)];
          final copy = AnchorMap(
            map.anchors.length <= 20
                ? source.id
                : '${source.id}-part-${offset ~/ 18}',
            source.name,
            group,
          );
          copy.floor.enabled = true;
          copy.floor.floorNumber = 1;
          copy.floor.calibrationIds.addAll(map.floor.calibrationIds);
          copy.floor.anchorPoints.addAll({
            for (final a in group) a.id: map.floor.anchorPoints[a.id]!,
          });
          payloads.add(copy.toJson());
        }
      }
      if (payloads.isEmpty)
        return warnings.isEmpty ? null : warnings.join('. ');
      state.addAll({
        'payloads': payloads,
        'uploaded': <String>[],
        'warnings': warnings,
        'graphId': floor.graphId,
        'graphVersion': floor.version,
      });
      if (!await preferences.setString(key, jsonEncode(state)))
        throw StateError('Could not save Floor 1 import progress');
    }
    if (state['graphId'] != floor.graphId ||
        state['graphVersion'] != floor.version) {
      throw StateError(
        'Floor 1 changed during import. Local points and import progress are preserved; reconcile calibration before sharing.',
      );
    }
    final uploaded = List<String>.from(state['uploaded'] as List);
    for (final json in state['payloads'] as List) {
      final map = AnchorMap.fromJson(Map<String, dynamic>.from(json as Map));
      if (uploaded.contains(map.id)) continue;
      await captures.publish(map, floor);
      uploaded.add(map.id);
      state['uploaded'] = uploaded;
      await preferences.setString(key, jsonEncode(state));
    }
    final warnings = List<String>.from(state['warnings'] as List);
    final message =
        'Floor 1 local points imported into Community once.${warnings.isEmpty ? '' : ' ${warnings.join('. ')}'}';
    await preferences.setString(
      key,
      jsonEncode({'done': true, 'message': message}),
    );
    return message;
  }
}
