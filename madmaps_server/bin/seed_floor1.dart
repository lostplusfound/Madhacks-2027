import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart' hide Serverpod;
import 'package:madmaps_server/src/generated/serverpod.dart';
import 'package:madmaps_server/src/generated/protocol.dart';
import 'package:madmaps_server/src/endpoints/map_graph_service.dart';

/// Explicit operator-only seed; never called by app startup or an endpoint.
Future<void> main(List<String> args) async {
  final pod = Serverpod(args);
  final session = await pod.createSession(enableLogging: false);
  session.updateAuthenticated(
    AuthenticationInfo('floor1-seed-operator', {}, authId: 'operator-seed'),
  );
  try {
    final data =
        jsonDecode(await File('assets/floor1_seed.json').readAsString())
            as Map<String, dynamic>;
    final request = CreateGraphRequest.fromJson(
      data['request'] as Map<String, dynamic>,
    );
    final notes = Map<String, String>.from(data['reviewNotes'] as Map);
    const service = MapGraphService();
    var snapshot = await service.getGraph(session, request.graphId);
    if (snapshot == null) {
      if (await service.getBuilding(session, request.buildingId) == null) {
        await service.createBuilding(
          session,
          buildingId: request.buildingId,
          name: 'Morgridge Hall',
        );
      }
      snapshot = await service.createGraph(session, request);
      await session.db.transaction((transaction) async {
        for (final l in snapshot!.locations) {
          if (notes.containsKey(l.locationId))
            await Locations.db.updateRow(
              session,
              l.copyWith(reviewNote: notes[l.locationId]),
              transaction: transaction,
            );
        }
      });
      snapshot = (await service.getGraph(session, request.graphId))!;
    }
    verifySeed(snapshot, request, notes);
    stdout.writeln(
      'Floor 1 seed verified: ${snapshot.nodes.length} nodes, ${snapshot.edges.length} edges, ${snapshot.locations.length} destinations. Geometry remains draft.',
    );
  } finally {
    await session.close();
    await pod.shutdown();
  }
}

void verifySeed(
  MapGraphSnapshot snapshot,
  CreateGraphRequest request,
  Map<String, String> notes,
) {
  void check(bool valid) {
    if (!valid)
      throw StateError(
        'Existing Floor 1 differs from the seed. No existing graph data was overwritten.',
      );
  }

  check(snapshot.walls.isEmpty);
  check(
    snapshot.building.buildingId == request.buildingId &&
        snapshot.graph.name == request.name,
  );
  check(
    snapshot.nodes.length == request.nodes.length &&
        snapshot.edges.length == request.edges.length &&
        snapshot.locations.length == request.locations.length,
  );
  final floor = snapshot.floors.singleWhere((f) => f.floorNumber == 1);
  check(
    floor.width == 1632 &&
        floor.height == 1056 &&
        floor.floorId == request.floors.single.floorId,
  );
  final nodes = {for (final n in snapshot.nodes) n.nodeId: n};
  for (final n in request.nodes) {
    final actual = nodes[n.nodeId];
    check(
      actual != null &&
          actual.floor == 1 &&
          actual.x == n.x &&
          actual.y == n.y &&
          actual.kind == n.kind &&
          actual.locationId == n.locationId,
    );
  }
  final edges = {for (final e in snapshot.edges) e.edgeId: e};
  for (final e in request.edges) {
    final actual = edges[e.edgeId];
    check(
      actual != null &&
          actual.fromNodeId == e.fromNodeId &&
          actual.toNodeId == e.toNodeId &&
          actual.costPx == e.cost &&
          actual.bidirectional == e.bidirectional &&
          actual.type == e.type,
    );
  }
  final locations = {for (final l in snapshot.locations) l.locationId: l};
  for (final l in request.locations) {
    final actual = locations[l.locationId];
    check(
      actual != null &&
          actual.floor == 1 &&
          actual.name == l.name &&
          actual.roomNumber == l.roomNumber &&
          actual.category == l.category &&
          actual.aliases == l.aliases &&
          actual.routeNodeId == l.routeNodeId &&
          actual.reviewNote == notes[l.locationId],
    );
  }
}
