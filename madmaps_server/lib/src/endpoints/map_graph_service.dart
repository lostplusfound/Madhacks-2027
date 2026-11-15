import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Owns validation, authorization, and transactional persistence for map data.
///
/// Endpoints deliberately stay thin so whole-graph and individual mutations
/// cannot drift into subtly different validation rules.
class MapGraphService {
  const MapGraphService();

  String requireUser(Session session) {
    final userId = session.authenticated?.userIdentifier;
    if (userId == null) {
      throw MapApiException(
        code: 'authentication_required',
        message: 'Sign in before changing map data.',
      );
    }
    return userId;
  }

  Future<Building> createBuilding(
    Session session, {
    required String buildingId,
    required String name,
    String? address,
  }) async {
    final userId = requireUser(session);
    _requireIdentifier(buildingId, 'buildingId');
    _requireText(name, 'name');

    final existing = await Building.db.findFirstRow(
      session,
      where: (t) => t.buildingId.equals(buildingId),
    );
    if (existing != null) {
      throw _conflict('A building with this ID already exists.');
    }

    return Building.db.insertRow(
      session,
      Building(
        buildingId: buildingId.trim(),
        name: name.trim(),
        address: _trimmedOrNull(address),
        createdBy: userId,
      ),
    );
  }

  Future<List<Building>> listBuildings(
    Session session, {
    int limit = 50,
    int offset = 0,
  }) {
    _validatePage(limit, offset);
    return Building.db.find(
      session,
      where: (t) =>
          t.status.equals(MapEntityStatus.active) & t.deletedAt.equals(null),
      orderBy: (t) => t.name,
      limit: limit,
      offset: offset,
    );
  }

  Future<Building?> getBuilding(Session session, String buildingId) {
    return Building.db.findFirstRow(
      session,
      where: (t) =>
          t.buildingId.equals(buildingId) &
          t.status.equals(MapEntityStatus.active) &
          t.deletedAt.equals(null),
    );
  }

  Future<MapGraphSnapshot> createGraph(
    Session session,
    CreateGraphRequest request,
  ) async {
    final userId = requireUser(session);
    _requireIdentifier(request.graphId, 'graphId');
    _requireText(request.name, 'name');

    final building = await getBuilding(session, request.buildingId);
    if (building == null || building.id == null) {
      throw _notFound('Building');
    }
    final duplicate = await MapGraph.db.findFirstRow(
      session,
      where: (t) => t.graphId.equals(request.graphId),
    );
    if (duplicate != null) {
      throw _conflict('A graph with this ID already exists.');
    }

    _validateContent(
      floors: request.floors,
      nodes: request.nodes,
      edges: request.edges,
      locations: request.locations,
    );

    late MapGraph graph;
    await session.db.transaction((transaction) async {
      graph = await MapGraph.db.insertRow(
        session,
        MapGraph(
          graphId: request.graphId.trim(),
          buildingId: building.id!,
          name: request.name.trim(),
          ownerId: userId,
        ),
        transaction: transaction,
      );

      final floors = await _upsertFloors(
        session,
        building: building,
        inputs: request.floors,
        transaction: transaction,
      );
      await _insertContent(
        session,
        graph: graph,
        floors: floors,
        nodes: request.nodes,
        edges: request.edges,
        locations: request.locations,
        userId: userId,
        transaction: transaction,
      );
    });

    return (await getGraph(session, graph.graphId))!;
  }

  Future<MapGraphSnapshot?> getGraph(Session session, String graphId) async {
    final graph = await MapGraph.db.findFirstRow(
      session,
      where: (t) =>
          t.graphId.equals(graphId) &
          t.status.equals(MapEntityStatus.active) &
          t.deletedAt.equals(null),
    );
    if (graph == null || graph.id == null) return null;

    final building = await Building.db.findById(session, graph.buildingId);
    if (building == null) {
      throw MapApiException(
        code: 'invalid_graph',
        message: 'The graph references a missing building.',
      );
    }

    final results = await Future.wait<List<dynamic>>([
      Floor.db.find(
        session,
        where: (t) => t.buildingId.equals(graph.buildingId),
        orderBy: (t) => t.floorNumber,
      ),
      Nodes.db.find(
        session,
        where: (t) =>
            t.graphId.equals(graph.id) &
            t.status.equals(MapEntityStatus.active) &
            t.deletedAt.equals(null),
        orderBy: (t) => t.nodeId,
      ),
      Edge.db.find(
        session,
        where: (t) =>
            t.graphId.equals(graph.id) &
            t.status.equals(MapEntityStatus.active) &
            t.deletedAt.equals(null),
        orderBy: (t) => t.edgeId,
      ),
      Locations.db.find(
        session,
        where: (t) =>
            t.graphId.equals(graph.id) &
            t.status.equals(MapEntityStatus.active) &
            t.deletedAt.equals(null),
        orderBy: (t) => t.locationId,
      ),
    ]);

    return MapGraphSnapshot(
      graph: graph,
      building: building,
      floors: results[0].cast<Floor>(),
      nodes: results[1].cast<Nodes>(),
      edges: results[2].cast<Edge>(),
      locations: results[3].cast<Locations>(),
    );
  }

