import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/navigation_panel.dart';
import 'package:madmaps/features/navigation/routing.dart';
import 'package:madmaps/features/navigation/interactive_floor_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FloorGraph graph;
  setUpAll(() async {
    graph = await FloorGraph.load();
  });
  test('all six newly connected amenities route from the main hall', () async {
    final amenities = graph.locations.where(
      (l) =>
          l.id.contains('restroom') ||
          l.id == 'f1-main-stairs' ||
          l.id == 'f1-elevator-bank',
    );
    expect(amenities.length, 6);
    for (final l in amenities) {
      expect(l.node, isNotNull);
      expect(
        findRoute(
          graph,
          FloorSetup(),
          graph.nodes['f1-demo-main-hall']!.point,
          l.node,
          20,
        ).failure,
        isNull,
        reason: l.label,
      );
    }
  });
  test('walking ETA clears when guidance pauses', () {
    final g = GuidanceState()
      ..target = 'entrance'
      ..remainingMeters = 120;
    expect(g.estimatedDuration, const Duration(seconds: 100));
    g.update(FloorGraph({}, [], []), FloorSetup(), null, null, DateTime.now());
    expect(g.estimatedDuration, isNull);
    expect(g.maneuverMeters, isNull);
    expect(g.arrived, false);
  });
  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      'long floor-transition guidance stays separated at text scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(390, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const instruction =
            'Take Northeast stairs to Floor 1. Scan surroundings after exiting.';
        const status =
            'Scan your surroundings slowly. Searching 7 saved anchors...';
        final guidance = GuidanceState()..status = instruction;
        Rect? mapBounds;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: const Size(390, 780),
                  textScaler: TextScaler.linear(scale),
                ),
                child: NavigationPanel(
                  graph: graph,
                  setup: FloorSetup(),
                  pose: null,
                  calibration: FloorCalibration(
                    Offset.zero,
                    Offset.zero,
                    10,
                    0,
                  ),
                  guidance: guidance,
                  destination: 'Room 1524',
                  message: status,
                  busy: true,
                  onSearch: () {},
                  onLocate: () {},
                  onCancel: () {},
                  onMapBoundsChanged: (rect) => mapBounds = rect,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final instructionBox = tester.getRect(
          find.byKey(const ValueKey('navigation-instruction')),
        );
        final statusBox = tester.getRect(
          find.byKey(const ValueKey('navigation-status')),
        );
        expect(statusBox.top, greaterThan(instructionBox.bottom));
        expect(find.text(instruction), findsOneWidget);
        expect(find.text('Cancel search'), findsOneWidget);
        expect(mapBounds, isNotNull);
        expect(mapBounds!.height, greaterThan(0));
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'estimated localization notice preserves turns and phone layout controls',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final g = GuidanceState()
        ..remainingMeters = 24
        ..maneuver = 'Turn left'
        ..maneuverMeters = 8;
      var cancelled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(1.5),
              ),
              child: NavigationPanel(
                graph: graph,
                setup: FloorSetup(),
                pose: Matrix4.identity(),
                calibration: FloorCalibration(Offset.zero, Offset.zero, 10, 0),
                guidance: g,
                destination: 'Cafe',
                message:
                    'Using AR position (estimated). Retrying automatically.',
                estimated: true,
                busy: false,
                onSearch: () {},
                onLocate: () {},
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Turn left in 8 m'), findsOneWidget);
      expect(
        find.textContaining('Using AR position (estimated)'),
        findsOneWidget,
      );
      expect(find.textContaining('Less than 1 min'), findsOneWidget);
      await tester.tap(find.byTooltip('Recenter'));
      await tester.tap(find.byTooltip('Map overview'));
      await tester.tap(find.text('Cancel'));
      expect(cancelled, true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'lost tracking hides map pose and announces automatic localization',
    (tester) async {
      final g = GuidanceState()..select('f1-demo-cafe');
      final c = FloorCalibration(Offset.zero, Offset.zero, 10, 0);
      g.update(graph, FloorSetup(), c, null, DateTime.now());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationPanel(
              graph: graph,
              setup: FloorSetup(),
              pose: null,
              calibration: c,
              guidance: g,
              destination: 'Cafe',
              message: 'Tracking lost - relocalizing automatically.',
              busy: false,
              estimated: true,
              onSearch: () {},
              onLocate: () {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Tracking lost - relocalizing automatically.'),
        findsOneWidget,
      );
      final map = tester.widget<InteractiveFloorMap>(
        find.byType(InteractiveFloorMap),
      );
      expect(map.position, isNull);
      expect(map.heading, isNull);
      expect(g.phase, NavigationPhase.paused);
      expect(g.estimatedDuration, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
