import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps_client/madmaps_client.dart' as api;
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/map_repository.dart';
import 'package:madmaps/features/shell/app_state.dart';
import 'package:madmaps/features/shell/home_screen.dart';
import 'package:madmaps/main.dart';

api.MapGraphSnapshot fixture() {
  final data =
      jsonDecode(
            File(
              '../madmaps_server/assets/floor1_seed.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final r = data['request'] as Map<String, dynamic>;
  return api.MapGraphSnapshot(
    graph: api.MapGraph(
      graphId: r['graphId'],
      buildingId: 1,
      name: r['name'],
      ownerId: 'seed',
    ),
    building: api.Building(
      buildingId: r['buildingId'],
      name: 'Morgridge Hall',
      createdBy: 'seed',
    ),
    floors: [
      for (final f in r['floors'])
        api.Floor.fromJson({...Map<String, dynamic>.from(f), 'buildingId': 1}),
    ],
    nodes: [
      for (final n in r['nodes'])
        api.Nodes.fromJson({
          ...Map<String, dynamic>.from(n),
          'floorId': 1,
          'floor': 1,
        }),
    ],
    edges: [
      for (final e in r['edges'])
        api.Edge.fromJson({
          ...Map<String, dynamic>.from(e),
          'costPx': e['cost'],
        }),
    ],
    locations: [
      for (final l in r['locations'])
        api.Locations.fromJson({
          ...Map<String, dynamic>.from(l),
          'floorId': 1,
          'floor': 1,
          'reviewNote': data['reviewNotes'][l['locationId']],
        }),
    ],
  );
}

class MemoryRepository implements MapRepository {
  MemoryRepository(this.graph);
  final FloorGraph graph;
  bool unavailable = false;
  @override
  Future<FloorGraph> load() async {
    if (unavailable) throw const SocketException('offline');
    return graph;
  }

  @override
  Future<List<String>> search(String query, {String? category}) async {
    if (unavailable) throw const SocketException('offline');
    return ['f1-cafe'];
  }

  @override
  List<String> get categories => ['bathroom', 'exit', 'elevator'];
  @override
  String? categoryOf(String id) => 'food';
}

class PendingRepository extends MemoryRepository {
  PendingRepository(super.graph);
  final requests = <String, Completer<List<String>>>{};
  @override
  Future<List<String>> search(String query, {String? category}) =>
      (requests[query] = Completer<List<String>>()).future;
}

class StubClient extends api.Client {
  StubClient() : super('http://localhost:8080/');
  bool offline = false;
  int searches = 0;
  @override
  Future<T> callServerEndpoint<T>(
    String endpoint,
    String method,
    Map<String, dynamic> args, {
    bool authenticated = true,
  }) async {
    if (offline) throw const SocketException('offline');
    if (method == 'getGraph')
      return api.GraphReadResult(unchanged: false, snapshot: fixture()) as T;
    if (method == 'listQuickAccessCategories')
      return [
            api.LocationCategory.bathroom,
            api.LocationCategory.exit,
            api.LocationCategory.elevator,
            api.LocationCategory.studySpace,
          ]
          as T;
    searches++;
    return [
          api.SearchResult(
            location: fixture().locations.singleWhere(
              (p) => p.locationId == 'f1-cafe',
            ),
            score: 100,
          ),
        ]
        as T;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'repository reuses loaded search responses offline and fails uncached requests',
    () async {
      final client = StubClient();
      final repository = ServerMapRepository(connect: () async => client);
      await repository.load();
      expect(repository.categories, ['bathroom', 'exit', 'elevator']);
      expect(await repository.search('cafe'), ['f1-cafe']);
      client.offline = true;
      expect(await repository.search(' CAFE '), ['f1-cafe']);
      expect(client.searches, 1);
      await expectLater(
        repository.search('1524'),
        throwsA(isA<SocketException>()),
      );
      client.close();
    },
  );
  testWidgets('late search replies cannot replace newer results', (
    tester,
  ) async {
    final repository = PendingRepository(adaptSnapshot(fixture()));
    final state = AppState(null);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            repository: repository,
            places: repository.graph.locations,
            state: state,
            onChoose: (_) {},
            onMap: () {},
            onProfile: () {},
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'cafe');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), '1524');
    await tester.pump(const Duration(milliseconds: 350));
    repository.requests['1524']!.complete(['f1-1524']);
    await tester.pump();
    repository.requests['cafe']!.complete(['f1-cafe']);
    await tester.pumpAndSettle();
    expect(find.text('Room 1524'), findsOneWidget);
    expect(find.text('Cafe'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  test(
    'seed preserves current Floor 1 IDs, geometry, routes and categories',
    () async {
      final snapshot = fixture();
      final actual = adaptSnapshot(snapshot);
      final bundled = await FloorGraph.load();
      expect(actual.nodes.keys.toSet(), bundled.nodes.keys.toSet());
      for (final id in actual.nodes.keys) {
        expect(actual.nodes[id]!.point, bundled.nodes[id]!.point);
      }
      expect(
        actual.locations.map((p) => [p.id, p.label, p.aliases, p.node]),
        bundled.locations.map((p) => [p.id, p.label, p.aliases, p.node]),
      );
      expect(
        actual.edges.map((e) => [e.from, e.to, e.cost, e.bidirectional]),
        bundled.edges.map((e) => [e.from, e.to, e.cost, e.bidirectional]),
      );
      expect(
        snapshot.locations
            .singleWhere((l) => l.locationId == 'f1-cafe')
            .category,
        api.LocationCategory.food,
      );
      expect(
        snapshot.locations.where(
          (l) => l.category == api.LocationCategory.bathroom,
        ),
        isNotEmpty,
      );
      expect(snapshot.locations.where((l) => l.reviewNote != null), isNotEmpty);
    },
  );
  test(
    'reject incompatible image, invalid coordinates and broken route references',
    () {
      var s = fixture();
      s.floors.first.width = 100;
      expect(() => adaptSnapshot(s), throwsFormatException);
      s = fixture();
      s.nodes.first.x = double.nan;
      expect(() => adaptSnapshot(s), throwsFormatException);
      s = fixture();
      s.edges.first.toNodeId = 'missing';
      expect(() => adaptSnapshot(s), throwsFormatException);
      s = fixture();
      s.locations.first.routeNodeId = 'missing';
      expect(() => adaptSnapshot(s), throwsFormatException);
    },
  );
  testWidgets(
    'startup requires server and Retry recovers without bundled fallback',
    (tester) async {
      final repository = MemoryRepository(adaptSnapshot(fixture()))
        ..unavailable = true;
      await tester.pumpWidget(
        MyApp(state: AppState(null), repository: repository),
      );
      await tester.pumpAndSettle();
      expect(find.text('Where are you headed?'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      repository.unavailable = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Where are you headed?'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'connection loss reports failure while loaded destinations and aliases remain usable',
    (tester) async {
      final repository = MemoryRepository(adaptSnapshot(fixture()))
        ..unavailable = true;
      final state = AppState(null)..aliases['f1-cafe'] = 'My coffee';
      String? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              repository: repository,
              places: repository.graph.locations,
              state: state,
              onChoose: (p) => chosen = p.id,
              onMap: () {},
              onProfile: () {},
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'My coffee');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not reach the server'), findsOneWidget);
      await tester.tap(find.text('My coffee').last);
      expect(chosen, 'f1-cafe');
      repository.unavailable = false;
      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not reach the server'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );
}
