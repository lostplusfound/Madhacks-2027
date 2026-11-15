import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'map_graph_service.dart';

class LocationEndpoint extends Endpoint {
  static const _service = MapGraphService();

  Future<Locations> createLocation(
    Session session,
    String graphId,
    int expectedGraphVersion,
    LocationInput location,
  ) async {
    final snapshot = await _mutate(
      session,
      graphId,
      expectedGraphVersion,
      creates: [location],
    );
    return snapshot.locations.firstWhere(
      (row) => row.locationId == location.locationId,
    );
  }

  Future<Locations?> getLocation(
    Session session,
    String graphId,
    String locationId,
  ) async {
    final snapshot = await _service.getGraph(session, graphId);
    if (snapshot == null) return null;
    return snapshot.locations
        .where((row) => row.locationId == locationId)
        .firstOrNull;
  }

  Future<List<Locations>> listLocations(
    Session session,
    String graphId,
    int? floorNumber,
    LocationCategory? category,
  ) async {
    final snapshot = await _service.getGraph(session, graphId);
    if (snapshot == null) return const [];
    return snapshot.locations
        .where(
          (row) =>
              (floorNumber == null || row.floor == floorNumber) &&
              (category == null || row.category == category),
        )
        .toList();
  }

  Future<Locations> updateLocation(
    Session session,
    String graphId,
    int expectedGraphVersion,
    LocationInput location,
  ) async {
    final snapshot = await _mutate(
      session,
      graphId,
      expectedGraphVersion,
      updates: [location],
    );
    return snapshot.locations.firstWhere(
      (row) => row.locationId == location.locationId,
    );
  }

  Future<void> deleteLocation(
    Session session,
    String graphId,
    int expectedGraphVersion,
    String locationId,
  ) async {
    await _mutate(
      session,
      graphId,
      expectedGraphVersion,
      deletes: [locationId],
    );
  }

  Future<MapGraphSnapshot> _mutate(
    Session session,
    String graphId,
    int expectedGraphVersion, {
    List<LocationInput> creates = const [],
    List<LocationInput> updates = const [],
    List<String> deletes = const [],
  }) => _service.patchGraph(
    session,
    GraphPatchRequest(
      graphId: graphId,
      expectedVersion: expectedGraphVersion,
      nodesToCreate: const [],
      nodesToUpdate: const [],
      nodeIdsToDelete: const [],
      edgesToCreate: const [],
      edgesToUpdate: const [],
      edgeIdsToDelete: const [],
      locationsToCreate: creates,
      locationsToUpdate: updates,
      locationIdsToDelete: deletes,
    ),
  );
}
