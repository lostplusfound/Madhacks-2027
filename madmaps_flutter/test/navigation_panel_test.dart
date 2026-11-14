import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/navigation_panel.dart';
import 'package:madmaps/features/navigation/routing.dart';

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
  testWidgets(
    'phone layout supports cancellation, recenter and lost localization',
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
                pose: null,
                calibration: null,
                guidance: g,
                destination: 'Cafe',
                message: 'Scan surroundings',
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
      expect(find.textContaining('Less than 1 min'), findsOneWidget);
      await tester.tap(find.byTooltip('Recenter'));
      await tester.tap(find.byTooltip('Map overview'));
      await tester.tap(find.text('Cancel'));
      expect(cancelled, true);
      expect(tester.takeException(), isNull);
    },
  );
}
