import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/routing.dart';

FloorGraph hall() => FloorGraph(
  {
    'a': FloorNode('a', Offset.zero, 'junction'),
    'b': FloorNode('b', const Offset(200, 0), 'junction'),
    'c': FloorNode('c', const Offset(200, 200), 'junction'),
    'd': FloorNode('d', const Offset(400, 200), 'approach'),
  },
  [
    FloorEdge('a', 'b', 200, true),
    FloorEdge('b', 'c', 200, true),
    FloorEdge('c', 'd', 200, true),
  ],
  [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FloorGraph bundled;
  setUpAll(() async {
    bundled = await FloorGraph.load();
  });
  final setup = FloorSetup();
  final calibration = FloorCalibration(Offset.zero, Offset.zero, 10, 0);
  final now = DateTime(2026);

  test(
    'return guidance survives tracking loss and resumes after rejoining',
    () {
      final g = GuidanceState()..select('d');
      final graph = hall();
      g.update(graph, setup, calibration, const Offset(50, 0), now);
      final original = g.route;
      g.update(graph, setup, calibration, const Offset(80, -60), now);
      g.update(
        graph,
        setup,
        calibration,
        const Offset(80, -60),
        now.add(const Duration(seconds: 3)),
      );
      expect(g.route, same(original));
      expect(g.phase, NavigationPhase.returningToRoute);
      expect(g.next, const Offset(80, 0));
      g.update(
        graph,
        setup,
        calibration,
        null,
        now.add(const Duration(seconds: 4)),
      );
      expect(g.phase, NavigationPhase.paused);
      expect(g.next, isNull);
      expect(g.estimatedDuration, isNull);
      expect(g.route, same(original));
      g.update(
        graph,
        setup,
        calibration,
        const Offset(90, -50),
        now.add(const Duration(seconds: 5)),
      );
      expect(g.next, const Offset(90, 0));
      g.update(
        graph,
        setup,
        calibration,
        const Offset(90, -20),
        now.add(const Duration(seconds: 6)),
      );
      expect(g.phase, NavigationPhase.navigating);
      expect(g.rejoinPoint, isNull);
      expect(g.status, contains('Turn right'));
      g.target = null;
      g.reset();
      expect(g.rejoinPoint, isNull);
      expect(g.phase, NavigationPhase.idle);
    },
  );
  test(
    'a reachable alternate corridor replaces the retained recovery route',
    () {
      final graph = FloorGraph(
        {
          'a': FloorNode('a', const Offset(0, 0), 'junction'),
          'b': FloorNode('b', const Offset(200, 0), 'approach'),
          'c': FloorNode('c', const Offset(0, 100), 'junction'),
          'd': FloorNode('d', const Offset(200, 100), 'junction'),
        },
        [
          FloorEdge('a', 'b', 200, true),
          FloorEdge('a', 'c', 100, true),
          FloorEdge('c', 'd', 200, true),
          FloorEdge('d', 'b', 100, true),
        ],
        [],
      );
      final g = GuidanceState()..select('b');
      g.update(graph, setup, calibration, const Offset(50, 0), now);
      final original = g.route;
      g.update(graph, setup, calibration, const Offset(70, 100), now);
      g.update(
        graph,
        setup,
        calibration,
        const Offset(70, 100),
        now.add(const Duration(seconds: 3)),
      );
      expect(g.route, isNot(same(original)));
      expect(g.route!.startEdge, 'c->d');
      expect(g.phase, NavigationPhase.navigating);
    },
  );

  test(
    'a distant destination starts with return guidance to a reachable segment',
    () {
      final g = GuidanceState()..select('d');
      final graph = hall();
      final start = const Offset(80, -100);
      expect(
        findRoute(graph, setup, start, 'd', 10).failure,
        RouteFailure.noNearbyEdge,
      );
      g.update(graph, setup, calibration, start, now);
      expect(g.phase, NavigationPhase.returningToRoute);
      expect(g.rejoinPoint, const Offset(80, 0));
      expect(g.next, g.rejoinPoint);
      expect(g.rejoinMeters, 10);
      expect(g.remainingMeters, 62);
      g.update(graph, setup, calibration, const Offset(80, -20), now);
      expect(g.phase, NavigationPhase.navigating);
      expect(g.rejoinPoint, isNull);
    },
  );
  test(
    'distant attachment skips disconnected segments and respects one-way entry',
    () {
      final graph = FloorGraph(
        {
          'a': FloorNode('a', const Offset(0, 0), 'junction'),
          'b': FloorNode('b', const Offset(100, 0), 'approach'),
          'c': FloorNode('c', const Offset(0, 100), 'junction'),
          'd': FloorNode('d', const Offset(100, 100), 'approach'),
          'isolated': FloorNode('isolated', const Offset(500, 500), 'approach'),
        },
        [FloorEdge('a', 'b', 100, false), FloorEdge('c', 'd', 100, false)],
        [],
      );
      final g = GuidanceState()..select('d');
      g.update(graph, setup, calibration, const Offset(50, -10), now);
      expect(g.route!.startEdge, 'c->d');
      expect(g.phase, NavigationPhase.returningToRoute);
      expect(g.rejoinPoint, const Offset(50, 100));
      final toStart = findRoute(
        graph,
        setup,
        const Offset(50, -100),
        'a',
        10,
        allowDistantAttachment: true,
      );
      expect(toStart.route!.points, [Offset.zero]);
      expect(
        findRoute(
          graph,
          setup,
          const Offset(50, -100),
          'isolated',
          10,
          allowDistantAttachment: true,
        ).failure,
        RouteFailure.disconnected,
      );
      final unreachable = GuidanceState()..select('isolated');
      unreachable.update(graph, setup, calibration, Offset.zero, now);
      expect(unreachable.phase, NavigationPhase.unavailable);
      expect(unreachable.route, isNull);
    },
  );
  test('University exit to Cafe works at low and high calibration scales', () {
    for (final scale in [5.0, 10.0, 20.0, 40.0]) {
      final result = findRoute(
        bundled,
        setup,
        bundled.nodes['f1-exit-university']!.point,
        'f1-demo-cafe',
        scale,
      );
      expect(result.failure, isNull, reason: 'scale=$scale');
      expect(result.route!.attachmentPixels, 0);
      expect(result.route!.points.last, bundled.nodes['f1-demo-cafe']!.point);
      expect(result.route!.startEdge, contains('f1-exit-university'));
    }
  });
  test(
    'every mapped approach can start a route to every mapped destination',
    () {
      final approaches = bundled.nodes.values.where(
        (n) => n.kind == 'approach',
      );
      for (final scale in [5.0, 20.0, 40.0]) {
        for (final start in approaches) {
          for (final target in approaches) {
            expect(
              findRoute(bundled, setup, start.point, target.id, scale).route,
              isNotNull,
              reason: '${start.id} -> ${target.id} at $scale px/m',
            );
          }
        }
      }
    },
  );
  test('parallel offset never requires visiting the initial projection', () {
    final g = GuidanceState()..select('d');
    g.update(hall(), setup, calibration, const Offset(20, 20), now);
    expect(g.route!.points.first, const Offset(20, 0));
    expect(g.next, const Offset(40, 20));
    g.update(hall(), setup, calibration, const Offset(100, 20), now);
    expect(g.next, const Offset(120, 20));
    expect(g.projected, const Offset(100, 0));
    expect(g.remainingMeters, 50);
    expect(g.offRouteSince, isNull);
    expect(g.status, 'Turn right in 10.0 m');
  });
  test(
    'lookahead stops at a turn, then advances without returning to its vertex',
    () {
      final g = GuidanceState()..select('d');
      g.update(hall(), setup, calibration, const Offset(20, 20), now);
      g.update(hall(), setup, calibration, const Offset(195, 20), now);
      expect(g.next, const Offset(200, 20));
      g.update(hall(), setup, calibration, const Offset(220, 50), now);
      expect(g.segment, 1);
      expect(g.next, const Offset(220, 70));
    },
  );
  test('missed samples and localization corrections reassess later legs', () {
    final g = GuidanceState()..select('d');
    g.update(hall(), setup, calibration, const Offset(20, 0), now);
    g.update(
      hall(),
      setup,
      calibration,
      const Offset(300, 210),
      now,
      relocalized: true,
    );
    expect(g.segment, 2);
    expect(g.projected, const Offset(300, 200));
    expect(g.next, const Offset(320, 210));
    expect(g.remainingMeters, 10);
  });
  test('nearby parallel legs do not steal a plausible current match', () {
    final graph = FloorGraph(
      {
        'a': FloorNode('a', Offset.zero, 'junction'),
        'b': FloorNode('b', const Offset(200, 0), 'junction'),
        'c': FloorNode('c', const Offset(200, 40), 'junction'),
        'd': FloorNode('d', const Offset(0, 40), 'approach'),
      },
      [
        FloorEdge('a', 'b', 200, true),
        FloorEdge('b', 'c', 40, true),
        FloorEdge('c', 'd', 200, true),
      ],
      [],
    );
    final g = GuidanceState()..select('d');
    g.update(graph, setup, calibration, const Offset(20, 0), now);
    g.update(graph, setup, calibration, const Offset(80, 25), now);
    expect(g.segment, 0);
    expect(g.next, const Offset(100, 25));
    expect(g.remainingMeters, 36);
  });
  test(
    'reverse walking updates distance and can return to the previous leg',
    () {
      final g = GuidanceState()..select('d');
      final graph = hall();
      g.update(graph, setup, calibration, const Offset(20, 0), now);
      g.update(graph, setup, calibration, const Offset(120, 20), now);
      final distance = g.remainingMeters!;
      g.update(graph, setup, calibration, const Offset(80, 20), now);
      expect(g.remainingMeters!, greaterThan(distance));
      expect(g.next, const Offset(100, 20));
      g.update(graph, setup, calibration, const Offset(200, 80), now);
      expect(g.segment, 1);
      g.update(graph, setup, calibration, const Offset(150, -10), now);
      expect(g.segment, 0);
      expect(g.next, const Offset(170, -10));
    },
  );
  test('off-route hysteresis tolerates noise and recovers within corridor', () {
    final g = GuidanceState()..select('d');
    final graph = hall();
    g.update(graph, setup, calibration, const Offset(20, 0), now);
    g.update(graph, setup, calibration, const Offset(80, -39), now);
    expect(g.offRouteSince, isNull);
    g.update(graph, setup, calibration, const Offset(80, -41), now);
    expect(g.offRouteSince, now);
    expect(g.next, const Offset(100, -41));
    g.update(
      graph,
      setup,
      calibration,
      const Offset(80, -35),
      now.add(const Duration(seconds: 1)),
    );
    expect(g.offRouteSince, now);
    g.update(
      graph,
      setup,
      calibration,
      const Offset(80, -30),
      now.add(const Duration(milliseconds: 1500)),
    );
    expect(g.offRouteSince, isNull);
    expect(g.route, isNotNull);
    g.update(
      graph,
      setup,
      calibration,
      const Offset(80, -50),
      now.add(const Duration(seconds: 2)),
    );
    g.update(
      graph,
      setup,
      calibration,
      const Offset(80, -50),
      now.add(const Duration(seconds: 4)),
    );
    expect(g.route, isNotNull);
    expect(g.next, const Offset(80, 0));
    expect(g.rejoinMeters, 5);
    expect(g.remainingMeters, 57);
    expect(g.phase, NavigationPhase.returningToRoute);
    expect(g.result!.failure, RouteFailure.noNearbyEdge);
    expect(g.status, contains('Return to route'));
    g.update(
      graph,
      setup,
      calibration,
      const Offset(80, -10),
      now.add(const Duration(seconds: 5)),
    );
    expect(g.route, isNotNull);
    expect(g.next, const Offset(100, -10));
  });
  test(
    'arrival needs actual entrance proximity, not just route projection',
    () {
      final g = GuidanceState()..select('d');
      final graph = hall();
      g.update(graph, setup, calibration, const Offset(20, 0), now);
      g.update(
        graph,
        setup,
        calibration,
        const Offset(400, 225),
        now,
        relocalized: true,
      );
      expect(g.status, isNot(contains('Near entrance')));
      g.update(graph, setup, calibration, const Offset(400, 210), now);
      expect(g.status, 'Near entrance (estimated)');
      expect(g.next, isNull);
    },
  );
  test(
    'nearby directed attachments are tried if the nearest is disconnected',
    () {
      final graph = FloorGraph(
        {
          'a': FloorNode('a', Offset.zero, 'junction'),
          'b': FloorNode('b', const Offset(100, 0), 'junction'),
          'c': FloorNode('c', const Offset(0, 20), 'junction'),
          'd': FloorNode('d', const Offset(100, 20), 'approach'),
        },
        [FloorEdge('a', 'b', 100, false), FloorEdge('c', 'd', 100, true)],
        [],
      );
      final result = findRoute(graph, setup, const Offset(50, 0), 'd', 10);
      expect(result.route!.startEdge, 'c->d');
      expect(result.route!.attachmentPixels, 20);
      expect(
        findRoute(graph, setup, Offset.zero, null, 10).failure,
        RouteFailure.unmappedDestination,
      );
      expect(
        findRoute(graph, setup, Offset.zero, 'missing', 10).failure,
        RouteFailure.invalidDestination,
      );
    },
  );
  test(
    'equal-distance attachments use route cost without breaking one-way edges',
    () {
      final graph = FloorGraph(
        {
          'a': FloorNode('a', Offset.zero, 'junction'),
          'b': FloorNode('b', const Offset(100, 0), 'junction'),
          'c': FloorNode('c', const Offset(0, 20), 'junction'),
          'd': FloorNode('d', const Offset(100, 20), 'junction'),
          'target': FloorNode('target', const Offset(200, 10), 'approach'),
        },
        [
          FloorEdge('a', 'b', 100, false),
          FloorEdge('c', 'd', 100, false),
          FloorEdge('b', 'target', 1000, true),
          FloorEdge('d', 'target', 100, true),
        ],
        [],
      );
      expect(
        findRoute(
          graph,
          setup,
          const Offset(50, 10),
          'target',
          10,
        ).route!.startEdge,
        'c->d',
      );
      expect(
        findRoute(graph, setup, const Offset(50, 0), 'a', 10).failure,
        RouteFailure.disconnected,
      );
    },
  );
  test('diagnostics distinguish failures and avoid per-frame log spam', () {
    final logs = <String>[];
    final g = GuidanceState(onDiagnostic: logs.add)..select('d');
    for (var i = 0; i < 5; i++) {
      g.update(hall(), setup, calibration, const Offset(20, 20), now);
    }
    expect(logs.length, 1);
    expect(logs.single, contains('startEdge=a->b'));
    expect(logs.single, contains('attachmentMeters=2.0'));
    expect(logs.single, contains('progressMeters='));
    g.update(hall(), setup, calibration, null, now);
    expect(g.next, isNull);
    expect(g.status, contains('paused'));
  });
  test('sustained departure can reattach to a different connected walkway', () {
    final graph = hall();
    graph.nodes['e'] = FloorNode('e', const Offset(0, -80), 'junction');
    graph.nodes['f'] = FloorNode('f', const Offset(400, -80), 'junction');
    graph.edges.addAll([
      FloorEdge('a', 'e', 80, true),
      FloorEdge('e', 'f', 1000, true),
      FloorEdge('f', 'd', 280, true),
    ]);
    final g = GuidanceState()..select('d');
    g.update(graph, setup, calibration, const Offset(20, 0), now);
    expect(g.route!.startEdge, 'a->b');
    g.update(graph, setup, calibration, const Offset(100, -80), now);
    g.update(
      graph,
      setup,
      calibration,
      const Offset(100, -80),
      now.add(const Duration(seconds: 2)),
    );
    expect(g.route!.startEdge, 'e->f');
    expect(g.result!.failure, isNull);
    expect(g.next, isNotNull);
    expect(g.offRouteSince, isNull);
  });
  test(
    'starting at destination and then leaving does not retain false arrival',
    () {
      final graph = hall();
      final g = GuidanceState()..select('d');
      g.update(graph, setup, calibration, const Offset(400, 200), now);
      expect(g.status, 'Near entrance (estimated)');
      g.update(graph, setup, calibration, const Offset(380, 210), now);
      expect(g.status, isNot(contains('Near entrance')));
      expect(g.next, const Offset(400, 210));
    },
  );
}
