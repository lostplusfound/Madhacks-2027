import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'map_graph_service.dart';

class MapNodeEndpoint extends Endpoint {
  static const _service = MapGraphService();

  Future<Nodes> createNode(
    Session session,
    String graphId,
    int expectedGraphVersion,
    MapNodeInput node,
  ) async {
    final snapshot = await _service.patchGraph(
      session,
      GraphPatchRequest(
        graphId: graphId,
        expectedVersion: expectedGraphVersion,
        nodesToCreate: [node],
        nodesToUpdate: const [],
        nodeIdsToDelete: const [],
        edgesToCreate: const [],
        edgesToUpdate: const [],
        edgeIdsToDelete: const [],
        locationsToCreate: const [],
        locationsToUpdate: const [],
        locationIdsToDelete: const [],
      ),
    );
    return snapshot.nodes.firstWhere((row) => row.nodeId == node.nodeId);
  }

  /// Creates a routable contribution atomically. This is the normal creation
  /// path after a graph has been seeded because active nodes must be connected.
  Future<MapGraphSnapshot> createNodeWithConnections(
    Session session,
    String graphId,
    int expectedGraphVersion,
    MapNodeInput node,
    List<MapEdgeInput> edges,
    LocationInput? location,
  ) => _service.patchGraph(
    session,
    GraphPatchRequest(
      graphId: graphId,
      expectedVersion: expectedGraphVersion,
      nodesToCreate: [node],
      nodesToUpdate: const [],
      nodeIdsToDelete: const [],
      edgesToCreate: edges,
      edgesToUpdate: const [],
      edgeIdsToDelete: const [],
      locationsToCreate: location == null ? const [] : [location],
      locationsToUpdate: const [],
      locationIdsToDelete: const [],
    ),
  );

  Future<Nodes?> getNode(Session session, String graphId, String nodeId) async {
    final snapshot = await _service.getGraph(session, graphId);
    if (snapshot == null) return null;
    return snapshot.nodes.where((row) => row.nodeId == nodeId).firstOrNull;
  }

  Future<List<Nodes>> listNodes(
    Session session,
    String graphId,
    int? floorNumber,
  ) async {
    final snapshot = await _service.getGraph(session, graphId);
    if (snapshot == null) return const [];
    return snapshot.nodes
        .where((row) => floorNumber == null || row.floor == floorNumber)
        .toList();
  }

  Future<Nodes> updateNode(
    Session session,
    String graphId,
    int expectedGraphVersion,
    MapNodeInput node,
  ) async {
    final snapshot = await _service.patchGraph(
      session,
      GraphPatchRequest(
        graphId: graphId,
        expectedVersion: expectedGraphVersion,
        nodesToCreate: const [],
        nodesToUpdate: [node],
        nodeIdsToDelete: const [],
        edgesToCreate: const [],
        edgesToUpdate: const [],
        edgeIdsToDelete: const [],
        locationsToCreate: const [],
        locationsToUpdate: const [],
        locationIdsToDelete: const [],
      ),
    );
    return snapshot.nodes.firstWhere((row) => row.nodeId == node.nodeId);
  }

  Future<void> deleteNode(
    Session session,
    String graphId,
    int expectedGraphVersion,
    String nodeId,
  ) async {
    final snapshot = await _service.getGraph(session, graphId);
    if (snapshot == null) {
      throw MapApiException(code: 'not_found', message: 'Graph was not found.');
    }
    final connectedEdges = snapshot.edges
        .where((row) => row.fromNodeId == nodeId || row.toNodeId == nodeId)
        .map((row) => row.edgeId!)
        .toList();
    final attachedLocations = snapshot.locations
        .where((row) => row.routeNodeId == nodeId)
        .map((row) => row.locationId)
        .toList();
    await _service.patchGraph(
      session,
      GraphPatchRequest(
        graphId: graphId,
        expectedVersion: expectedGraphVersion,
        nodesToCreate: const [],
        nodesToUpdate: const [],
        nodeIdsToDelete: [nodeId],
        edgesToCreate: const [],
        edgesToUpdate: const [],
        edgeIdsToDelete: connectedEdges,
        locationsToCreate: const [],
        locationsToUpdate: const [],
        locationIdsToDelete: attachedLocations,
      ),
    );
  }
}
