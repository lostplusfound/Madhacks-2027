import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

class SavedAnchor {
  SavedAnchor(this.id, this.name, this.cloudId, this.pose, this.expiresAt);
  final String id;
  String name;
  final String cloudId;
  final Matrix4 pose;
  final DateTime expiresAt;
  bool get expired => !expiresAt.isAfter(DateTime.now());
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cloudId': cloudId,
    'pose': pose.storage.toList(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
  factory SavedAnchor.fromJson(Map<String, dynamic> j) => SavedAnchor(
    j['id'] as String,
    j['name'] as String,
    j['cloudId'] as String,
    Matrix4.fromList(
      (j['pose'] as List).map((v) => (v as num).toDouble()).toList(),
    ),
    DateTime.parse(j['expiresAt'] as String),
  );
}

class AnchorMap {
  AnchorMap(this.id, this.name, this.anchors);
  final String id;
  String name;
  final List<SavedAnchor> anchors;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'anchors': anchors.map((a) => a.toJson()).toList(),
  };
  factory AnchorMap.fromJson(Map<String, dynamic> j) => AnchorMap(
    j['id'] as String,
    j['name'] as String,
    (j['anchors'] as List)
        .map((a) => SavedAnchor.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList(),
  );
}

/// A local map is a floor for discovery; preserve its existing coordinate frame.
class LocalizationCandidate {
  LocalizationCandidate(this.map, this.anchor);
  final AnchorMap map;
  final SavedAnchor anchor;
  Matrix4 alignment(Matrix4 sessionAnchor) =>
      alignMap(anchor.pose, sessionAnchor);
}

Map<String, LocalizationCandidate> liveAnchorCandidates(List<AnchorMap> maps) {
  final candidates = <String, LocalizationCandidate>{};
  for (final map in maps) {
    for (final anchor in map.anchors) {
      if (!anchor.expired) {
        candidates.putIfAbsent(
          anchor.cloudId,
          () => LocalizationCandidate(map, anchor),
        );
      }
    }
  }
  return candidates;
}

class MapStore {
  static const key = 'madmaps.anchorMaps.v1';
  Future<List<AnchorMap>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((j) => AnchorMap.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  Future<void> save(List<AnchorMap> maps) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode(maps.map((m) => m.toJson()).toList()),
    )) {
      throw StateError('Could not save maps on this phone.');
    }
  }
}

Matrix4 alignMap(Matrix4 mapAnchor, Matrix4 sessionAnchor) =>
    mapAnchor * Matrix4.inverted(sessionAnchor);
double horizontalDistance(Vector3 a, Vector3 b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.z - b.z, 2));
double heading(Matrix4 camera) =>
    math.atan2(-camera.entry(0, 2), camera.entry(2, 2));
double relativeBearing(Matrix4 camera, Vector3 target) {
  final p = camera.getTranslation();
  final angle = math.atan2(target.x - p.x, -(target.z - p.z)) - heading(camera);
  return math.atan2(math.sin(angle), math.cos(angle));
}
