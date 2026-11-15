import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/map_repository.dart';
import 'package:madmaps/features/navigation/place_maps.dart';
import 'package:madmaps/features/shell/app_state.dart';
import 'package:madmaps/features/shell/madmaps_shell.dart';
import 'package:madmaps/screens/room_amenity_map_screen.dart';
import 'room_amenity_map_screen_test.dart' show PlacesApi;

class FakePlaceMaps implements PlaceMapsApi {
  final records = <String, SavedPlaceMap>{};
  @override
  Future<List<SavedPlaceMap>> list() async => records.values.toList();
  @override
  Future<SavedPlaceMap> get(String id) async => records[id]!;
  @override
  Future<SavedPlaceMap> save(
    String content,
    String buildingName,
    String floorLabel, {
    String? mapId,
    int? expectedVersion,
  }) async {
    final id = mapId ?? 'places-test';
    if (mapId != null && records[id]!.version != expectedVersion)
      throw StateError('Conflict');
    final value = SavedPlaceMap(
      mapId: id,
      buildingName: buildingName,
      floorLabel: floorLabel,
      version: (records[id]?.version ?? 0) + 1,
      mapJson: content,
      places: (jsonDecode(content)['places'] as List)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList(),
    );
    records[id] = value;
    return value;
  }
}

class BuiltInRepository implements MapRepository {
  BuiltInRepository(this.graph);
  final FloorGraph graph;
  @override
  Future<FloorGraph> load() async => graph;
  @override
  Future<List<String>> search(String q, {String? category}) async => graph
      .locations
      .where(
        (p) =>
            category == null && p.label.toLowerCase().contains(q.toLowerCase()),
      )
      .map((p) => p.id)
      .toList();
  @override
  List<String> get categories => [];
  @override
  String? categoryOf(String id) => null;
}

String fixture() => jsonEncode({
  'schema_version': 1,
  'profile': 'rooms-and-amenities-v1',
  'name': 'Science plan',
  'width': 400,
  'height': 240,
  'coordinate_origin': 'top-left',
  'coordinate_units': 'pixels',
  'image_mime_type': 'image/png',
  'image_base64': base64Encode(
    File('test/fixtures/lab_plan.png').readAsBytesSync(),
  ),
  'places': [
    {
      'id': 'place-1',
      'label': 'Quantum Lab',
      'category': 'office',
      'x': 100,
      'y': 120,
    },
  ],
});
void main() {
  late FloorGraph graph;
  setUpAll(() async => graph = await FloorGraph.load());
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });
  test(
    'catalog searches labels, building names and categories with stable IDs',
    () async {
      final api = FakePlaceMaps();
      final saved = await api.save(fixture(), 'Science Hall', 'Level 2');
      final catalog = CatalogMapRepository(
        BuiltInRepository(graph),
      )..maps = [saved];
      expect(await catalog.search('Quantum'), [saved.destinationId('place-1')]);
      expect(await catalog.search('science hall'), [
        saved.destinationId('place-1'),
      ]);
      expect(await catalog.search('', category: 'office'), [
        saved.destinationId('place-1'),
      ]);
      expect(await catalog.search('Quantum', category: 'bathroom'), isEmpty);
      expect(catalog.destinations.single.node, isNull);
    },
  );
  testWidgets('import exported JSON, save and update the same app map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakePlaceMaps();
    final initial = await api.save(fixture(), 'Science Hall', 'Level 2');
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RoomAmenityMapScreen(
          api: PlacesApi(),
          placeMapsApi: api,
          initialMap: initial,
          onSaved: () => saves++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit Quantum Lab'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('place-label')), 'Physics Lab');
    await tester.tap(find.byKey(const Key('save-place')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-place-map')));
    await tester.tap(find.byKey(const Key('save-place-map')));
    await tester.pumpAndSettle();
    expect(find.text('Science Hall'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-save-map')));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(api.records, hasLength(1));
    expect(api.records.values.single.version, 2);
    expect(api.records.values.single.places.single['label'], 'Physics Lab');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'compact Explore filters buildings and opens the uploaded destination map',
    (tester) async {
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FakePlaceMaps();
      await api.save(fixture(), 'Science Hall', 'Level 2');
      final state = AppState(null);
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MadMapsShell(
            state: state,
            repository: BuiltInRepository(graph),
            placeMapsApi: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Quantum');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Quantum Lab'), findsOneWidget);
      expect(find.text('Science Hall · Level 2 · View on map'), findsOneWidget);
      await tester.tap(find.byKey(const Key('destination-building-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morgridge Hall').last);
      await tester.pumpAndSettle();
      expect(find.text('Quantum Lab'), findsNothing);
      await tester.tap(find.byKey(const Key('destination-building-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Science Hall').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quantum Lab'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(find.text('Plan a route'), findsNothing);
      expect(
        find.byKey(const ValueKey('destination-pin-place-1')),
        findsOneWidget,
      );
      expect(find.text('Quantum Lab'), findsOneWidget);
      expect(
        find.textContaining('Walking directions are not mapped'),
        findsOneWidget,
      );
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('destination-pin-place-1')),
        findsOneWidget,
      );
      expect(find.text('Quantum Lab'), findsOneWidget);
      final pin = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(const ValueKey('destination-pin-place-1')),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((pin.decoration! as BoxDecoration).color, Colors.deepOrange);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Explore building selection and map floor selection share the displayed plan',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FakePlaceMaps();
      await api.save(fixture(), 'Science Hall', 'Level 2');
      final document = jsonDecode(fixture()) as Map<String, dynamic>;
      document['places'] = [
        {
          'id': 'place-2',
          'label': 'Chemistry Lab',
          'category': 'office',
          'x': 200,
          'y': 120,
        },
      ];
      api.records['places-second'] = SavedPlaceMap(
        mapId: 'places-second',
        buildingName: 'Science Hall',
        floorLabel: 'Level 3',
        version: 1,
        mapJson: jsonEncode(document),
        places: (document['places'] as List).cast<Map<String, dynamic>>(),
      );
      final state = AppState(null);
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MadMapsShell(
            state: state,
            repository: BuiltInRepository(graph),
            placeMapsApi: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('destination-pin-place-2')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('map-plan-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Science Hall · Level 2').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('destination-pin-place-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('destination-pin-place-2')),
        findsNothing,
      );
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('destination-building-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morgridge Hall').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('destination-pin-place-1')),
        findsNothing,
      );
      expect(find.byTooltip('Find my location'), findsOneWidget);
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('destination-building-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Science Hall').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('destination-pin-place-1')),
        findsOneWidget,
      );
      expect(find.text('Plan a route'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
