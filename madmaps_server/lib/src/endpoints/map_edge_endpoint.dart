import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'map_graph_service.dart';

class MapEdgeEndpoint extends Endpoint {
  static const _service = MapGraphService();

  Future<Edge> createEdge(
    Session session,
    String graphId,
    int expectedGraphVersion,
    MapEdgeInput edge,
  ) async {
    final snapshot = await _mutate(
      session,
      graphId,
      expectedGraphVersion,
      creates: [edge],
    );
    return snapshot.edges.firstWhere((row) => row.edgeId == edge.edgeId);
  }

  Future<Edge?> getEdge(Session session, String graphId, String edgeId) async {
    final snapshot = await _service.getGraph(session, graphId);
    if (snapshot == null) return null;
    return snapshot.edges.where((row) => row.edgeId == edgeId).firstOrNull;
  }

  Future<List<Edge>> listEdges(Session session, String graphId) async {
    final snapshot = await _service.getGraph(session, graphId);
    return snapshot?.edges ?? const [];
  }

  Future<Edge> updateEdge(
    Session session,
    String graphId,
    int expectedGraphVersion,
    MapEdgeInput edge,
  ) async {
    final snapshot = await _mutate(
      session,
      graphId,
      expectedGraphVersion,
      updates: [edge],
    );
    return snapshot.edges.firstWhere((row) => row.edgeId == edge.edgeId);
  }

  Future<void> deleteEdge(
    Session session,
    String graphId,
    int expectedGraphVersion,
    String edgeId,
  ) async {
    await _mutate(
      session,
      graphId,
      expectedGraphVersion,
      deletes: [edgeId],
    );
  }

  Future<MapGraphSnapshot> _mutate(
    Session session,
    String graphId,
    int expectedGraphVersion, {
    List<MapEdgeInput> creates = const [],
    List<MapEdgeInput> updates = const [],
    List<String> deletes = const [],
  }) => _service.patchGraph(
    session,
    GraphPatchRequest(
      graphId: graphId,
      expectedVersion: expectedGraphVersion,
      nodesToCreate: const [],
      nodesToUpdate: const [],
      nodeIdsToDelete: const [],
      edgesToCreate: creates,
      edgesToUpdate: updates,
      edgeIdsToDelete: deletes,
      locationsToCreate: const [],
      locationsToUpdate: const [],
      locationIdsToDelete: const [],
    ),
  );
}
