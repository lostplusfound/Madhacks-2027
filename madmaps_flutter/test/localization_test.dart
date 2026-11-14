import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;
import 'package:madmaps/features/localization/map_data.dart';
import 'package:madmaps/main.dart';

void main() {
  test('aligns translated and rotated sessions, including height', () {
    final mapAnchor = Matrix4.translationValues(3, 2, 8)..rotateY(.8);
    final sessionFromMap = Matrix4.translationValues(-7, 4, 2)..rotateY(-1.2);
    final sessionAnchor = sessionFromMap * mapAnchor;
    final camera = Matrix4.translationValues(4, 1.7, -2)..rotateY(.2);
    final result = alignMap(mapAnchor, sessionAnchor) * sessionFromMap * camera;
    for (var i = 0; i < 16; i++) {
      expect(result.storage[i], closeTo(camera.storage[i], 1e-9));
    }
  });
  test('horizontal distance ignores camera and anchor height', () {
    expect(horizontalDistance(Vector3(0, 100, 0), Vector3(3, -100, 4)), 5);
    expect(horizontalDistance(Vector3(3, 9, 4), Vector3(3, 1, 4)), 0);
  });
  test('camera relative arrow directions and rotation', () {
    final camera = Matrix4.identity();
    expect(relativeBearing(camera, Vector3(0, 0, -3)), 0);
    expect(
      relativeBearing(camera, Vector3(3, 99, 0)),
      closeTo(math.pi / 2, 1e-9),
    );
    expect(
      relativeBearing(camera, Vector3(-3, 0, 0)),
      closeTo(-math.pi / 2, 1e-9),
    );
    camera.rotateY(-math.pi / 2);
    expect(relativeBearing(camera, Vector3(3, 0, 0)), closeTo(0, 1e-9));
  });
  test('storage preserves names, full poses, cloud IDs and expiry', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MapStore();
    expect(await store.load(), isEmpty);
    final pose = Matrix4.translationValues(1, 2, 3)..rotateY(.7);
    final expiry = DateTime.utc(2030);
    await store.save([
      AnchorMap('map', 'Hall', [
        SavedAnchor('a', 'Door', 'cloud', pose, expiry),
      ]),
    ]);
    final restored = (await store.load()).single;
    expect(restored.name, 'Hall');
    expect(restored.anchors.single.pose.storage, pose.storage);
    expect(restored.anchors.single.cloudId, 'cloud');
    expect(restored.anchors.single.expiresAt, expiry);
    expect(
      SavedAnchor(
        'e',
        'Expired',
        'c',
        Matrix4.identity(),
        DateTime.utc(2000),
      ).expired,
      isTrue,
    );
  });
  testWidgets('create map and rename from home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create map'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Test hall');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Test hall'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'New hall');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('New hall'), findsOneWidget);
  });
}
