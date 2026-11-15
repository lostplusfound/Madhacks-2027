import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/screens/lab_api.dart';
import 'package:madmaps/screens/room_amenity_map_screen.dart';

class PlacesApi implements LabApi {
  PlacesApi({this.failDetection = false});
  final bool failDetection;
  final requests = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> capabilities() async => {
    'worker_ready': true,
    'live_ready': true,
  };

  @override
  Future<String> start(Map<String, dynamic> request) async {
    requests.add(request);
    return '${requests.length - 1}';
  }

  @override
  Future<Map<String, dynamic>> getJob(String id) async {
    final request = requests[int.parse(id)];
    if (failDetection && request['mode'] == 'databricks') {
      return {'status': 'failed', 'error': 'Detection unavailable'};
    }
    final pins = request['mode'] == 'manual'
        ? <Map<String, dynamic>>[]
        : [
            {
              'id': 'place-1',
              'label': 'Room 101',
              'category': 'other',
              'x': 100,
              'y': 120,
              'source': request['mode'] == 'demo' ? 'example' : 'model',
            },
            {
              'id': 'place-2',
              'label': 'Restroom',
              'category': 'bathroom',
              'x': 300,
              'y': 120,
              'source': request['mode'] == 'demo' ? 'example' : 'model',
            },
          ];
    return {
      'status': 'completed',
      'payload': {
        'profile': 'places',
        'places': pins,
        'plan_base64': base64Encode(
          File('test/fixtures/lab_plan.png').readAsBytesSync(),
        ),
        'result': {
          'status': 'needsReview',
          'metadata': {'width': 400, 'height': 240},
          'timings_s': {'extraction': 3.2},
        },
      },
    };
  }
}

Future<void> mount(
  WidgetTester tester,
  PlacesApi api, {
  Future<void> Function(String)? onExport,
  Size size = const Size(1200, 1200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: RoomAmenityMapScreen(
        api: api,
        onExport: onExport,
        pickPlan: () async => XFile.fromData(
          File('test/fixtures/lab_plan.png').readAsBytesSync(),
          name: 'plan.png',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('upload and find only rooms and amenities', (tester) async {
    final api = PlacesApi();
    await mount(tester, api);
    await tester.tap(find.byKey(const Key('choose-place-plan')));
    await tester.pumpAndSettle();
    expect(api.requests.single['profile'], 'places');
    expect(api.requests.single['mode'], 'manual');
    expect(find.text('0 places'), findsOneWidget);
    await tester.tap(find.byKey(const Key('find-places')));
    await tester.pumpAndSettle();
    expect(api.requests.last['mode'], 'databricks');
    expect(api.requests.last.containsKey('calibration'), isFalse);
    expect(find.text('Room 101'), findsOneWidget);
    expect(find.text('Restroom'), findsWidgets);
    expect(find.text('2 places'), findsOneWidget);
    expect(find.text('Benchmark'), findsNothing);
    expect(find.text('Fine-tune'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit, drag and export image with pins', (tester) async {
    String? exported;
    await mount(
      tester,
      PlacesApi(),
      onExport: (content) async => exported = content,
    );
    await tester.tap(find.byKey(const Key('example-place-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit Room 101'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('place-label')), 'Office 101');
    await tester.tap(find.byKey(const Key('save-place')));
    await tester.pumpAndSettle();
    expect(find.text('Office 101'), findsOneWidget);
    await tester.tap(find.byKey(const Key('place-map-zoom-in')));
    await tester.pumpAndSettle();
    final transform = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    final beforeDrag = transform.value.clone();
    final drag = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('map-pin-place-1'))),
    );
    await drag.moveBy(const Offset(40, 30));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();
    expect(transform.value, beforeDrag);
    await tester.tap(find.byKey(const Key('export-place-map')));
    await tester.pumpAndSettle();
    final map = jsonDecode(exported!) as Map<String, dynamic>;
    expect(map['profile'], 'rooms-and-amenities-v1');
    expect(map['image_base64'], isNotEmpty);
    expect(map.containsKey('walls'), isFalse);
    expect(map.containsKey('doors'), isFalse);
    final pin = (map['places'] as List).first as Map;
    expect(pin['label'], 'Office 101');
    expect(pin['x'], greaterThan(100));
    expect(pin['y'], greaterThan(120));
    expect(pin['source'], 'manual');
    expect(tester.takeException(), isNull);
  });

  testWidgets('zoom buttons work and scrolling does not zoom', (tester) async {
    await mount(tester, PlacesApi());
    await tester.tap(find.byKey(const Key('example-place-plan')));
    await tester.pumpAndSettle();
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final transform = viewer.transformationController!;
    expect(transform.value.getMaxScaleOnAxis(), 1);
    await tester.tap(find.byKey(const Key('place-map-zoom-in')));
    await tester.pumpAndSettle();
    expect(transform.value.getMaxScaleOnAxis(), closeTo(1.25, .001));
    final beforeScroll = transform.value.clone();
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.byType(InteractiveViewer)),
        scrollDelta: const Offset(0, -120),
      ),
    );
    await tester.pumpAndSettle();
    expect(transform.value, beforeScroll);
    await tester.tap(find.byKey(const Key('place-map-zoom-out')));
    await tester.pumpAndSettle();
    expect(transform.value.getMaxScaleOnAxis(), closeTo(1, .001));
    await tester.tap(find.byKey(const Key('place-map-zoom-out')));
    await tester.pumpAndSettle();
    expect(transform.value, Matrix4.identity());
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual add works when detection fails', (tester) async {
    await mount(tester, PlacesApi(failDetection: true));
    await tester.tap(find.byKey(const Key('choose-place-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('find-places')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('places-error')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-map-place')));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(Image)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('place-label')), 'Room 202');
    await tester.tap(find.byKey(const Key('save-place')));
    await tester.pumpAndSettle();
    expect(find.text('Room 202'), findsOneWidget);
    expect(find.text('1 place'), findsOneWidget);
    expect(find.byKey(const Key('places-error')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map and controls fit a phone width', (tester) async {
    await mount(tester, PlacesApi(), size: const Size(390, 844));
    await tester.tap(find.byKey(const Key('example-place-plan')));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
