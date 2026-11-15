import 'dart:convert';
import '../../client.dart';
import 'floor_data.dart';
import 'map_repository.dart';

class SavedPlaceMap {
  const SavedPlaceMap({
    required this.mapId,
    required this.buildingName,
    required this.floorLabel,
    required this.version,
    required this.places,
    this.mapJson,
  });
  final String mapId, buildingName, floorLabel;
  final int version;
  final List<Map<String, dynamic>> places;
  final String? mapJson;
  String destinationId(String pinId) => '$mapId/$pinId';
  List<FloorLocation> get destinations => places
      .map(
        (p) => FloorLocation(
          destinationId(p['id'] as String),
          p['label'] as String,
          buildingName,
          null,
          buildingName: buildingName,
          placeMapId: mapId,
          mapFloorLabel: floorLabel,
        ),
      )
      .toList();
}

abstract interface class PlaceMapsApi {
  Future<List<SavedPlaceMap>> list();
  Future<SavedPlaceMap> get(String id);
  Future<SavedPlaceMap> save(
    String content,
    String buildingName,
    String floorLabel, {
    String? mapId,
    int? expectedVersion,
  });
}

class ServerpodPlaceMapsApi implements PlaceMapsApi {
  @override
  Future<List<SavedPlaceMap>> list() async {
    await initializeClient();
    return (await client.placeMap.listMaps())
        .map(
          (m) => SavedPlaceMap(
            mapId: m.mapId,
            buildingName: m.buildingName,
            floorLabel: m.floorLabel,
            version: m.version,
            places: _pins(m.placesJson),
          ),
        )
        .toList();
  }

  @override
  Future<SavedPlaceMap> get(String id) async {
    await initializeClient();
    final m = await client.placeMap.getMap(id);
    return SavedPlaceMap(
      mapId: m.mapId,
      buildingName: m.buildingName,
      floorLabel: m.floorLabel,
      version: m.version,
      mapJson: m.mapJson,
      places: _pins(jsonEncode((jsonDecode(m.mapJson) as Map)['places'])),
    );
  }

  @override
  Future<SavedPlaceMap> save(
    String content,
    String buildingName,
    String floorLabel, {
    String? mapId,
    int? expectedVersion,
  }) async {
    await initializeClient();
    final m = await client.placeMap.saveMap(
      content,
      buildingName,
      floorLabel,
      mapId,
      expectedVersion,
    );
    return SavedPlaceMap(
      mapId: m.mapId,
      buildingName: m.buildingName,
      floorLabel: m.floorLabel,
      version: m.version,
      mapJson: m.mapJson,
      places: _pins(jsonEncode((jsonDecode(m.mapJson) as Map)['places'])),
    );
  }

  static List<Map<String, dynamic>> _pins(String value) =>
      (jsonDecode(value) as List)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
}

/// Keep point maps searchable without inventing routing nodes or edges.
class CatalogMapRepository implements MapRepository {
  CatalogMapRepository(this.base);
  final MapRepository base;
  List<SavedPlaceMap> maps = [];
  List<FloorLocation> get destinations =>
      maps.expand((m) => m.destinations).toList();
  @override
  Future<FloorGraph> load() => base.load();
  @override
  List<String> get categories => {
    ...base.categories,
    for (final m in maps)
      for (final p in m.places) p['category'] as String,
  }.toList();
  @override
  String? categoryOf(String id) {
    for (final m in maps) {
      for (final p in m.places) {
        if (m.destinationId(p['id'] as String) == id) {
          return p['category'] as String;
        }
      }
    }
    return base.categoryOf(id);
  }

  @override
  Future<List<String>> search(String query, {String? category}) async {
    final q = query.trim().toLowerCase();
    final local = [
      for (final m in maps)
        for (final p in m.places)
          if ((category == null || category == p['category']) &&
              '${p['label']} ${m.buildingName} ${m.floorLabel}'
                  .toLowerCase()
                  .contains(q))
            m.destinationId(p['id'] as String),
    ];
    final builtIn = await base.search(query, category: category);
    return [...builtIn, ...local];
  }
}
