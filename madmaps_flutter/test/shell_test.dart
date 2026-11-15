import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:madmaps/main.dart';
import 'package:madmaps/features/navigation/map_repository.dart';
import 'package:madmaps/features/localization/map_data.dart';
import 'package:madmaps/features/localization/prototype_screen.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/navigation_panel.dart';
import 'package:madmaps/features/navigation/routing.dart';
import 'package:madmaps/features/shell/app_state.dart';
import 'package:madmaps/features/shell/navigation_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FloorGraph graph;
  setUpAll(() async {
    graph = await FloorGraph.load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });
  test(
    'saved IDs, aliases, history and preferences survive reload without touching maps',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(MapStore.key, 'existing map data');
      final state = AppState(prefs);
      expect(state.saved, isEmpty);
      expect(state.visits, isEmpty);
      state.toggleSaved('f1-cafe');
      state.rename('f1-cafe', 'Coffee break');
      state.recordVisit('f1-cafe');
      state.recordVisit('f1-heart');
      state.recordVisit('f1-cafe');
      state.setFeet(true);
      state.setContrast(true);
      state.setVoice(true);
      await state.flushed;
      final restored = AppState(prefs);
      expect(restored.saved, {'f1-cafe'});
      expect(restored.aliases['f1-cafe'], 'Coffee break');
      expect(restored.recent, ['f1-cafe', 'f1-heart']);
      expect(restored.frequent.first, 'f1-cafe');
      expect(restored.distance(10), '33 ft');
      expect(restored.contrast && restored.voice, isTrue);
      expect(prefs.getString(MapStore.key), 'existing map data');
      state.dispose();
      restored.dispose();
    },
  );
  test('unavailable storage keeps preferences usable in memory', () async {
    final state = AppState(null);
    state.toggleSaved('f1-cafe');
    await state.flushed;
    expect(state.saved, {'f1-cafe'});
    expect(state.storageError, isNotNull);
    state.dispose();
  });
  test('corrupt preferences fall back to real empty state', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppState.storageKey, 'broken json');
    final state = AppState(prefs);
    expect(state.saved, isEmpty);
    expect(state.storageError, isNotNull);
    state.dispose();
  });
  test(
    'arrival is recorded once per trip, and tracking loss pauses distance',
    () {
      final session = NavigationSession();
      final place = FloorLocation('cafe', 'Cafe', '', 'node');
      session.choose(place);
      final guidance = GuidanceState()
        ..remainingMeters = 12
        ..maneuver = 'Turn left';
      expect(session.update(guidance, tracking: true), false);
      expect(session.instruction, 'Turn left');
      session.update(guidance, tracking: false);
      expect(session.remainingMeters, isNull);
      expect(session.instruction, contains('Tracking paused'));
      guidance.arrived = true;
      expect(session.update(guidance, tracking: false), false);
      expect(session.update(guidance, tracking: true), true);
      expect(session.update(guidance, tracking: true), false);
      session.update(guidance, tracking: false);
      expect(session.update(guidance, tracking: true), false);
      session.choose(place);
      expect(session.update(guidance, tracking: true), true);
      var cancelled = false;
      session.onCancel = () => cancelled = true;
      session.cancel();
      expect(cancelled, true);
      expect(session.destination, isNull);
      expect(session.update(guidance, tracking: true), false);
      session.dispose();
    },
  );
  testWidgets(
    'Home search saves a place, Saved renames it, and real setup is required',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        MyApp(state: state, repository: FixtureRepository(graph)),
      );
      await tester.runAsync(() async {
        await FloorGraph.load();
      });
      await tester.pumpAndSettle();
      expect(find.text('Where are you headed?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '1524');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Save place'), findsOneWidget);
      await tester.tap(find.byTooltip('Save place'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(state.saved.length, 1);
      await tester.longPress(find.text('Room 1524'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'My room');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('My room'), findsOneWidget);
      await tester.tap(find.text('My room'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();
      expect(find.text('Scan a floor to enable live guidance'), findsOneWidget);
      expect(find.text('Open mapping tools'), findsOneWidget);
      await tester.tap(find.text('Open mapping tools'));
      await tester.pumpAndSettle();
      expect(find.text('Map with AR'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('My room'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Explore Floor 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'tab changes preserve the same native session owner and pending destination',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final map = AnchorMap('map', 'Hall', [
        SavedAnchor(
          'a',
          'A',
          'cloud-a',
          Matrix4.identity(),
          DateTime.utc(2030),
        ),
        SavedAnchor(
          'b',
          'B',
          'cloud-b',
          Matrix4.translationValues(5, 0, 0),
          DateTime.utc(2030),
        ),
      ]);
      map.floor.enabled = true;
      map.floor.calibrationIds.addAll(['a', 'b']);
      map.floor.anchorPoints.addAll({
        'a': const Offset(500, 500),
        'b': const Offset(600, 500),
      });
      await MapStore().save([map]);
      final state = AppState(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        MyApp(state: state, repository: FixtureRepository(graph)),
      );
      await tester.runAsync(() async {
        await FloorGraph.load();
      });
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1524');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Room 1524'));
      await tester.pump();
      await tester.runAsync(() async {
        await FloorGraph.load();
      });
      await tester.pumpAndSettle();
      final sessionFinder = find.byType(MapSessionScreen);
      final owner = tester.state(sessionFinder);
      final session = tester.widget<MapSessionScreen>(sessionFinder).session!;
      expect(session.destination?.id, 'f1-1524');
      expect(session.attached, true);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tracking paused'), findsOneWidget);
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(identical(owner, tester.state(sessionFinder)), true);
      expect(session.destination?.id, 'f1-1524');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(session.attached, false);
      expect(session.destination, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'large text Profile has real preferences without unsupported claims',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final state = AppState(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        MyApp(state: state, repository: FixtureRepository(graph)),
      );
      await tester.runAsync(() async {
        await FloorGraph.load();
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High contrast'));
      await tester.pumpAndSettle();
      expect(state.contrast, true);
      expect(find.text('Wheelchair access'), findsNothing);
      expect(find.text('Camera check-in demo'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('distance preference applies to real guidance', (tester) async {
    final guidance = GuidanceState()
      ..remainingMeters = 24
      ..maneuver = 'Turn left'
      ..maneuverMeters = 8;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavigationPanel(
            graph: graph,
            setup: FloorSetup(),
            pose: Matrix4.identity(),
            calibration: FloorCalibration(Offset.zero, Offset.zero, 10, 0),
            guidance: guidance,
            destination: 'Cafe',
            message: 'Ready',
            busy: false,
            onSearch: () {},
            onLocate: () {},
            onCancel: () {},
            distanceLabel: (m) => '${(m * 3.28084).round()} ft',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Turn left in 26 ft'), findsOneWidget);
    expect(find.textContaining('79 ft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class FixtureRepository implements MapRepository {
  FixtureRepository(this.graph);
  final FloorGraph graph;
  @override
  Future<FloorGraph> load() async => graph;
  @override
  List<String> get categories => ['bathroom', 'exit'];
  @override
  String? categoryOf(String id) => id.contains('restroom')
      ? 'bathroom'
      : id.contains('exit')
      ? 'exit'
      : 'other';
  @override
  Future<List<String>> search(String query, {String? category}) async => graph
      .locations
      .where(
        (p) =>
            (category == null || categoryOf(p.id) == category) &&
            '${p.label} ${p.aliases} ${p.id}'.toLowerCase().contains(
              query.toLowerCase(),
            ),
      )
      .map((p) => p.id)
      .toList();
}
