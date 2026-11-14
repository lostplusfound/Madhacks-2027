import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/features/localization/map_data.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/floor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FloorGraph graph;
  setUpAll(() async {
    graph = await FloorGraph.load();
  });
  testWidgets(
    'image taps retain original coordinates under letterboxing and zoom',
    (tester) async {
      final controller = TransformationController();
      Offset? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: FloorCanvas(
                  graph: graph,
                  setup: FloorSetup(),
                  transformationController: controller,
                  onPoint: (p) => tapped = p,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final imageRect = tester.getRect(find.byType(Image));
      expect(imageRect.width, 400);
      expect(imageRect.height, closeTo(400 * 1056 / 1632, .01));
      await tester.tapAt(imageRect.center);
      expect(tapped!.dx, closeTo(816, .01));
      expect(tapped!.dy, closeTo(528, .01));
      controller.value = Matrix4.identity()..scaleByDouble(2, 2, 1, 1);
      await tester.pump();
      await tester.tapAt(imageRect.topLeft + const Offset(100, 100));
      expect(tapped!.dx, closeTo(204, .01));
      expect(tapped!.dy, closeTo(204, .01));
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('setup can associate a legacy map and saves changes', (
    tester,
  ) async {
    final map = AnchorMap('test', 'Test map', []);
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FloorSetupScreen(
          map: map,
          graph: graph,
          save: () async {
            saves++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Not calibrated.'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(map.floor.enabled, true);
    expect(saves, 1);
    expect(tester.takeException(), isNull);
  });
}