  Future<GraphReadResult> readGraph(
    Session session,
    String graphId, {
    int? ifVersion,
  }) async {
    final snapshot = await getGraph(session, graphId);
    if (snapshot == null) throw _notFound('Graph');
    if (ifVersion != null && snapshot.graph.version == ifVersion) {
      return GraphReadResult(unchanged: true);
    }
    return GraphReadResult(unchanged: false, snapshot: snapshot);
  }

  Future<List<MapGraph>> listGraphs(
    Session session, {
    String? buildingId,
    int limit = 50,
    int offset = 0,
  }) async {
    _validatePage(limit, offset);
    int? databaseBuildingId;
    if (buildingId != null) {
      final building = await getBuilding(session, buildingId);
      if (building == null) return const [];
      databaseBuildingId = building.id;
    }

    return MapGraph.db.find(
      session,
      where: (t) {
        var expression =
            t.status.equals(MapEntityStatus.active) & t.deletedAt.equals(null);
        if (databaseBuildingId != null) {
          expression = expression & t.buildingId.equals(databaseBuildingId);
        }
        return expression;
      },
      orderBy: (t) => t.name,
      limit: limit,
      offset: offset,
    );
  }

  Future<MapGraphSnapshot> patchGraph(
    Session session,
    GraphPatchRequest request,
  ) async {
    final userId = requireUser(session);
    final snapshot = await getGraph(session, request.graphId);
    if (snapshot == null || snapshot.graph.id == null) {
      throw _notFound('Graph');
    }
    if (snapshot.graph.version != request.expectedVersion) {
      throw MapApiException(
        code: 'version_conflict',
        message: 'The graph changed after it was loaded.',
      );
    }

    final prospectiveNodes = {
      for (final node in snapshot.nodes)
        node.nodeId: _nodeToInput(node, snapshot),
    };
    final prospectiveEdges = {
      for (final edge in snapshot.edges) edge.edgeId!: _edgeToInput(edge),
    };
    final prospectiveLocations = {
      for (final location in snapshot.locations)
        location.locationId: _locationToInput(location, snapshot),
    };

    for (final id in request.nodeIdsToDelete) {
      prospectiveNodes.remove(id);
    }
    for (final input in [...request.nodesToCreate, ...request.nodesToUpdate]) {
      prospectiveNodes[input.nodeId] = input;
    }
    for (final id in request.edgeIdsToDelete) {
      prospectiveEdges.remove(id);
    }
    for (final input in [...request.edgesToCreate, ...request.edgesToUpdate]) {
      prospectiveEdges[input.edgeId] = input;
    }
    for (final id in request.locationIdsToDelete) {
      prospectiveLocations.remove(id);
    }
    for (final input in [
      ...request.locationsToCreate,
      ...request.locationsToUpdate,
    ]) {
      prospectiveLocations[input.locationId] = input;
    }

    _validateContent(
      floors: snapshot.floors.map(_floorToInput).toList(),
      nodes: prospectiveNodes.values.toList(),
      edges: prospectiveEdges.values.toList(),
      locations: prospectiveLocations.values.toList(),
    );

    await session.db.transaction(
      (transaction) async {
        final lockedGraph = await MapGraph.db.findFirstRow(
          session,
          where: (t) => t.id.equals(snapshot.graph.id),
          transaction: transaction,
        );
        if (lockedGraph == null ||
            lockedGraph.version != request.expectedVersion) {
          throw MapApiException(
            code: 'version_conflict',
            message: 'The graph changed after it was loaded.',
          );
        }

        final floorsByPublicId = {
          for (final floor in snapshot.floors) floor.floorId: floor,
        };
        await _applyNodePatch(
          session,
          graph: lockedGraph,
          floors: floorsByPublicId,
          creates: request.nodesToCreate,
          updates: request.nodesToUpdate,
          deletes: request.nodeIdsToDelete,
          userId: userId,
          transaction: transaction,
        );
        await _applyEdgePatch(
          session,
          graph: lockedGraph,
          floors: floorsByPublicId,
          allNodes: prospectiveNodes,
          creates: request.edgesToCreate,
          updates: request.edgesToUpdate,
          deletes: request.edgeIdsToDelete,
          userId: userId,
          transaction: transaction,
        );
        await _applyLocationPatch(
          session,
          graph: lockedGraph,
          floors: floorsByPublicId,
          creates: request.locationsToCreate,
          updates: request.locationsToUpdate,
          deletes: request.locationIdsToDelete,
          userId: userId,
          transaction: transaction,
        );
        await MapGraph.db.updateRow(
          session,
          lockedGraph.copyWith(
            version: lockedGraph.version + 1,
            updatedAt: DateTime.now().toUtc(),
          ),
          transaction: transaction,
        );
      },
      settings: TransactionSettings(
        isolationLevel: IsolationLevel.serializable,
      ),
    );

    return (await getGraph(session, request.graphId))!;
  }

