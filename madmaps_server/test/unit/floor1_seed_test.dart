import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:madmaps_server/src/generated/protocol.dart';
import '../../bin/seed_floor1.dart' show verifySeed;

MapGraphSnapshot fixture([int floorNumber = 1]) {
  final data =
      jsonDecode(
            File('assets/floor${floorNumber}_seed.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final r = data['request'] as Map<String, dynamic>;
  return MapGraphSnapshot(
    walls: [
      for (final w in r['walls']) WallInput.fromJson(w as Map<String, dynamic>),
    ],
    graph: MapGraph(
      graphId: r['graphId'],
      buildingId: 1,
      name: r['name'],
      ownerId: 'seed',
    ),
    building: Building(
      buildingId: r['buildingId'],
      name: 'Morgridge Hall',
      createdBy: 'seed',
    ),
    floors: [
      for (final f in r['floors'])
        Floor.fromJson({...Map<String, dynamic>.from(f), 'buildingId': 1}),
    ],
    nodes: [
      for (final n in r['nodes'])
        Nodes.fromJson({
          ...Map<String, dynamic>.from(n),
          'floorId': 1,
          'floor': floorNumber,
        }),
    ],
    edges: [
      for (final e in r['edges'])
        Edge.fromJson({...Map<String, dynamic>.from(e), 'costPx': e['cost']}),
    ],
    locations: [
      for (final l in r['locations'])
        Locations.fromJson({
          ...Map<String, dynamic>.from(l),
          'floorId': 1,
          'floor': floorNumber,
          'reviewNote': data['reviewNotes'][l['locationId']],
        }),
    ],
  );
}

void main() {
  for (final floor in [0, 2, 3]) {
    test(
      'Floor $floor seed is valid and repeat verification preserves edits',
      () {
        final data =
            jsonDecode(
                  File('assets/floor${floor}_seed.json').readAsStringSync(),
                )
                as Map<String, dynamic>;
        final request = CreateGraphRequest.fromJson(data['request']);
        final notes = Map<String, String>.from(data['reviewNotes']);
        final snapshot = fixture(floor);
        verifySeed(snapshot, request, notes);
        verifySeed(snapshot, request, notes);
        final ids = request.nodes.map((n) => n.nodeId).toSet();
        final connected = <String>{};
        for (final edge in request.edges) {
          expect(
            ids.contains(edge.fromNodeId) && ids.contains(edge.toNodeId),
            isTrue,
          );
          connected.addAll([edge.fromNodeId, edge.toNodeId]);
          expect(edge.cost, greaterThan(0));
        }
        expect(connected, ids);
        snapshot.nodes.first.x += 1;
        expect(() => verifySeed(snapshot, request, notes), throwsStateError);
      },
    );
  }
  final data =
      jsonDecode(File('assets/floor1_seed.json').readAsStringSync())
          as Map<String, dynamic>;
  final request = CreateGraphRequest.fromJson(data['request']);
  final notes = Map<String, String>.from(data['reviewNotes']);
  test(
    'repeat verification accepts identical seed with draft review notes',
    () {
      final snapshot = fixture();
      verifySeed(snapshot, request, notes);
      verifySeed(snapshot, request, notes);
      expect(notes, isNotEmpty);
      expect(data['geometryStatus'], 'draft');
    },
  );
  test(
    'verification rejects edited geometry, costs, categories and review notes',
    () {
      var s = fixture();
      s.nodes.first.x += 1;
      expect(() => verifySeed(s, request, notes), throwsStateError);
      s = fixture();
      s.edges.first.costPx += 1;
      expect(() => verifySeed(s, request, notes), throwsStateError);
      s = fixture();
      s.locations.first.category = LocationCategory.exit;
      expect(() => verifySeed(s, request, notes), throwsStateError);
      s = fixture();
      s.locations.first.reviewNote = 'changed';
      expect(() => verifySeed(s, request, notes), throwsStateError);
    },
  );
}
