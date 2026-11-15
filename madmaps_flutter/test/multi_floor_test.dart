import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:madmaps/main.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/interactive_floor_map.dart';
import 'package:madmaps/features/navigation/map_repository.dart';
import 'package:madmaps/features/shell/app_state.dart';
import 'package:madmaps/features/shell/madmaps_shell.dart';
import 'package:madmaps/features/shell/navigation_session.dart';
import 'map_repository_test.dart' show fixture, MemoryRepository;

class AllFloorsRepository extends MemoryRepository
    implements MultiFloorMapRepository {
  AllFloorsRepository(this.floors) : super(floors[1]!);
  final Map<int, FloorGraph> floors;
  @override
  Future<Map<int, FloorGraph>> loadFloors() async => floors;
  @override
  Future<List<String>> search(String query, {String? category}) async => floors
      .values
      .expand((g) => g.locations)
      .where((l) => l.label.toLowerCase().contains(query.toLowerCase()))
      .map((l) => l.id)
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final floors = <int, FloorGraph>{};
  setUpAll(() async {
    for (final f in [0, 1, 2, 3]) {
      floors[f] = await adaptSnapshot(fixture(f), floorNumber: f).loadRooms();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });
  test('all 64 polygons match destinations and original image dimensions', () {
    expect(floors.values.fold<int>(0, (n, f) => n + f.rooms.length), 64);
    for (final f in floors.values) {
      expect(f.imageSize, const Size(1632, 1056));
      expect(f.rooms, isNotEmpty);
      expect(f.locations.every((l) => l.floor == f.floor), isTrue);
      for (final r in f.rooms) {
        expect(r.area, greaterThan(0));
        expect(f.locations.any((l) => l.id == r.locationId), isTrue);
      }
    }
    expect(floors[1]!.nodes.containsKey('f1-cafe-restroom-1-approach'), isTrue);
    expect(floors[1]!.rooms.length, 4);
  });
  test('reject malformed, out-of-bounds and zero-area room geometry', () {
    for (final points in [
      [],
      [
        [0, 0],
        [1, 1],
      ],
      [
        [0, 0],
        [1, 1],
        [2, 2],
      ],
      [
        [-1, 0],
        [1, 0],
        [1, 1],
      ],
      [
        [0, 0],
        [double.nan, 1],
        [1, 0],
      ],
      [
        [0, 0],
        [1633, 0],
        [1, 1],
      ],
    ]) {
      expect(
        () => RoomPolygon.parse('bad', points, floorImageSize),
        throwsFormatException,
      );
    }
  });
  test('overlapping rooms select smallest polygon; hallway has no room', () {
    RoomPolygon box(String id, double n) => RoomPolygon(id, [
      Offset.zero,
      Offset(n, 0),
      Offset(n, n),
      Offset(0, n),
    ]);
    final g = FloorGraph(
      {},
      [],
      [
        FloorLocation('large', 'Large', '', null),
        FloorLocation('small', 'Small', '', null),
      ],
      rooms: [box('large', 100), box('small', 30)],
    );
    expect(g.roomAt(const Offset(20, 20))!.id, 'small');
    expect(g.roomAt(const Offset(50, 50))!.id, 'large');
    expect(g.roomAt(const Offset(101, 50)), isNull);
  });
  testWidgets(
    'polygon taps stay aligned after zoom, pan and rotation; marker wins',
    (tester) async {
      final controller = FloorViewportController()..following = false;
      final room = RoomPolygon('room', [
        const Offset(400, 300),
        const Offset(800, 300),
        const Offset(800, 700),
        const Offset(400, 700),
      ]);
      final g = FloorGraph(
        {
          'node': FloorNode('node', const Offset(700, 500), 'approach'),
          'extent': FloorNode('extent', const Offset(400, 300), 'junction'),
        },
        [],
        [
          FloorLocation('room', 'Room', '', null),
          FloorLocation('marker', 'Marker', '', 'node'),
        ],
        rooms: [room],
      );
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveFloorMap(
              graph: g,
              setup: FloorSetup(),
              controller: controller,
              position: null,
              heading: null,
              route: const [],
              fullRoute: const [],
              onLocation: (l) => selected = l.id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
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
      final origin = tester.getTopLeft(
        find.byKey(const ValueKey('interactive-floor-map')),
      );
      final gesture = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('interactive-floor-map')),
      );
      gesture.onScaleStart!(
        ScaleStartDetails(localFocalPoint: const Offset(400, 300)),
      );
      gesture.onScaleUpdate!(
        ScaleUpdateDetails(
          localFocalPoint: const Offset(430, 330),
          scale: .7,
          rotation: math.pi / 5,
          pointerCount: 2,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(
        origin +
            MatrixUtils.transformPoint(transform(), const Offset(500, 400)),
      );
      await tester.pump();
      expect(selected, 'room');
      await tester.tap(find.byKey(const ValueKey('place-marker')));
      await tester.pump();
      expect(selected, 'marker');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  testWidgets(
    'browse every floor while preserving Floor 1 trip and navigator',
    (tester) async {
      final state = AppState(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        MyApp(state: state, repository: AllFloorsRepository(floors)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();
      final dynamic shell = tester.state(find.byType(MadMapsShell));
      final session = shell.session as NavigationSession;
      final destination = floors[1]!.locations.firstWhere(
        (l) => l.node != null,
      );
      session.choose(destination);
      await tester.pumpAndSettle();
      final navigator = shell.mapNavigator.currentState;
      for (final f in [0, 2, 3]) {
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .onChanged!(f);
        await tester.pumpAndSettle();
        expect(
          find.text('Navigation available on Floor 1 only'),
          findsNothing,
        );
        expect(find.text('Find my location'), findsOneWidget);
        expect(session.destination, same(destination));
        expect(shell.mapNavigator.currentState, same(navigator));
        final map = tester.widget<InteractiveFloorMap>(
          find.byType(InteractiveFloorMap),
        );
        expect(map.graph.floor, f);
        expect(map.position, isNull);
        expect(map.route, isEmpty);
      }
      await tester.ensureVisible(find.text('Return to navigation'));
      await tester.tap(find.text('Return to navigation'));
      await tester.pumpAndSettle();
      expect(find.text('Find my location'), findsOneWidget);
      expect(session.destination, same(destination));
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('floor image asset bytes match the handoff dimensions', () {
    for (final f in [0, 2, 3]) {
      final bytes = File('assets/maps/floor$f.png').readAsBytesSync();
      final data = ByteData.sublistView(bytes);
      expect(data.getUint32(16), 1632);
      expect(data.getUint32(20), 1056);
    }
    final json = jsonDecode(
      File('assets/maps/room_shapes.json').readAsStringSync(),
    );
    expect(json['version'], 1);
  });
}
