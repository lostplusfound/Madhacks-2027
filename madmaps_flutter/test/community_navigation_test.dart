import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/features/localization/capture_screen.dart';
import 'package:madmaps/features/localization/map_data.dart';
import 'package:madmaps/features/localization/shared_captures.dart';
import 'package:madmaps/features/localization/prototype_screen.dart';
import 'package:madmaps/features/navigation/building_routing.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/floor_screen.dart';
import 'package:madmaps/features/shell/app_state.dart';
import 'package:madmaps/features/shell/route_planner_screen.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_captures_test.dart' show CaptureClient, scan;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FloorGraph graph;
  setUpAll(() async {
    graph = await FloorGraph.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'automatic placement projects aligned poses and rejects invalid positions',
    () {
      final map = scan();
      final calibration = map.floor.calibration(map)!;
      final pose = Matrix4.translationValues(1, 0, 2);
      final expected = calibration.toImage(const Offset(1, 2));
      expect(captureImagePoint(map, pose, const Size(10000, 10000)), expected);
      expect(() => captureImagePoint(map, pose, Size.zero), throwsStateError);
      map.floor.calibrationIds.clear();
      expect(
        () => captureImagePoint(map, pose, const Size(10000, 10000)),
        throwsStateError,
      );
    },
  );

  testWidgets('scan placement uses an arbitrary pin on an uncluttered plan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: GuidedCaptureScreen(graph: graph)),
    );
    await tester.pumpAndSettle();
    final canvas = tester.widget<FloorCanvas>(find.byType(FloorCanvas));
    expect(canvas.showLabels, isFalse);
    expect(canvas.showGraph, isFalse);
    final image = tester.getRect(find.byType(Image));
    await tester.tapAt(
      image.topLeft + Offset(image.width * .31, image.height * .47),
    );
    await tester.pump();
    final pin = tester.widget<FloorCanvas>(find.byType(FloorCanvas)).pin!;
    expect(pin.dx, closeTo(graph.imageSize.width * .31, .01));
    expect(pin.dy, closeTo(graph.imageSize.height * .47, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Community shows existing local Floor 1 points offline and preserves original tools',
    (tester) async {
      final map = scan()..floor.floorNumber = 1;
      await MapStore().save([map]);
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString(MapStore.key);
      final client = CaptureClient()..offline = true;
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CaptureHome(
            floors: {1: graph},
            captures: SharedCaptures(connect: () async => client),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 points saved on this phone'), findsOneWidget);
      expect(
        find.textContaining('No saved or compatible shared points'),
        findsNothing,
      );
      expect(prefs.getString(MapStore.key), before);
      await tester.tap(find.text('Manage maps on this phone'));
      await tester.pumpAndSettle();
      expect(find.byType(MapsScreen), findsOneWidget);
      expect(find.text(map.name), findsOneWidget);
      expect(find.text('2 anchors'), findsOneWidget);
      expect(prefs.getString(MapStore.key), before);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'removing calibration point chooses a valid remaining pair in the same frame',
    () {
      final map = AnchorMap('scan', 'Scan', [
        for (var i = 0; i < 3; i++)
          SavedAnchor(
            '$i',
            '$i',
            'cloud-$i',
            Matrix4.translationValues(i * 3, 0, 0),
            DateTime.utc(2030),
          ),
      ])..floor.enabled = true;
      map.floor.calibrationIds.addAll(['0', '1']);
      map.floor.anchorPoints.addAll({
        for (var i = 0; i < 3; i++) '$i': Offset(100 + i * 60, 100),
      });
      map.anchors.removeAt(0);
      map.floor.anchorPoints.remove('0');
      expect(repairCaptureCalibration(map), isTrue);
      expect(map.floor.calibrationIds, ['1', '2']);
      expect(map.floor.calibration(map)!.scale, 20);
      map.anchors.removeAt(0);
      expect(repairCaptureCalibration(map), isFalse);
    },
  );

  test(
    'named origin starts exactly at its node, including identical endpoints',
    () {
      final place = graph.locations.firstWhere((p) => p.node != null);
      final route = planBuildingRoute(
        floors: {1: graph},
        connectors: [],
        startFloor: 1,
        start: graph.nodes[place.node]!.point,
        startNode: place.node,
        destination: place,
      );
      expect(route, isNotNull);
      expect(route!.meters, 0);
      expect(route.legs.single.points, [graph.nodes[place.node]!.point]);
    },
  );

  testWidgets(
    'current location is default and named start shows directions without localization',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(null);
      addTearDown(state.dispose);
      var localized = false;
      final end = graph.locations.firstWhere((p) => p.node != null);
      await tester.pumpWidget(
        MaterialApp(
          home: RoutePlannerScreen(
            floors: {1: graph},
            connectors: [],
            state: state,
            destination: end,
            onLocalize: (_, _) => localized = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Current location'), findsOneWidget);
      expect(
        find.textContaining('requires visual localization'),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);
      await tester.tap(find.text('Localize and navigate'));
      expect(localized, isTrue);
      localized = false;
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), end.label);
      await tester.pumpAndSettle();
      await tester.tap(find.text(end.label).last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Follow these steps manually'),
        findsOneWidget,
      );
      expect(find.byTooltip('Previous step'), findsOneWidget);
      expect(find.byTooltip('Next step'), findsOneWidget);
      expect(find.byKey(const ValueKey('manual-step-0')), findsOneWidget);
      expect(localized, isFalse);
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('previous-step')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('next-step')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('manual-step-0')))
            .selected,
        isTrue,
      );
      await tester.ensureVisible(find.text('Start'));
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      final other = graph.locations.firstWhere(
        (p) => p.node != null && p.node != end.node,
      );
      await tester.enterText(find.byType(TextField), other.label);
      await tester.pumpAndSettle();
      await tester.tap(find.text(other.label).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('next-step')));
      final initialMap = tester.widget<FloorCanvas>(find.byType(FloorCanvas));
      expect(initialMap.routePosition, initialMap.fullRoute.first);
      expect(initialMap.route, initialMap.fullRoute);
      expect(initialMap.showDestinationMarker, isFalse);
      await tester.tap(find.byKey(const ValueKey('next-step')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('manual-step-1')))
            .selected,
        isTrue,
      );
      final advancedMap = tester.widget<FloorCanvas>(find.byType(FloorCanvas));
      expect(advancedMap.routePosition, advancedMap.route.first);
      expect(advancedMap.route.length, lessThan(advancedMap.fullRoute.length));
      expect(advancedMap.routePosition, isNot(initialMap.routePosition));
      await tester.tap(find.byKey(const ValueKey('previous-step')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('manual-step-0')))
            .selected,
        isTrue,
      );
      final restoredMap = tester.widget<FloorCanvas>(find.byType(FloorCanvas));
      expect(restoredMap.routePosition, initialMap.routePosition);
      expect(restoredMap.route, initialMap.fullRoute);
      await tester.scrollUntilVisible(find.text('Use current location'), -400);
      await tester.tap(find.text('Use current location'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('Localize and navigate'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
