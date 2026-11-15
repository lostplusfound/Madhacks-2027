import 'dart:convert';
import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../mapping/place_map_validation.dart';

class PlaceMapEndpoint extends Endpoint {
  /// The local prototype shares maps explicitly saved by a human reviewer.
  Future<PlaceMap> saveMap(
    Session session,
    String content,
    String buildingName,
    String floorLabel,
    String? mapId,
    int? expectedVersion,
  ) async {
    if (session.serverpod.runMode != ServerpodRunMode.development &&
        session.serverpod.runMode != ServerpodRunMode.test) {
      throw StateError(
        'Map uploads are available in the local prototype only.',
      );
    }
    buildingName = buildingName.trim();
    floorLabel = floorLabel.trim();
    if (buildingName.isEmpty ||
        buildingName.length > 120 ||
        floorLabel.isEmpty ||
        floorLabel.length > 80) {
      throw ArgumentError('Enter a building and floor name.');
    }
    final document = validatePlaceMap(content);
    final normalized = jsonEncode(document);
    final id =
        mapId ??
        'places-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    if (!RegExp(r'^places-[a-f0-9]{32}$').hasMatch(id)) {
      throw ArgumentError('Invalid map ID.');
    }
    return session.db.transaction((transaction) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(hashtext(@mapId))',
        parameters: QueryParameters.named({'mapId': id}),
        transaction: transaction,
      );
      final existing = await PlaceMap.db.findFirstRow(
        session,
        where: (t) => t.mapId.equals(id),
        transaction: transaction,
      );
      if (mapId != null &&
          (existing == null || existing.version != expectedVersion)) {
        throw MapApiException(
          code: 'mapConflict',
          message: 'This map changed. Reopen it before saving again.',
        );
      }
      if (existing == null) {
        return PlaceMap.db.insertRow(
          session,
          PlaceMap(
            mapId: id,
            buildingName: buildingName,
            floorLabel: floorLabel,
            mapJson: normalized,
          ),
          transaction: transaction,
        );
      }
      return PlaceMap.db.updateRow(
        session,
        existing.copyWith(
          buildingName: buildingName,
          floorLabel: floorLabel,
          mapJson: normalized,
          version: existing.version + 1,
          updatedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    });
  }

  Future<List<PlaceMapSummary>> listMaps(Session session) async {
    final maps = await PlaceMap.db.find(session, orderBy: (t) => t.updatedAt);
    return maps
        .map(
          (m) => PlaceMapSummary(
            mapId: m.mapId,
            buildingName: m.buildingName,
            floorLabel: m.floorLabel,
            version: m.version,
            placesJson: jsonEncode((jsonDecode(m.mapJson) as Map)['places']),
          ),
        )
        .toList();
  }

  Future<PlaceMap> getMap(Session session, String mapId) async {
    final map = await PlaceMap.db.findFirstRow(
      session,
      where: (t) => t.mapId.equals(mapId),
    );
    if (map == null) {
      throw MapApiException(
        code: 'not_found',
        message: 'Saved map was not found.',
      );
    }
    return map;
  }
}
