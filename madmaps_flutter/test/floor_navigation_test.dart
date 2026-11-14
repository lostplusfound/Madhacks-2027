import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/routing.dart';
import 'package:madmaps/features/localization/map_data.dart';
import 'package:vector_math/vector_math_64.dart';

FloorGraph fixture({bool reverse = true}) => FloorGraph(
  {
    'a': FloorNode('a', Offset.zero, 'junction'),
    'b': FloorNode('b', const Offset(100, 0), 'junction'),
    'c': FloorNode('c', const Offset(100, 100), 'junction'),
    'room': FloorNode('room', const Offset(110, 100), 'approach'),
    'isolated': FloorNode('isolated', const Offset(400, 400), 'approach'),
  },
  [
    FloorEdge('a', 'b', 100, reverse),
    FloorEdge('b', 'c', 100, true),
    FloorEdge('c', 'room', 10, true),
    FloorEdge('a', 'c', 500, true),
  ],
  [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'bundled data has connected floor-one routes and room mappings',
    () async {
      final graph = await FloorGraph.load();
      expect(graph.nodes.length, 20);
      expect(graph.edges.length, 19);
      expect(graph.locations.length, 13);
      final route = findRoute(
        graph,
        FloorSetup(),
        graph.nodes['f1-demo-south-hall']!.point,
        'f1-demo-cafe',
        20,
      );
      expect(route.failure, isNull);
      expect(route.route!.points.last, graph.nodes['f1-demo-cafe']!.point);
    },
  );
  test('Dijkstra uses weighted shortest path from a fractional edge', () {
    final route = findRoute(
      fixture(),
      FloorSetup(),
      const Offset(50, -5),
      'room',
      10,
    ).route!;
    expect(route.cost, closeTo(165, .001));
    expect(route.points, contains(const Offset(100, 0)));
    expect(
      findRoute(
        fixture(),
        FloorSetup(),
        const Offset(50, 0),
        'isolated',
        10,
      ).failure,
      RouteFailure.disconnected,
    );
    expect(
      findRoute(
        fixture(),
        FloorSetup(),
        const Offset(500, 0),
        'room',
        10,
      ).failure,
      RouteFailure.noNearbyEdge,
    );
    expect(
      findRoute(fixture(), FloorSetup(), Offset.zero, 'missing', 10).failure,
      RouteFailure.invalidDestination,
    );
  });
  test('one-way start edge cannot travel backward', () {
    final graph = fixture(reverse: false);
    // No return path exists once the unrelated diagonal is removed.
    graph.edges.removeLast();
    expect(
      findRoute(graph, FloorSetup(), const Offset(50, 0), 'a', 10).failure,
      RouteFailure.disconnected,
    );
    expect(
      findRoute(graph, FloorSetup(), const Offset(50, 0), 'room', 10).route,
      isNotNull,
    );
  });
  test('edited nodes update incident costs', () {
    final graph = fixture(), setup = FloorSetup();
    setup.nodePoints['b'] = const Offset(200, 0);
    expect(graph.cost(graph.edges.first, setup), 200);
  });
  test('rotated translated calibration round trip and invalid pairs', () {
    final c = FloorCalibration.pair(
      const Offset(3, 5),
      const Offset(5, 5),
      const Offset(100, 200),
      const Offset(100, 240),
    );
    expect(c.scale, 20);
    expect(c.toImage(const Offset(4, 6)), const Offset(80, 220));
    expect(
      (c.toMap(c.toImage(const Offset(-3, 10))) - const Offset(-3, 10))
          .distance,
      lessThan(1e-8),
    );
    expect(
      () => FloorCalibration.pair(
        Offset.zero,
        const Offset(1, 0),
        Offset.zero,
        const Offset(100, 0),
      ),
      throwsStateError,
    );
    expect(
      () => FloorCalibration.pair(
        Offset.zero,
        const Offset(3, 0),
        Offset.zero,
        Offset.zero,
      ),
      throwsStateError,
    );
  });
  test('legacy maps and floor setup persist without changing poses', () {
    final legacy = AnchorMap.fromJson({
      'id': 'old',
      'name': 'Old',
      'anchors': [],
    });
    expect(legacy.floor.enabled, false);
    legacy.anchors.addAll([
      SavedAnchor(
        'a',
        'A',
        'cloudA',
        Matrix4.translationValues(0, 1, 0),
        DateTime(2030),
      ),
      SavedAnchor(
        'b',
        'B',
        'cloudB',
        Matrix4.translationValues(3, 8, 0),
        DateTime(2030),
      ),
    ]);
    legacy.floor.enabled = true;
    legacy.floor.anchorPoints.addAll({
      'a': Offset.zero,
      'b': const Offset(60, 0),
    });
    legacy.floor.calibrationIds.addAll(['a', 'b']);
    final restored = AnchorMap.fromJson(legacy.toJson());
    expect(restored.floor.calibration(restored)!.scale, 20);
    expect(restored.anchors[1].pose.entry(1, 3), 8);
    restored.anchors.removeLast();
    expect(restored.floor.calibration(restored), isNull);
  });
  test('turn directions use image-down coordinates', () {
    expect(
      turnInstruction(const Offset(1, 0), const Offset(0, 1)),
      'Turn right',
    );
    expect(
      turnInstruction(const Offset(1, 0), const Offset(0, -1)),
      'Turn left',
    );
    expect(
      turnInstruction(const Offset(1, 0), const Offset(1, .1)),
      'Continue',
    );
  });
  test('guidance pauses, resumes, advances and arrives', () {
    final g = GuidanceState()..select('room');
    final graph = fixture(), setup = FloorSetup();
    final c = FloorCalibration(Offset.zero, Offset.zero, 10, 0);
    final now = DateTime(2026);
    g.update(graph, setup, c, const Offset(50, 0), now);
    expect(g.next, const Offset(70, 0));
    expect(g.status, contains('Turn right'));
    g.update(graph, setup, c, null, now);
    expect(g.next, isNull);
    expect(g.status, contains('paused'));
    // A localization correction can move past a turn without sampling its radius.
    g.update(graph, setup, c, const Offset(100, 40), now);
    expect(g.next, const Offset(100, 60));
    g.update(graph, setup, c, const Offset(100, 100), now);
    expect(g.status, 'Near entrance (estimated)');
  });
  test('off-route grace period then recomputation', () {
    final g = GuidanceState()..select('room');
    final graph = fixture(), setup = FloorSetup(), now = DateTime(2026);
    final c = FloorCalibration(Offset.zero, Offset.zero, 10, 0);
    g.update(graph, setup, c, const Offset(50, 0), now);
    g.update(graph, setup, c, const Offset(500, 500), now);
    expect(g.next, isNotNull);
    expect(g.route, isNotNull);
    g.update(
      graph,
      setup,
      c,
      const Offset(500, 500),
      now.add(const Duration(seconds: 2)),
    );
    expect(g.route, isNull);
  });
  test('CSV quoting and invalid references are handled', () {
    expect(readCsv('a,b\n"one,two","a""b"\n')[1], ['one,two', 'a"b']);
    expect(
      () => FloorGraph.parse(
        'node_id,floor,x,y,location_id,kind,status\na,1,0,0,,junction,draft',
        'from_node_id,to_node_id,type,cost_px,bidirectional,status\na,missing,walk,1,true,draft',
        'location_id,floor,room_number,name,category,aliases,route_node_id,review_note',
      ),
      throwsFormatException,
    );
  });
}
