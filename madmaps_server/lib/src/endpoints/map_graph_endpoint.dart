import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'map_graph_service.dart';

class MapGraphEndpoint extends Endpoint {
  static const _service = MapGraphService();

  Future<MapGraphSnapshot> createGraph(
    Session session,
    CreateGraphRequest request,
  ) => _service.createGraph(session, request);

  Future<GraphReadResult> getGraph(
    Session session,
    String graphId,
    int? ifVersion,
  ) => _service.readGraph(session, graphId, ifVersion: ifVersion);

  Future<List<MapGraph>> listGraphs(
    Session session,
    String? buildingId,
    int limit,
    int offset,
  ) => _service.listGraphs(
    session,
    buildingId: buildingId,
    limit: limit,
    offset: offset,
  );

  Future<MapGraphSnapshot> patchGraph(
    Session session,
    GraphPatchRequest request,
  ) => _service.patchGraph(session, request);

  Future<MapGraphSnapshot> replaceGraph(
    Session session,
    ReplaceGraphRequest request,
  ) => _service.replaceGraph(session, request);

  Future<void> deleteGraph(
    Session session,
    String graphId,
    int expectedVersion,
  ) => _service.deleteGraph(session, graphId, expectedVersion);
}