  Future<MapGraphSnapshot> replaceGraph(
    Session session,
    ReplaceGraphRequest request,
  ) async {
    final userId = requireUser(session);
    final current = await getGraph(session, request.graphId);
    if (current == null) throw _notFound('Graph');
    if (current.graph.ownerId != userId) {
      throw _forbidden('Only the graph owner can replace the whole graph.');
    }
    if (current.graph.version != request.expectedVersion) {
      throw MapApiException(
        code: 'version_conflict',
        message: 'The graph changed after it was loaded.',
      );
    }

    _requireText(request.name, 'name');
    _validateContent(
      floors: request.floors,
      nodes: request.nodes,
      edges: request.edges,
      locations: request.locations,
    );

    final existingNodeIds = {for (final row in current.nodes) row.nodeId};
    final requestedNodeIds = {for (final row in request.nodes) row.nodeId};
    final existingEdgeIds = {for (final row in current.edges) row.edgeId!};
    final requestedEdgeIds = {for (final row in request.edges) row.edgeId};
    final existingLocationIds = {
      for (final row in current.locations) row.locationId,
    };
    final requestedLocationIds = {
      for (final row in request.locations) row.locationId,
    };

    final nodesToCreate = request.nodes
        .where((row) => !existingNodeIds.contains(row.nodeId))
        .toList();
    final nodesToUpdate = request.nodes
        .where((row) => existingNodeIds.contains(row.nodeId))
        .toList();
    final nodeIdsToDelete = existingNodeIds
        .difference(requestedNodeIds)
        .toList();
    final edgesToCreate = request.edges
        .where((row) => !existingEdgeIds.contains(row.edgeId))
        .toList();
    final edgesToUpdate = request.edges
        .where((row) => existingEdgeIds.contains(row.edgeId))
        .toList();
    final edgeIdsToDelete = existingEdgeIds
        .difference(requestedEdgeIds)
        .toList();
    final locationsToCreate = request.locations
        .where((row) => !existingLocationIds.contains(row.locationId))
        .toList();
    final locationsToUpdate = request.locations
        .where((row) => existingLocationIds.contains(row.locationId))
        .toList();
    final locationIdsToDelete = existingLocationIds
        .difference(requestedLocationIds)
        .toList();
    final requestedNodes = {
      for (final node in request.nodes) node.nodeId: node,
    };

    await session.db.transaction(
      (transaction) async {
        final lockedGraph = await MapGraph.db.findFirstRow(
          session,
          where: (t) => t.id.equals(current.graph.id),
          transaction: transaction,
        );
        if (lockedGraph == null ||
            lockedGraph.version != request.expectedVersion) {
          throw MapApiException(
            code: 'version_conflict',
            message: 'The graph changed after it was loaded.',
          );
        }
        if (lockedGraph.ownerId != userId) {
          throw _forbidden('Only the graph owner can replace the whole graph.');
        }

        final floors = await _upsertFloors(
          session,
          building: current.building,
          inputs: request.floors,
          transaction: transaction,
        );
        final floorsByPublicId = {
          for (final floor in floors) floor.floorId: floor,
        };

        await _applyNodePatch(
          session,
          graph: lockedGraph,
          floors: floorsByPublicId,
          creates: nodesToCreate,
          updates: nodesToUpdate,
          deletes: nodeIdsToDelete,
          userId: userId,
          transaction: transaction,
        );
        await _applyEdgePatch(
          session,
          graph: lockedGraph,
          floors: floorsByPublicId,
          allNodes: requestedNodes,
          creates: edgesToCreate,
          updates: edgesToUpdate,
          deletes: edgeIdsToDelete,
          userId: userId,
          transaction: transaction,
        );
        await _applyLocationPatch(
          session,
          graph: lockedGraph,
          floors: floorsByPublicId,
          creates: locationsToCreate,
          updates: locationsToUpdate,
          deletes: locationIdsToDelete,
          userId: userId,
          transaction: transaction,
        );
        await MapGraph.db.updateRow(
          session,
          lockedGraph.copyWith(
            name: request.name.trim(),
            version: lockedGraph.version + 1,
            updatedAt: DateTime.now().toUtc(),
          ),
          transaction: transaction,
        );
      },
      settings: TransactionSettings(
        isolationLevel: IsolationLevel.serializable,
      ),
    );

    return (await getGraph(session, request.graphId))!;
  }

  Future<void> deleteGraph(
    Session session,
    String graphId,
    int expectedVersion,
  ) async {
    final userId = requireUser(session);
    final snapshot = await getGraph(session, graphId);
    if (snapshot == null || snapshot.graph.id == null) {
      throw _notFound('Graph');
    }
    if (snapshot.graph.ownerId != userId) {
      throw _forbidden('Only the graph owner can delete this graph.');
    }
    if (snapshot.graph.version != expectedVersion) {
      throw MapApiException(
        code: 'version_conflict',
        message: 'The graph changed after it was loaded.',
      );
    }

    final now = DateTime.now().toUtc();
    await session.db.transaction((transaction) async {
      for (final node in snapshot.nodes) {
        await Nodes.db.updateRow(
          session,
          node.copyWith(
            status: MapEntityStatus.deleted,
            deletedAt: now,
            updatedAt: now,
            updatedBy: userId,
          ),
          transaction: transaction,
        );
      }
      for (final edge in snapshot.edges) {
        await Edge.db.updateRow(
          session,
          edge.copyWith(
            status: MapEntityStatus.deleted,
            deletedAt: now,
            updatedAt: now,
            updatedBy: userId,
          ),
          transaction: transaction,
        );
      }
      for (final location in snapshot.locations) {
        await Locations.db.updateRow(
          session,
          location.copyWith(
            status: MapEntityStatus.deleted,
            deletedAt: now,
            updatedAt: now,
            updatedBy: userId,
          ),
          transaction: transaction,
        );
      }
      await MapGraph.db.updateRow(
        session,
        snapshot.graph.copyWith(
          status: MapEntityStatus.deleted,
          deletedAt: now,
          updatedAt: now,
          version: snapshot.graph.version + 1,
        ),
        transaction: transaction,
      );
    });
  }

