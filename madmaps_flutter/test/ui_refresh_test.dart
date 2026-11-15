import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:madmaps/main.dart';
import 'package:madmaps/features/shell/app_state.dart';
import 'package:madmaps/features/navigation/map_repository.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/interactive_floor_map.dart';
import 'map_repository_test.dart' show fixture;

class ExploreRepository implements MultiFloorMapRepository {
  final floors = {
    for (final f in [1, 0, 2, 3]) f: adaptSnapshot(fixture(f), floorNumber: f),
  };
  bool offline = false;
  final calls = <String>[];
  @override
  Future<FloorGraph> load() async => floors[1]!;
  @override
  Future<Map<int, FloorGraph>> loadFloors() async => floors;
  @override
  List<String> get categories => ['bathroom', 'studySpace', 'exit', 'elevator'];
  @override
  String? categoryOf(String id) {
    for (final f in [1, 0, 2, 3]) {
      for (final place in fixture(f).locations) {
        if (place.locationId == id) return place.category?.name;
      }
    }
    return null;
  }

  @override
  Future<List<String>> search(String query, {String? category}) async {
    calls.add('$query:$category');
    if (offline) throw StateError('offline');
    return floors.values
        .expand((f) => f.locations)
        .where(
          (p) =>
              p.label.toLowerCase().contains(query.toLowerCase()) &&
              (category == null || categoryOf(p.id) == category),
        )
        .map((p) => p.id)
        .toList();
  }
}

Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('UI_SCREENSHOTS')) return;
  final context = key.currentContext!;
  final images = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toList();
  await tester.runAsync(() async {
    for (final image in images) {
      await precacheImage(image, context);
    }
  });
  await tester.pumpAndSettle();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final dir = Directory('build/ui-refresh')..createSync(recursive: true);
    await File(
      '${dir.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
          (_) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });
  testWidgets(
    'Explore filters combine with search and retain state across tabs',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      for (final family in ['RedHatDisplay', 'RedHatText']) {
        final loader = FontLoader(family)
          ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
        await loader.load();
      }
      final repo = ExploreRepository();
      await tester.runAsync(() async {
        for (final floor in repo.floors.keys.toList()) {
          repo.floors[floor] = await repo.floors[floor]!.loadRooms();
        }
      });
      final state = AppState(await SharedPreferences.getInstance());
      final afterKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: afterKey,
          child: MyApp(state: state, repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MadMaps'), findsOneWidget);
      expect(find.textContaining('UW'), findsNothing);
      expect(find.text('Plan a route'), findsNothing);
      expect(find.text('Your next stop, a little closer.'), findsNothing);
      expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .items!
            .map((item) => item.value),
        [0, 1, 2, 3],
      );
      for (final floor in [0, 2, 3, 1]) {
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .onChanged!(floor);
        await tester.pumpAndSettle();
        final dynamic mapState = tester.state(find.byType(InteractiveFloorMap));
        final size = tester.getSize(find.byType(InteractiveFloorMap));
        for (final sourcePoint in [
          ...repo.floors[floor]!.nodes.values.map((node) => node.point),
          ...repo.floors[floor]!.rooms.expand((room) => room.points),
        ]) {
          final point = MatrixUtils.transformPoint(
            mapState.matrix,
            sourcePoint,
          );
          expect(point.dx, inInclusiveRange(0, size.width));
          expect(point.dy, inInclusiveRange(0, size.height));
        }
      }
      expect(find.text('Home'), findsNothing);
      expect(find.text('Map'), findsNothing);
      await tester.runAsync(() async {
        await precacheImage(
          AssetImage(repo.floors[1]!.imageAsset),
          tester.element(find.byType(TextField)),
        );
      });
      await tester.pumpAndSettle();
      await screenshot(tester, afterKey, 'after-explore');
      await tester.tap(find.text('Study spaces'));
      await tester.pumpAndSettle();
      expect(repo.calls.last, ':studySpace');
      await tester.enterText(find.byType(TextField), 'room');
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'room:studySpace');
      await tester.tap(find.text('Study spaces'));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'room:null');
      final result = find.textContaining('Room ').first;
      expect(
        tester.getTopLeft(result).dy,
        greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
      );
      await screenshot(tester, afterKey, 'search-dropdown');
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await screenshot(tester, afterKey, 'after-profile');
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'room',
      );
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Morgridge Hall'), findsNothing);
      expect(find.text('Around the building'), findsNothing);
      await tester.tap(find.byTooltip('Expand explore'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DraggableScrollableSheet>(
              find.byType(DraggableScrollableSheet),
            )
            .controller!
            .size,
        greaterThan(.22),
      );
      await screenshot(tester, afterKey, 'after-expanded');
      await tester.tap(find.byTooltip('Collapse explore'));
      await tester.pumpAndSettle();
      await screenshot(tester, afterKey, 'after-explore');
      final upstairs = repo.floors[2]!.locations.firstWhere(
        (p) => p.node != null,
      );
      await tester.enterText(find.byType(TextField), upstairs.label);
      await tester.pumpAndSettle();
      await tester.tap(find.text(upstairs.label).last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveFloorMap>(find.byType(InteractiveFloorMap))
            .graph
            .floor,
        2,
      );
      expect(find.text('Navigate'), findsOneWidget);
      final mapOwner = tester.state(find.byType(InteractiveFloorMap));
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(InteractiveFloorMap)), same(mapOwner));
      expect(find.text('Your location'), findsOneWidget);
      expect(find.text('Walking directions'), findsOneWidget);
      await screenshot(tester, afterKey, 'inline-directions');
      await tester.tap(find.text('Your location'));
      await tester.pumpAndSettle();
      final origin = repo.floors[2]!.locations.firstWhere(
        (p) => p.node != null && p.node != upstairs.node,
      );
      await tester.enterText(find.byType(TextField), origin.label);
      await tester.pumpAndSettle();
      await tester.tap(find.text(origin.label).last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveFloorMap>(find.byType(InteractiveFloorMap))
            .fullRoute,
        isNotEmpty,
      );
      await screenshot(tester, afterKey, 'inline-route-preview');
      await tester.ensureVisible(find.text('Start step-by-step'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start step-by-step'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('manual-instruction')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('inline-previous-step')),
            )
            .onPressed,
        isNull,
      );
      final initialPosition = tester
          .widget<InteractiveFloorMap>(find.byType(InteractiveFloorMap))
          .position;
      expect(initialPosition, isNotNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('inline-next-step')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('inline-next-step')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveFloorMap>(find.byType(InteractiveFloorMap))
            .position,
        isNot(initialPosition),
      );
      await tester.tap(find.byKey(const ValueKey('inline-previous-step')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveFloorMap>(find.byType(InteractiveFloorMap))
            .position,
        initialPosition,
      );
      await screenshot(tester, afterKey, 'manual-step-navigation');
      var advances = 0;
      while (tester
              .widget<IconButton>(
                find.byKey(const ValueKey('inline-next-step')),
              )
              .onPressed !=
          null) {
        expect(advances++, lessThan(100));
        await tester.ensureVisible(
          find.byKey(const ValueKey('inline-next-step')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('inline-next-step')));
        await tester.pumpAndSettle();
      }
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('manual-instruction')))
            .data,
        startsWith('Reach the entrance'),
      );
      expect(state.recent, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DraggableScrollableSheet>(
              find.byType(DraggableScrollableSheet),
            )
            .controller!
            .size,
        closeTo(.22, .01),
      );
      await tester.tap(find.text('Contribute'));
      await tester.pumpAndSettle();
      await screenshot(tester, afterKey, 'after-contribute');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('compact Explore supports large text and an open keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final state = AppState(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MyApp(state: state, repository: ExploreRepository()),
    );
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
