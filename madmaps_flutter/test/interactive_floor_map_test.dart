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
    'heading follow centers pose, wraps smoothly, and retains zoom while pinching',
    (tester) async {
      final controller = FloorViewportController()..navigation(true);
      var p = const Offset(600, 400);
      Widget map(Offset? h) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: InteractiveFloorMap(
                graph: graph,
                setup: FloorSetup(),
                controller: controller,
                position: p,
                heading: h,
                route: const [],
                fullRoute: const [],
                onLocation: (_) {},
              ),
            ),
          ),
        ),
      );
      Offset headingAt(double target) =>
          p +
          Offset(
            math.cos(-math.pi / 2 - target),
            math.sin(-math.pi / 2 - target),
          );
      Matrix4 transform() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('interactive-floor-map')),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform;
      double angle() =>
          math.atan2(transform().entry(1, 0), transform().entry(0, 0));
      await tester.pumpWidget(map(headingAt(math.pi - .02)));
      await tester.pumpAndSettle();
      expect(
        (MatrixUtils.transformPoint(transform(), p) - const Offset(200, 200))
            .distance,
        lessThan(.01),
      );
      final before = angle();
      await tester.pumpWidget(map(headingAt(-math.pi + .02)));
      await tester.pump(const Duration(milliseconds: 110));
      final halfway = angle();
      expect(
        math
            .atan2(math.sin(halfway - before), math.cos(halfway - before))
            .abs(),
        lessThan(.05),
      );
      await tester.pumpAndSettle();
      final forward =
          MatrixUtils.transformPoint(transform(), headingAt(-math.pi + .02)) -
          MatrixUtils.transformPoint(transform(), p);
      expect(forward.dx, closeTo(0, 1e-5));
      expect(forward.dy, lessThan(0));
      final held = angle();
      p = const Offset(620, 420);
      await tester.pumpWidget(map(null));
      await tester.pumpAndSettle();
      expect(angle(), closeTo(held, 1e-6));
      expect(
        (MatrixUtils.transformPoint(transform(), p) - const Offset(200, 200))
            .distance,
        lessThan(.01),
      );
      final viewport = find.byKey(const ValueKey('interactive-floor-map'));
      final middle = tester.getCenter(viewport),
          scale = transform().getMaxScaleOnAxis();
      final first = await tester.startGesture(
        middle - const Offset(40, 0),
        pointer: 1,
      );
      final second = await tester.startGesture(
        middle + const Offset(40, 0),
        pointer: 2,
      );
      await tester.pump();
      await first.moveTo(middle - const Offset(60, 0));
      await second.moveTo(middle + const Offset(60, 0));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(controller.mode, FloorFollowMode.heading);
      expect(transform().getMaxScaleOnAxis(), greaterThan(scale));
      expect(
        (MatrixUtils.transformPoint(transform(), p) - const Offset(200, 200))
            .distance,
        lessThan(.01),
      );
      await tester.drag(viewport, const Offset(30, 10));
      await tester.pumpAndSettle();
      expect(controller.mode, FloorFollowMode.free);
      controller.recenter();
      await tester.pumpAndSettle();
      expect(controller.mode, FloorFollowMode.heading);
      controller.north();
      await tester.pumpAndSettle();
      expect(controller.mode, FloorFollowMode.position);
      expect(angle(), closeTo(0, 1e-6));
      controller.overview();
      await tester.pumpAndSettle();
      expect(controller.mode, FloorFollowMode.free);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
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
      // Move both pointers beyond gesture slop before rotating incrementally.
      await first.moveTo(middle - const Offset(100, 0));
      await second.moveTo(middle + const Offset(100, 0));
      await tester.pump();
      for (var step = 1; step <= 12; step++) {
        final angle = math.pi / 2 * step / 12;
        final offset = Offset(math.cos(angle) * 100, math.sin(angle) * 100);
        await first.moveTo(middle - offset);
        await second.moveTo(middle + offset);
        await tester.pump();
      }
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