  Future<List<SearchResult>> searchLocations(
    Session session, {
    required String graphId,
    String? query,
    LocationCategory? category,
    int? floorNumber,
    int limit = 25,
  }) async {
    if (limit < 1 || limit > 100) {
      throw MapApiException(
        code: 'invalid_page',
        message: 'limit must be between 1 and 100.',
      );
    }
    final snapshot = await getGraph(session, graphId);
    if (snapshot == null) throw _notFound('Graph');
    final normalizedQuery = _normalize(query ?? '');
    final synonymCategory = _categoryForSynonym(normalizedQuery);
    final requestedCategory = category ?? synonymCategory;
    final nodesById = {for (final node in snapshot.nodes) node.nodeId: node};

    final results = <SearchResult>[];
    for (final location in snapshot.locations) {
      if (floorNumber != null && location.floor != floorNumber) continue;
      if (requestedCategory != null && location.category != requestedCategory) {
        continue;
      }
      var score = _searchScore(location, normalizedQuery);
      if (score == 0 && synonymCategory == location.category) score = 40;
      if (normalizedQuery.isNotEmpty &&
          score == 0 &&
          requestedCategory == null) {
        continue;
      }
      final node = location.routeNodeId == null
          ? null
          : nodesById[location.routeNodeId];
      if (location.routeNodeId != null && node == null) continue;
      results.add(SearchResult(location: location, node: node, score: score));
    }
    results.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      if (scoreOrder != 0) return scoreOrder;
      return (a.location.name ?? a.location.roomNumber ?? a.location.locationId)
          .compareTo(
            b.location.name ?? b.location.roomNumber ?? b.location.locationId,
          );
    });
    return results.take(limit).toList();
  }

  Future<MapReport> reportEntity(
    Session session, {
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? notes,
  }) async {
    final userId = requireUser(session);
    _requireIdentifier(targetId, 'targetId');
    await _ensureTargetExists(session, targetType, targetId);
    final duplicate = await MapReport.db.findFirstRow(
      session,
      where: (t) =>
          t.reporterId.equals(userId) &
          t.targetType.equals(targetType) &
          t.targetId.equals(targetId) &
          t.status.equals(ReportStatus.open),
    );
    if (duplicate != null) {
      throw _conflict('You already have an open report for this item.');
    }
    return MapReport.db.insertRow(
      session,
      MapReport(
        reportId: const Uuid().v4(),
        targetType: targetType,
        targetId: targetId,
        reporterId: userId,
        reason: reason,
        notes: _trimmedOrNull(notes),
      ),
    );
  }

  Future<List<MapReport>> listMyReports(
    Session session, {
    int limit = 50,
    int offset = 0,
  }) {
    final userId = requireUser(session);
    _validatePage(limit, offset);
    return MapReport.db.find(
      session,
      where: (t) => t.reporterId.equals(userId),
      orderBy: (t) => t.createdAt,
      limit: limit,
      offset: offset,
    );
  }

  Future<MapReport> withdrawReport(Session session, String reportId) async {
    final userId = requireUser(session);
    final report = await MapReport.db.findFirstRow(
      session,
      where: (t) => t.reportId.equals(reportId),
    );
    if (report == null) throw _notFound('Report');
    if (report.reporterId != userId) {
      throw _forbidden('You can withdraw only your own reports.');
    }
    return MapReport.db.updateRow(
      session,
      report.copyWith(
        status: ReportStatus.withdrawn,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<List<Floor>> _upsertFloors(
    Session session, {
    required Building building,
    required List<FloorInput> inputs,
    required Transaction transaction,
  }) async {
    final floors = <Floor>[];
    for (final input in inputs) {
      final existing = await Floor.db.findFirstRow(
        session,
        where: (t) =>
            t.buildingId.equals(building.id) & t.floorId.equals(input.floorId),
        transaction: transaction,
      );
      if (existing == null) {
        floors.add(
          await Floor.db.insertRow(
            session,
            Floor(
              floorId: input.floorId,
              buildingId: building.id!,
              floorNumber: input.floorNumber,
              name: _trimmedOrNull(input.name),
              width: input.width,
              height: input.height,
              metersPerUnit: input.metersPerUnit,
            ),
            transaction: transaction,
          ),
        );
      } else {
        if (existing.floorNumber != input.floorNumber ||
            existing.width != input.width ||
            existing.height != input.height ||
            existing.metersPerUnit != input.metersPerUnit) {
          throw _conflict(
            'Floor ${input.floorId} already exists with different calibration.',
          );
        }
        floors.add(existing);
      }
    }
    return floors;
  }

  Future<void> _insertContent(
    Session session, {
    required MapGraph graph,
    required List<Floor> floors,
    required List<MapNodeInput> nodes,
    required List<MapEdgeInput> edges,
    required List<LocationInput> locations,
    required String userId,
    required Transaction transaction,
  }) async {
    final floorsByPublicId = {for (final floor in floors) floor.floorId: floor};
    final nodesByPublicId = {for (final node in nodes) node.nodeId: node};
    final now = DateTime.now().toUtc();
    await Nodes.db.insert(
      session,
      nodes.map((input) {
        final floor = floorsByPublicId[input.floorId]!;
        return Nodes(
          nodeId: input.nodeId,
          graphId: graph.id,
          floorId: floor.id,
          floor: floor.floorNumber,
          x: input.x,
          y: input.y,
          locationId: input.locationId,
          kind: input.kind,
          createdBy: userId,
          updatedBy: userId,
          createdAt: now,
          updatedAt: now,
        );
      }).toList(),
      transaction: transaction,
    );
    await Locations.db.insert(
      session,
      locations.map((input) {
        final floor = floorsByPublicId[input.floorId]!;
        return Locations(
          locationId: input.locationId,
          graphId: graph.id,
          floorId: floor.id,
          floor: floor.floorNumber,
          roomNumber: _trimmedOrNull(input.roomNumber),
          name: _trimmedOrNull(input.name),
          category: input.category,
          aliases: _trimmedOrNull(input.aliases),
          routeNodeId: input.routeNodeId,
          createdBy: userId,
          updatedBy: userId,
          createdAt: now,
          updatedAt: now,
        );
      }).toList(),
      transaction: transaction,
    );
    await Edge.db.insert(
      session,
      edges.map((input) {
        final cost = _edgeCost(
          input,
          nodesByPublicId: nodesByPublicId,
          floorsByPublicId: floorsByPublicId,
        );
        return Edge(
          edgeId: input.edgeId,
          graphId: graph.id,
          fromNodeId: input.fromNodeId,
          toNodeId: input.toNodeId,
          type: input.type,
          costPx: cost,
          bidirectional: input.bidirectional,
          createdBy: userId,
          updatedBy: userId,
          createdAt: now,
          updatedAt: now,
        );
      }).toList(),
      transaction: transaction,
    );
  }

  Future<void> _applyNodePatch(
    Session session, {
    required MapGraph graph,
    required Map<String, Floor> floors,
    required List<MapNodeInput> creates,
    required List<MapNodeInput> updates,
    required List<String> deletes,
    required String userId,
    required Transaction transaction,
  }) async {
    final now = DateTime.now().toUtc();
    for (final input in creates) {
      final duplicate = await Nodes.db.findFirstRow(
        session,
        where: (t) => t.nodeId.equals(input.nodeId),
        transaction: transaction,
      );
      if (duplicate != null) throw _conflict('Node ${input.nodeId} exists.');
      final floor = floors[input.floorId]!;
      await Nodes.db.insertRow(
        session,
        Nodes(
          nodeId: input.nodeId,
          graphId: graph.id,
          floorId: floor.id,
          floor: floor.floorNumber,
          x: input.x,
          y: input.y,
          locationId: input.locationId,
          kind: input.kind,
          createdBy: userId,
          updatedBy: userId,
        ),
        transaction: transaction,
      );
    }
    for (final input in updates) {
      final row = await _ownedNode(
        session,
        graph.id!,
        input.nodeId,
        userId,
        transaction,
      );
      final floor = floors[input.floorId]!;
      await Nodes.db.updateRow(
        session,
        row.copyWith(
          floorId: floor.id,
          floor: floor.floorNumber,
          x: input.x,
          y: input.y,
          locationId: input.locationId,
          kind: input.kind,
          updatedBy: userId,
          updatedAt: now,
          version: row.version + 1,
        ),
        transaction: transaction,
      );
    }
    for (final nodeId in deletes) {
      final row = await _ownedNode(
        session,
        graph.id!,
        nodeId,
        userId,
        transaction,
      );
      await Nodes.db.updateRow(
        session,
        row.copyWith(
          status: MapEntityStatus.deleted,
          deletedAt: now,
          updatedBy: userId,
          updatedAt: now,
          version: row.version + 1,
        ),
        transaction: transaction,
      );
    }
  }

  Future<void> _applyEdgePatch(
    Session session, {
    required MapGraph graph,
    required Map<String, Floor> floors,
    required Map<String, MapNodeInput> allNodes,
    required List<MapEdgeInput> creates,
    required List<MapEdgeInput> updates,
    required List<String> deletes,
    required String userId,
    required Transaction transaction,
  }) async {
    final now = DateTime.now().toUtc();
    for (final input in creates) {
      final duplicate = await Edge.db.findFirstRow(
        session,
        where: (t) => t.edgeId.equals(input.edgeId),
        transaction: transaction,
      );
      if (duplicate != null) throw _conflict('Edge ${input.edgeId} exists.');
      await Edge.db.insertRow(
        session,
        Edge(
          edgeId: input.edgeId,
          graphId: graph.id,
          fromNodeId: input.fromNodeId,
          toNodeId: input.toNodeId,
          type: input.type,
          costPx: _edgeCost(
            input,
            nodesByPublicId: allNodes,
            floorsByPublicId: floors,
          ),
          bidirectional: input.bidirectional,
          createdBy: userId,
          updatedBy: userId,
        ),
        transaction: transaction,
      );
    }
    for (final input in updates) {
      final row = await _ownedEdge(
        session,
        graph.id!,
        input.edgeId,
        userId,
        transaction,
      );
      await Edge.db.updateRow(
        session,
        row.copyWith(
          fromNodeId: input.fromNodeId,
          toNodeId: input.toNodeId,
          type: input.type,
          costPx: _edgeCost(
            input,
            nodesByPublicId: allNodes,
            floorsByPublicId: floors,
          ),
          bidirectional: input.bidirectional,
          updatedBy: userId,
          updatedAt: now,
          version: row.version + 1,
        ),
        transaction: transaction,
      );
    }
    for (final edgeId in deletes) {
      final row = await _ownedEdge(
        session,
        graph.id!,
        edgeId,
        userId,
        transaction,
      );
      await Edge.db.updateRow(
        session,
        row.copyWith(
          status: MapEntityStatus.deleted,
          deletedAt: now,
          updatedBy: userId,
          updatedAt: now,
          version: row.version + 1,
        ),
        transaction: transaction,
      );
    }
  }

  Future<void> _applyLocationPatch(
    Session session, {
    required MapGraph graph,
    required Map<String, Floor> floors,
    required List<LocationInput> creates,
    required List<LocationInput> updates,
    required List<String> deletes,
    required String userId,
    required Transaction transaction,
  }) async {
    final now = DateTime.now().toUtc();
    for (final input in creates) {
      final duplicate = await Locations.db.findFirstRow(
        session,
        where: (t) => t.locationId.equals(input.locationId),
        transaction: transaction,
      );
      if (duplicate != null) {
        throw _conflict('Location ${input.locationId} exists.');
      }
      final floor = floors[input.floorId]!;
      await Locations.db.insertRow(
        session,
        Locations(
          locationId: input.locationId,
          graphId: graph.id,
          floorId: floor.id,
          floor: floor.floorNumber,
          roomNumber: _trimmedOrNull(input.roomNumber),
          name: _trimmedOrNull(input.name),
          category: input.category,
          aliases: _trimmedOrNull(input.aliases),
          routeNodeId: input.routeNodeId,
          createdBy: userId,
          updatedBy: userId,
        ),
        transaction: transaction,
      );
    }
    for (final input in updates) {
      final row = await _ownedLocation(
        session,
        graph.id!,
        input.locationId,
        userId,
        transaction,
      );
      final floor = floors[input.floorId]!;
      await Locations.db.updateRow(
        session,
        row.copyWith(
          floorId: floor.id,
          floor: floor.floorNumber,
          roomNumber: _trimmedOrNull(input.roomNumber),
          name: _trimmedOrNull(input.name),
          category: input.category,
          aliases: _trimmedOrNull(input.aliases),
          routeNodeId: input.routeNodeId,
          updatedBy: userId,
          updatedAt: now,
          version: row.version + 1,
        ),
        transaction: transaction,
      );
    }
    for (final locationId in deletes) {
      final row = await _ownedLocation(
        session,
        graph.id!,
        locationId,
        userId,
        transaction,
      );
      await Locations.db.updateRow(
        session,
        row.copyWith(
          status: MapEntityStatus.deleted,
          deletedAt: now,
          updatedBy: userId,
          updatedAt: now,
          version: row.version + 1,
        ),
        transaction: transaction,
      );
    }
  }

  Future<Nodes> _ownedNode(
    Session session,
    int graphId,
    String nodeId,
    String userId,
    Transaction transaction,
  ) async {
    final row = await Nodes.db.findFirstRow(
      session,
      where: (t) =>
          t.graphId.equals(graphId) &
          t.nodeId.equals(nodeId) &
          t.status.equals(MapEntityStatus.active),
      transaction: transaction,
    );
    if (row == null) throw _notFound('Node');
    if (row.createdBy != userId) {
      throw _forbidden('You can change only nodes you created.');
    }
    return row;
  }

  Future<Edge> _ownedEdge(
    Session session,
    int graphId,
    String edgeId,
    String userId,
    Transaction transaction,
  ) async {
    final row = await Edge.db.findFirstRow(
      session,
      where: (t) =>
          t.graphId.equals(graphId) &
          t.edgeId.equals(edgeId) &
          t.status.equals(MapEntityStatus.active),
      transaction: transaction,
    );
    if (row == null) throw _notFound('Edge');
    if (row.createdBy != userId) {
      throw _forbidden('You can change only edges you created.');
    }
    return row;
  }

  Future<Locations> _ownedLocation(
    Session session,
    int graphId,
    String locationId,
    String userId,
    Transaction transaction,
  ) async {
    final row = await Locations.db.findFirstRow(
      session,
      where: (t) =>
          t.graphId.equals(graphId) &
          t.locationId.equals(locationId) &
          t.status.equals(MapEntityStatus.active),
      transaction: transaction,
    );
    if (row == null) throw _notFound('Location');
    if (row.createdBy != userId) {
      throw _forbidden('You can change only locations you created.');
    }
    return row;
  }

  void _validateContent({
    required List<FloorInput> floors,
    required List<MapNodeInput> nodes,
    required List<MapEdgeInput> edges,
    required List<LocationInput> locations,
  }) {
    if (floors.isEmpty) {
      throw _validation('A graph must contain at least one floor.');
    }
    final floorsById = <String, FloorInput>{};
    final floorNumbers = <int>{};
    for (final floor in floors) {
      _requireIdentifier(floor.floorId, 'floorId');
      if (!floor.width.isFinite ||
          floor.width <= 0 ||
          !floor.height.isFinite ||
          floor.height <= 0 ||
          !floor.metersPerUnit.isFinite ||
          floor.metersPerUnit <= 0) {
        throw _validation('Floor dimensions and scale must be positive.');
      }
      if (floorsById.containsKey(floor.floorId) ||
          !floorNumbers.add(floor.floorNumber)) {
        throw _validation('Floor IDs and floor numbers must be unique.');
      }
      floorsById[floor.floorId] = floor;
    }

    final nodesById = <String, MapNodeInput>{};
    for (final node in nodes) {
      _requireIdentifier(node.nodeId, 'nodeId');
      final floor = floorsById[node.floorId];
      if (floor == null) {
        throw _validation('Node ${node.nodeId} references an unknown floor.');
      }
      if (!node.x.isFinite ||
          !node.y.isFinite ||
          node.x < 0 ||
          node.y < 0 ||
          node.x > floor.width ||
          node.y > floor.height) {
        throw _validation('Node ${node.nodeId} is outside its floor bounds.');
      }
      if (nodesById.containsKey(node.nodeId)) {
        throw _validation('Node IDs must be unique within the graph.');
      }
      nodesById[node.nodeId] = node;
    }

    final edgeIds = <String>{};
    final connectedNodeIds = <String>{};
    for (final edge in edges) {
      _requireIdentifier(edge.edgeId, 'edgeId');
      if (!edgeIds.add(edge.edgeId)) {
        throw _validation('Edge IDs must be unique within the graph.');
      }
      final from = nodesById[edge.fromNodeId];
      final to = nodesById[edge.toNodeId];
      if (from == null || to == null) {
        throw _validation('Edge ${edge.edgeId} references an unknown node.');
      }
      if (from.nodeId == to.nodeId) {
        throw _validation(
          'Edge ${edge.edgeId} cannot connect a node to itself.',
        );
      }
      final crossFloor = from.floorId != to.floorId;
      if (crossFloor &&
          edge.type != EdgeType.stairs &&
          edge.type != EdgeType.elevator &&
          edge.type != EdgeType.escalator) {
        throw _validation(
          'Cross-floor edge ${edge.edgeId} must be stairs, elevator, or escalator.',
        );
      }
      if (edge.cost != null && (!edge.cost!.isFinite || edge.cost! <= 0)) {
        throw _validation('Edge costs must be positive finite values.');
      }
      if (crossFloor && edge.cost == null) {
        throw _validation('Cross-floor edges require an explicit cost.');
      }
      connectedNodeIds.add(from.nodeId);
      connectedNodeIds.add(to.nodeId);
    }
    if (nodes.length > 1) {
      final isolated = nodesById.keys.where(
        (id) => !connectedNodeIds.contains(id),
      );
      if (isolated.isNotEmpty) {
        throw _validation(
          'Active nodes must be connected: ${isolated.join(', ')}.',
        );
      }
    }

    final locationIds = <String>{};
    for (final location in locations) {
      _requireIdentifier(location.locationId, 'locationId');
      if (!locationIds.add(location.locationId)) {
        throw _validation('Location IDs must be unique within the graph.');
      }
      if (!floorsById.containsKey(location.floorId)) {
        throw _validation(
          'Location ${location.locationId} references an unknown floor.',
        );
      }
      if (_trimmedOrNull(location.name) == null &&
          _trimmedOrNull(location.roomNumber) == null) {
        throw _validation('A location needs a name or room number.');
      }
      if (location.routeNodeId != null) {
        final node = nodesById[location.routeNodeId];
        if (node == null) {
          throw _validation(
            'Location ${location.locationId} references an unknown route node.',
          );
        }
        if (node.floorId != location.floorId) {
          throw _validation(
            'A location and its route node must be on the same floor.',
          );
        }
      }
    }
  }

  double _edgeCost(
    MapEdgeInput edge, {
    required Map<String, MapNodeInput> nodesByPublicId,
    required Map<String, Floor> floorsByPublicId,
  }) {
    if (edge.cost != null) return edge.cost!;
    final from = nodesByPublicId[edge.fromNodeId]!;
    final to = nodesByPublicId[edge.toNodeId]!;
    final floor = floorsByPublicId[from.floorId]!;
    return math.sqrt(
          math.pow(to.x - from.x, 2) + math.pow(to.y - from.y, 2),
        ) *
        floor.metersPerUnit;
  }

  MapNodeInput _nodeToInput(Nodes node, MapGraphSnapshot snapshot) {
    final floor = snapshot.floors.firstWhere((row) => row.id == node.floorId);
    return MapNodeInput(
      nodeId: node.nodeId,
      floorId: floor.floorId,
      x: node.x,
      y: node.y,
      locationId: node.locationId,
      kind: node.kind,
    );
  }

  MapEdgeInput _edgeToInput(Edge edge) => MapEdgeInput(
    edgeId: edge.edgeId!,
    fromNodeId: edge.fromNodeId,
    toNodeId: edge.toNodeId,
    type: edge.type,
    cost: edge.costPx,
    bidirectional: edge.bidirectional,
  );

  LocationInput _locationToInput(
    Locations location,
    MapGraphSnapshot snapshot,
  ) {
    final floor = snapshot.floors.firstWhere(
      (row) => row.id == location.floorId,
    );
    return LocationInput(
      locationId: location.locationId,
      floorId: floor.floorId,
      roomNumber: location.roomNumber,
      name: location.name,
      category: location.category ?? LocationCategory.other,
      aliases: location.aliases,
      routeNodeId: location.routeNodeId,
    );
  }

  FloorInput _floorToInput(Floor floor) => FloorInput(
    floorId: floor.floorId,
    floorNumber: floor.floorNumber,
    name: floor.name,
    width: floor.width,
    height: floor.height,
    metersPerUnit: floor.metersPerUnit,
  );

  Future<void> _ensureTargetExists(
    Session session,
    ReportTargetType type,
    String targetId,
  ) async {
    final exists = switch (type) {
      ReportTargetType.node =>
        await Nodes.db.findFirstRow(
              session,
              where: (t) =>
                  t.nodeId.equals(targetId) &
                  t.status.equals(MapEntityStatus.active),
            ) !=
            null,
      ReportTargetType.edge =>
        await Edge.db.findFirstRow(
              session,
              where: (t) =>
                  t.edgeId.equals(targetId) &
                  t.status.equals(MapEntityStatus.active),
            ) !=
            null,
      ReportTargetType.location =>
        await Locations.db.findFirstRow(
              session,
              where: (t) =>
                  t.locationId.equals(targetId) &
                  t.status.equals(MapEntityStatus.active),
            ) !=
            null,
      ReportTargetType.graph =>
        await MapGraph.db.findFirstRow(
              session,
              where: (t) =>
                  t.graphId.equals(targetId) &
                  t.status.equals(MapEntityStatus.active),
            ) !=
            null,
    };
    if (!exists) throw _notFound('Report target');
  }

  int _searchScore(Locations location, String query) {
    if (query.isEmpty) return 1;
    final room = _normalize(location.roomNumber ?? '');
    final name = _normalize(location.name ?? '');
    final aliases = _normalize(location.aliases ?? '');
    if (room == query) return 100;
    if (name == query || aliases.split(';').contains(query)) return 90;
    if (room.startsWith(query)) return 80;
    if (name.startsWith(query)) return 70;
    if (room.contains(query) || name.contains(query)) return 60;
    if (aliases.contains(query)) return 50;
    if (_normalize(location.category?.name ?? '') == query) return 40;
    return 0;
  }

  LocationCategory? _categoryForSynonym(String query) {
    const synonyms = {
      'bathroom': LocationCategory.bathroom,
      'bathrooms': LocationCategory.bathroom,
      'restroom': LocationCategory.bathroom,
      'restrooms': LocationCategory.bathroom,
      'toilet': LocationCategory.bathroom,
      'washroom': LocationCategory.bathroom,
      'study': LocationCategory.studySpace,
      'study space': LocationCategory.studySpace,
      'study spaces': LocationCategory.studySpace,
      'exit': LocationCategory.exit,
      'exits': LocationCategory.exit,
      'elevator': LocationCategory.elevator,
      'elevators': LocationCategory.elevator,
    };
    return synonyms[query];
  }

  void _requireIdentifier(String value, String field) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 120 ||
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(trimmed)) {
      throw _validation('$field contains invalid characters.');
    }
  }

  void _requireText(String value, String field) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw _validation('$field must be between 1 and 200 characters.');
    }
  }

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _normalize(String value) => value.trim().toLowerCase();

  void _validatePage(int limit, int offset) {
    if (limit < 1 || limit > 100 || offset < 0) {
      throw MapApiException(
        code: 'invalid_page',
        message: 'Use limit 1-100 and a non-negative offset.',
      );
    }
  }

  MapApiException _validation(String message) =>
      MapApiException(code: 'validation_failed', message: message);

  MapApiException _notFound(String resource) => MapApiException(
    code: 'not_found',
    message: '$resource was not found.',
  );

  MapApiException _conflict(String message) =>
      MapApiException(code: 'conflict', message: message);

  MapApiException _forbidden(String message) =>
      MapApiException(code: 'forbidden', message: message);
}
