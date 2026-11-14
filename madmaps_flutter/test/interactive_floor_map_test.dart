import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/interactive_floor_map.dart';
import 'package:madmaps/features/navigation/navigation_panel.dart';
import 'package:madmaps/features/navigation/routing.dart';

void main() {
  final location = FloorLocation('cafe', 'Cafe', '', 'cafe');
  final graph = FloorGraph(
    {
      'a': FloorNode('a', const Offset(500, 400), 'junction'),
      'cafe': FloorNode('cafe', const Offset(700, 400), 'approach'),
    },
    [FloorEdge('a', 'cafe', 200, true)],
    [location],
  );
  testWidgets(
    'rotation, zoom and pan keep tappable markers on their map points',
    (tester) async {
      final controller = FloorViewportController()..following = false;
      final setup = FloorSetup()..nodePoints['cafe'] = const Offset(680, 450);
      FloorLocation? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: InteractiveFloorMap(
                  graph: graph,
                  setup: setup,
                  controller: controller,
                  position: null,
                  heading: null,
                  route: const [],
                  fullRoute: const [],
                  onLocation: (l) => selected = l,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final viewport = find.byKey(const ValueKey('interactive-floor-map'));
      final middle = tester.getCenter(viewport);
      final first = await tester.startGesture(
        middle - const Offset(50, 0),
        pointer: 1,
      );
      final second = await tester.startGesture(
        middle + const Offset(50, 0),
        pointer: 2,
      );
      await tester.pump();
      // Rotate ninety degrees and enlarge around the same focal point.
      await first.moveTo(middle - const Offset(0, 75));
      await second.moveTo(middle + const Offset(0, 75));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      await tester.drag(viewport, const Offset(20, 10));
      await tester.pumpAndSettle();
      final transformFinder = find.descendant(
        of: viewport,
        matching: find.byType(Transform),
      );
      final transform = tester
          .widget<Transform>(transformFinder.first)
          .transform;
      expect(
        math.atan2(transform.entry(1, 0), transform.entry(0, 0)).abs(),
        greaterThan(1),
      );
      final localPoint = MatrixUtils.transformPoint(
        transform,
        setup.nodePoints['cafe']!,
      );
      final origin = tester.getTopLeft(viewport);
      final marker = find.byKey(const ValueKey('place-cafe'));
      expect(
        (tester.getCenter(marker) - origin - localPoint).distance,
        lessThan(.01),
      );
      await tester.tap(marker);
      expect(selected, same(location));
      controller.north();
      await tester.pump();
      final north = tester.widget<Transform>(transformFinder.first).transform;
      expect(north.entry(1, 0), closeTo(0, 1e-8));
      controller.recenter();
      await tester.pump();
      expect(controller.following, true);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('nearby overlapping places remain selectable from a cluster', (
    tester,
  ) async {
    final closeGraph = FloorGraph(
      {
        'cafe': FloorNode('cafe', const Offset(700, 400), 'approach'),
        'restroom': FloorNode('restroom', const Offset(710, 400), 'approach'),
      },
      [],
      [location, FloorLocation('restroom', 'Restroom', '', 'restroom')],
    );
    final controller = FloorViewportController();
    FloorLocation? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveFloorMap(
            graph: closeGraph,
            setup: FloorSetup(),
            controller: controller,
            position: null,
            heading: null,
            route: const [],
            fullRoute: const [],
            onLocation: (l) => selected = l,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cluster-cafe')));
    await tester.pumpAndSettle();
    expect(find.text('Places here'), findsOneWidget);
    await tester.tap(find.text('Restroom'));
    await tester.pumpAndSettle();
    expect(selected!.id, 'restroom');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets(
    'place card navigates through the selected destination callback',
    (tester) async {
      FloorLocation? selected;
      final guidance = GuidanceState()..select('cafe');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationPanel(
              graph: graph,
              setup: FloorSetup(),
              pose: null,
              calibration: FloorCalibration(Offset.zero, Offset.zero, 10, 0),
              guidance: guidance,
              destination: 'Existing trip',
              message: '',
              busy: false,
              onSearch: () {},
              onLocate: () {},
              onCancel: () {},
              onNavigate: (l) => selected = l,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('place-cafe')));
      await tester.pumpAndSettle();
      expect(find.text('Cafe'), findsOneWidget);
      expect(find.text('Floor 1'), findsOneWidget);
      expect(guidance.target, 'cafe');
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();
      expect(selected, same(location));
      expect(tester.takeException(), isNull);
    },
  );
}
