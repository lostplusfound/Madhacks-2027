import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'map_graph_service.dart';

class BuildingEndpoint extends Endpoint {
  static const _service = MapGraphService();

  Future<Building> createBuilding(
    Session session,
    String buildingId,
    String name,
    String? address,
  ) => _service.createBuilding(
    session,
    buildingId: buildingId,
    name: name,
    address: address,
  );

  Future<Building?> getBuilding(Session session, String buildingId) =>
      _service.getBuilding(session, buildingId);

  Future<List<Building>> listBuildings(
    Session session,
    int limit,
    int offset,
  ) => _service.listBuildings(session, limit: limit, offset: offset);
}
