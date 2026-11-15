import 'dart:convert';
import 'dart:io';
import 'package:madmaps_server/src/generated/serverpod.dart';
import 'package:madmaps_server/src/generated/protocol.dart';
import 'package:madmaps_server/src/endpoints/map_graph_service.dart';

bool same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    final keys = a.keys.where((k) => k != '__className__').toSet();
    final other = b.keys.where((k) => k != '__className__').toSet();
    return keys.length == other.length &&
        keys.every((k) => other.contains(k) && same(a[k], b[k]));
  }
  if (a is List && b is List)
    return a.length == b.length &&
        List.generate(a.length, (i) => i).every((i) => same(a[i], b[i]));
  return a == b;
}

Future<void> main(List<String> args) async {
  final pod = Serverpod(args);
  final session = await pod.createSession(enableLogging: false);
  session.updateAuthenticated(
    AuthenticationInfo('floor1-seed-operator', {}, authId: 'operator-seed'),
  );
  try {
    const service = MapGraphService();
    final updates =
        jsonDecode(await File('assets/map_corrections_v2.json').readAsString())
            as List;
    for (final update in updates) {
      final snapshot = await service.getGraph(session, update['graphId']);
      if (snapshot == null) continue; // New graphs use the corrected seed.
      final floorId = update['graphId'] as String;
      final actual = <String, Map<String, dynamic>>{
        'nodes': {
          for (final n in snapshot.nodes)
            n.nodeId: MapNodeInput(
              nodeId: n.nodeId,
              floorId: floorId,
              x: n.x,
              y: n.y,
              kind: n.kind,
              locationId: n.locationId,
            ).toJson(),
        },
        'edges': {
          for (final e in snapshot.edges)
            e.edgeId!: MapEdgeInput(
              edgeId: e.edgeId!,
              fromNodeId: e.fromNodeId,
              toNodeId: e.toNodeId,
              type: e.type,
              cost: e.costPx,
              bidirectional: e.bidirectional,
            ).toJson(),
        },
        'locations': {
          for (final l in snapshot.locations)
            l.locationId: LocationInput(
              locationId: l.locationId,
              floorId: floorId,
              roomNumber: l.roomNumber,
              name: l.name,
              category: l.category ?? LocationCategory.other,
              aliases: l.aliases,
              routeNodeId: l.routeNodeId,
            ).toJson(),
        },
        'walls': {for (final w in snapshot.walls) w.wallId: w.toJson()},
      };
      final create = <String, List<Map<String, dynamic>>>{},
          change = <String, List<Map<String, dynamic>>>{},
          remove = <String, List<String>>{};
      for (final key in actual.keys) {
        create[key] = [];
        change[key] = [];
        remove[key] = [];
        final idKey = {
          'nodes': 'nodeId',
          'edges': 'edgeId',
          'locations': 'locationId',
          'walls': 'wallId',
        }[key]!;
        for (final delta in update['changes'][key]) {
          final before = delta['before'] as Map<String, dynamic>?;
          final after = delta['after'] as Map<String, dynamic>?;
          final id = (after ?? before)![idKey] as String;
          Map<String, dynamic>? clean(Map<String, dynamic>? v) =>
              v == null ? null : (Map.of(v)..remove('__className__'));
          final current = clean(actual[key]![id] as Map<String, dynamic>?);
          // Serverpod omits null fields on the wire; compare the complete input shape.
          bool matches(Map<String, dynamic>? expected) => expected == null
              ? current == null
              : current != null &&
                    expected.keys.every((k) => same(current[k], expected[k]));
          if (matches(after)) continue;
          if (!matches(before) &&
              !(delta.containsKey('intermediate') &&
                  matches(delta['intermediate'] as Map<String, dynamic>?)))
            throw StateError(
              'Map correction conflict in $floorId / $id. Existing edits preserved; reconcile this entity before retrying.',
            );
          if (after == null) {
            remove[key]!.add(id);
            actual[key]!.remove(id);
          } else {
            actual[key]![id] = after;
            if (current == null) {
              create[key]!.add(after);
            } else {
              change[key]!.add(after);
            }
          }
        }
      }
      if ([
        ...create.values,
        ...change.values,
        ...remove.values,
      ].any((l) => l.isNotEmpty)) {
        await service.patchGraph(
          session,
          GraphPatchRequest(
            graphId: floorId,
            expectedVersion: snapshot.graph.version,
            nodesToCreate: create['nodes']!.map(MapNodeInput.fromJson).toList(),
            nodesToUpdate: change['nodes']!.map(MapNodeInput.fromJson).toList(),
            nodeIdsToDelete: remove['nodes']!,
            edgesToCreate: create['edges']!.map(MapEdgeInput.fromJson).toList(),
            edgesToUpdate: change['edges']!.map(MapEdgeInput.fromJson).toList(),
            edgeIdsToDelete: remove['edges']!,
            locationsToCreate: create['locations']!
                .map(LocationInput.fromJson)
                .toList(),
            locationsToUpdate: change['locations']!
                .map(LocationInput.fromJson)
                .toList(),
            locationIdsToDelete: remove['locations']!,
            walls: actual['walls']!.values
                .map((w) => WallInput.fromJson(w as Map<String, dynamic>))
                .toList(),
          ),
        );
        stdout.writeln('Applied reviewed floor-plan corrections to $floorId');
      }
      final seed = jsonDecode(
        await File('assets/floor${update['floor']}_seed.json').readAsString(),
      );
      final refreshed = (await service.getGraph(session, floorId))!;
      for (final l in refreshed.locations) {
        final note = seed['reviewNotes'][l.locationId] as String?;
        final reviewed = update['reviewNoteChanges']?[l.locationId];
        if (note != null &&
            (l.reviewNote == null ||
                (reviewed != null && l.reviewNote == reviewed['before'])))
          await Locations.db.updateRow(session, l.copyWith(reviewNote: note));
      }
    }
    final connectors =
        jsonDecode(await File('assets/floor_connectors.json').readAsString())
            as List;
    final connectorCorrections =
        jsonDecode(
              await File('assets/connector_corrections.json').readAsString(),
            )
            as List;
    for (final delta in connectorCorrections) {
      final before = FloorConnector.fromJson(delta['before']);
      final after = FloorConnector.fromJson(delta['after']);
      final existing = await FloorConnector.db.findFirstRow(
        session,
        where: (t) => t.connectorId.equals(after.connectorId),
      );
      if (existing == null) continue;
      final current = existing.toJson()..remove('id');
      if (same(current, after.toJson())) continue;
      if (!same(current, before.toJson())) {
        throw StateError(
          'Connector correction conflict for ${after.connectorId}. Existing edits preserved.',
        );
      }
      await FloorConnector.db.updateRow(
        session,
        after.copyWith(id: existing.id),
      );
      stdout.writeln('Corrected stairs connection ${after.connectorId}');
    }
    for (final raw in connectors) {
      final input = FloorConnector.fromJson(raw as Map<String, dynamic>);
      final existing = await FloorConnector.db.findFirstRow(
        session,
        where: (t) => t.connectorId.equals(input.connectorId),
      );
      if (existing == null) {
        await FloorConnector.db.insertRow(session, input);
      }
    }
    stdout.writeln(
      'Connector catalog ready. Geometry and cross-floor cores require on-site verification.',
    );
  } finally {
    await session.close();
    await pod.shutdown(exitProcess: false);
  }
}
