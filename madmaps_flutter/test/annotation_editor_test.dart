import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/screens/annotation_document.dart';
import 'package:madmaps/screens/annotation_editor.dart';

Map<String, dynamic> emptyPlan() => {
  'schema_version': 1,
  'width': 400,
  'height': 240,
  'coordinate_origin': 'top-left',
  'coordinate_units': 'pixels',
  'rooms': [],
  'walls': [],
  'doors': [],
  'walkable_areas': [],
};

void main() {
  group('Annotation document', () {
    test('rotation and rotated resizing round-trip through JSON and undo', () {
      final document = AnnotationDocument(emptyPlan());
      addTearDown(document.dispose);
      document.addRoom(
        const Offset(100, 80),
        const Offset(180, 120),
        category: 'bathroom',
      );
      document.rotateSelected(45);
      expect(document.selected!['category'], 'bathroom');
      expect(document.selected!['rotation_deg'], 45);
      final vertex = document.vertices(document.selection!).first;
      document.moveVertex(0, vertex + const Offset(5, 5));
      expect(document.selected!['rotation_deg'], 45);
      expect(
        (document.vertices(document.selection!).first -
                (vertex + const Offset(5, 5)))
            .distance,
        lessThan(.001),
      );
      final copy = AnnotationDocument(document.data);
      addTearDown(copy.dispose);
      copy.select(const AnnotationSelection('rooms', 'room_1'));
      expect(copy.selected!['rotation_deg'], 45);
      document.undo();
      document.select(const AnnotationSelection('rooms', 'room_1'));
      document.undo();
      document.select(const AnnotationSelection('rooms', 'room_1'));
      expect(document.selected!['rotation_deg'], 0);
    });
    test(
      'rotation rejects corners outside the image without changing the box',
      () {
        final document = AnnotationDocument(emptyPlan());
        addTearDown(document.dispose);
        document.addRoom(const Offset(1, 1), const Offset(120, 20));
        expect(() => document.rotateSelected(45), throwsFormatException);
        expect(document.selected!['rotation_deg'], 0);
      },
    );

    test('edits preserve the prediction and support undo and redo', () {
      final source = emptyPlan(), document = AnnotationDocument(source);
      addTearDown(document.dispose);
      document.addPolygon('walls', [
        const Offset(10, 10),
        const Offset(50, 10),
        const Offset(50, 50),
      ]);
      expect(source['walls'], isEmpty);
      expect((document.data['walls'] as List).length, 1);
      document.undo();
      expect(document.data['walls'], isEmpty);
      document.redo();
      expect((document.data['walls'] as List).length, 1);
      document.undo();
      document.addRoom(const Offset(50, 60), const Offset(10, 20));
      expect(document.canRedo, isFalse);
      expect(document.selected!['bbox'], [10, 20, 50, 60]);
    });
    test('invalid polygons are rejected without changing history', () {
      final document = AnnotationDocument(emptyPlan());
      addTearDown(document.dispose);
      for (final points in [
        [
          const Offset(10, 10),
          const Offset(50, 50),
          const Offset(10, 50),
          const Offset(50, 10),
        ],
        [const Offset(10, 10), const Offset(20, 20), const Offset(30, 30)],
        [const Offset(-1, 10), const Offset(50, 10), const Offset(50, 50)],
      ]) {
        expect(
          () => document.addPolygon('walls', points),
          throwsFormatException,
        );
      }
      expect(document.canUndo, isFalse);
      expect(document.data['walls'], isEmpty);
    });
    test('deleting a room removes linked doors and undo restores both', () {
      final document = AnnotationDocument(emptyPlan());
      addTearDown(document.dispose);
      document.addRoom(const Offset(10, 10), const Offset(80, 80));
      document.addDoor(const Offset(80, 40), 'room_1');
      document.select(const AnnotationSelection('rooms', 'room_1'));
      document.deleteSelected();
      expect(document.data['rooms'], isEmpty);
      expect(document.data['doors'], isEmpty);
      document.undo();
      expect((document.data['rooms'] as List).length, 1);
      expect((document.data['doors'] as List).length, 1);
    });
    test('vertices can be inserted, removed, dragged and undone', () {
      final document = AnnotationDocument(emptyPlan());
      addTearDown(document.dispose);
      document.addPolygon('walls', [
        const Offset(10, 10),
        const Offset(80, 10),
        const Offset(80, 80),
        const Offset(10, 80),
      ]);
      document.insertVertex(0);
      expect(document.vertices(document.selection!).length, 5);
      document.moveVertex(1, const Offset(40, 5));
      expect(document.vertices(document.selection!)[1], const Offset(40, 5));
      document.removeVertex(1);
      expect(document.vertices(document.selection!).length, 4);
      document.undo();
      document.select(const AnnotationSelection('walls', 'wall_1'));
      expect(document.vertices(document.selection!).length, 5);
    });
    test(
      'JSON cannot change the image frame or create invalid door references',
      () {
        final document = AnnotationDocument(emptyPlan());
        addTearDown(document.dispose);
        final changed = emptyPlan()..['width'] = 800;
        expect(() => document.replace(changed), throwsFormatException);
        expect(
          () => document.addDoor(const Offset(20, 20), 'missing'),
          throwsFormatException,
        );
        expect(document.canUndo, isFalse);
      },
    );
    test('generated IDs stay unique after importing model annotations', () {
      final source = emptyPlan();
      (source['walls'] as List).add({
        'id': 'wall_1',
        'polygon': [
          [10, 10],
          [20, 10],
          [20, 20],
        ],
        'confidence': .8,
      });
      final document = AnnotationDocument(source);
      addTearDown(document.dispose);
      document.addPolygon('walls', [
        const Offset(30, 30),
        const Offset(40, 30),
        const Offset(40, 40),
      ]);
      expect(document.selected!['id'], 'wall_2');
    });
  });

  Future<void> mount(WidgetTester tester, AnnotationDocument document) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnnotationEditor(
                document: document,
                image: File('test/fixtures/lab_plan.png').readAsBytesSync(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Offset location(WidgetTester tester, Offset pixel) {
    final box = tester.renderObject<RenderBox>(
      find.byKey(const Key('annotation-canvas')),
    );
    return box.localToGlobal(
      Offset(pixel.dx * box.size.width / 400, pixel.dy * box.size.height / 240),
    );
  }

  Future<void> click(WidgetTester tester, Offset pixel) async {
    await tester.tapAt(location(tester, pixel));
    await tester.pumpAndSettle();
  }

  testWidgets('mouse tracing closes a polygon in canonical pixels', (
    tester,
  ) async {
    final document = AnnotationDocument(emptyPlan());
    addTearDown(document.dispose);
    await mount(tester, document);
    await tester.tap(find.byKey(const Key('annotation-tool-wall')));
    await tester.pumpAndSettle();
    for (final p in [
      const Offset(20, 20),
      const Offset(80, 20),
      const Offset(80, 70),
      const Offset(20, 70),
    ]) {
      await click(tester, p);
    }
    await tester.tap(find.byKey(const Key('finish-polygon')));
    await tester.pumpAndSettle();
    final polygon = (document.data['walls'] as List).single['polygon'] as List;
    expect(polygon.length, 4);
    expect(polygon[0][0], closeTo(20, .01));
    expect(polygon[2][1], closeTo(70, .01));
    expect(tester.takeException(), isNull);
  });
  testWidgets('zoomed canvas still writes original image coordinates', (
    tester,
  ) async {
    final document = AnnotationDocument(emptyPlan());
    addTearDown(document.dispose);
    await mount(tester, document);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('annotation-tool-walkable')));
    await tester.pumpAndSettle();
    for (final p in [
      const Offset(10, 10),
      const Offset(60, 10),
      const Offset(60, 60),
    ]) {
      await click(tester, p);
    }
    await click(tester, const Offset(10, 10));
    final points =
        (document.data['walkable_areas'] as List).single['polygon'] as List;
    expect(points[1][0], closeTo(60, .01));
    expect(points[2][1], closeTo(60, .01));
    expect(tester.takeException(), isNull);
  });
  testWidgets('room box can be dragged and labeled without JSON edits', (
    tester,
  ) async {
    final document = AnnotationDocument(emptyPlan());
    addTearDown(document.dispose);
    await mount(tester, document);
    await tester.tap(find.byKey(const Key('annotation-tool-room')));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      location(tester, const Offset(50, 50)),
    );
    await gesture.moveTo(location(tester, const Offset(150, 130)));
    await gesture.up();
    await tester.pumpAndSettle();
    expect((document.data['rooms'] as List).length, 1);
    final bbox = document.selected!['bbox'] as List;
    expect(bbox[0], closeTo(50, .01));
    expect(bbox[3], closeTo(130, .01));
    await tester.ensureVisible(find.byKey(const Key('annotation-room-label')));
    await tester.enterText(
      find.byKey(const Key('annotation-room-label')),
      'Lecture hall',
    );
    await tester.ensureVisible(find.text('Apply room label'));
    await tester.tap(find.text('Apply room label'));
    await tester.pumpAndSettle();
    expect(document.selected!['label'], 'Lecture hall');
    expect(tester.takeException(), isNull);
  });
  testWidgets('select handles drag and undo restores the previous vertex', (
    tester,
  ) async {
    final document = AnnotationDocument(emptyPlan());
    addTearDown(document.dispose);
    document.addPolygon('walls', [
      const Offset(20, 20),
      const Offset(80, 20),
      const Offset(80, 80),
      const Offset(20, 80),
    ]);
    await mount(tester, document);
    final gesture = await tester.startGesture(
      location(tester, const Offset(20, 20)),
    );
    await gesture.moveTo(location(tester, const Offset(30, 30)));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(document.vertices(document.selection!).first.dx, closeTo(30, .01));
    await tester.tap(find.byKey(const Key('annotation-undo')));
    await tester.pumpAndSettle();
    document.select(const AnnotationSelection('walls', 'wall_1'));
    expect(document.vertices(document.selection!).first, const Offset(20, 20));
    expect(tester.takeException(), isNull);
  });
  testWidgets('self-intersecting drawing stays editable with a visible error', (
    tester,
  ) async {
    final document = AnnotationDocument(emptyPlan());
    addTearDown(document.dispose);
    await mount(tester, document);
    await tester.tap(find.byKey(const Key('annotation-tool-wall')));
    await tester.pumpAndSettle();
    for (final p in [
      const Offset(10, 10),
      const Offset(80, 80),
      const Offset(10, 80),
      const Offset(80, 10),
    ]) {
      await click(tester, p);
    }
    await tester.tap(find.byKey(const Key('finish-polygon')));
    await tester.pumpAndSettle();
    expect(document.data['walls'], isEmpty);
    expect(find.byKey(const Key('annotation-error')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'amenity shortcut creates a labeled elevator box and supports angle entry',
    (tester) async {
      final document = AnnotationDocument(emptyPlan());
      addTearDown(document.dispose);
      await mount(tester, document);
      await tester.tap(find.byKey(const Key('annotation-add-elevator')));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        location(tester, const Offset(100, 80)),
      );
      await gesture.moveTo(location(tester, const Offset(180, 120)));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(document.selected!['category'], 'elevator');
      expect(document.selected!['label'], startsWith('Elevator'));
      await tester.ensureVisible(find.byKey(const Key('annotation-rotation')));
      await tester.enterText(
        find.byKey(const Key('annotation-rotation')),
        '30',
      );
      await tester.ensureVisible(find.text('Apply rotation'));
      await tester.tap(find.text('Apply rotation'));
      await tester.pumpAndSettle();
      expect(document.selected!['rotation_deg'], 30);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('round mouse handle rotates a box', (tester) async {
    final document = AnnotationDocument(emptyPlan());
    addTearDown(document.dispose);
    document.addRoom(const Offset(100, 80), const Offset(180, 120));
    await mount(tester, document);
    final box = tester.renderObject<RenderBox>(
      find.byKey(const Key('annotation-canvas')),
    );
    final gap = 12 * document.width / box.size.width * 2.2;
    final start = roomRotationHandle(document.selected!, gap),
        center = roomCenter(document.selected!);
    final end = rotatePixel(start, center, 45);
    final gesture = await tester.startGesture(location(tester, start));
    await gesture.moveTo(location(tester, end));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(document.selected!['rotation_deg'], closeTo(45, .01));
    expect(tester.takeException(), isNull);
  });
}
