import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:madmaps_client/madmaps_client.dart' as api;
import 'package:madmaps/features/navigation/map_repository.dart';
import 'package:madmaps/features/shell/navigation_session.dart';
import 'map_repository_test.dart' show fixture;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart'
    show MethodCall, MethodChannel, StandardMethodCodec;
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin.dart' show ARView;
import 'package:madmaps/features/localization/ar_adapter.dart';
import 'package:madmaps/features/localization/map_data.dart';
import 'package:madmaps/features/localization/prototype_screen.dart';

class FakeSession extends ARSessionManager {
  FakeSession(BuildContext context)
    : super(700, context, PlaneDetectionConfig.horizontalAndVertical);
  bool closed = false;
  int frameTimestamp = 0;
  @override
  Future<Map<String, dynamic>?> getLocalizationFrame(
    List<String> names,
  ) async => {
    'timestamp': frameTimestamp += 100000000,
    'camera': Matrix4.identity().storage.toList(),
    'tracking': 'TRACKING',
    'anchors': {
      for (final name in names)
        name: {
          'pose': Matrix4.identity().storage.toList(),
          'tracking': 'TRACKING',
        },
    },
  };
  @override
  Future<void> onInitialize({
    bool showAnimatedGuide = true,
    bool autoHideCoachingOverlay = true,
    bool showFeaturePoints = false,
    bool showPlanes = true,
    String? customPlaneTexturePath,
    bool showWorldOrigin = false,
    bool handleTaps = true,
    bool handlePans = false,
    bool handleRotation = false,
    List<String>? trackingImagePaths,
    bool continuousImageTracking = false,
    int imageTrackingUpdateIntervalMs = 100,
    double lightIntensityMultiplier = 1.0,
  }) async {}
  @override
  Future<Matrix4?> getCameraPose() async => Matrix4.identity();
  @override
  Future<void> dispose() async {
    closed = true;
  }
}

class FakeAnchors extends ARAnchorManager {
  FakeAnchors() : super(700);
  final requests = <String, String>{};
  final cancelled = <String>[];
  int placements = 0;
  bool accept = true;
  bool completeHosting = true;
  bool removed = false;
  String? failure;
  @override
  Future<void> initGoogleCloudAnchorMode() async {}
  @override
  Future<bool?> addAnchor(ARAnchor anchor) async {
    placements++;
    return accept;
  }

  @override
  Future<bool?> uploadAnchor(ARAnchor anchor) async {
    if (failure != null) {
      scheduleMicrotask(
        () => onCloudAnchorError!('host', anchor.name, failure!),
      );
      return true;
    }
    if (completeHosting) {
      (anchor as ARPlaneAnchor).cloudanchorid = 'hosted';
      scheduleMicrotask(() => onAnchorUploaded!(anchor));
    }
    return accept;
  }

  @override
  void removeAnchor(ARAnchor anchor) {
    removed = true;
  }

  @override
  Future<void> cancelCloudTask(String name) async {}

  @override
  Future<void> cancelResolve(String requestId) async {
    cancelled.add(requestId);
  }

  @override
  Future<bool?> downloadAnchor(
    String cloudanchorid, {
    String? requestId,
  }) async {
    requests[requestId!] = cloudanchorid;
    return true;
  }

  void resolveRequest(String name) => onAnchorDownloaded!(
    ARPlaneAnchor(
      name: name,
      transformation: Matrix4.identity(),
      cloudanchorid: requests[name],
    ).toJson(),
  );
}

void main() {
  for (final mode in [api.EdgeType.stairs, api.EdgeType.elevator]) {
    testWidgets(
      '${mode.name} transition confirms the destination floor before arrival, retaining the native session',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: Text('AR')));
        final native = FakeSession(tester.element(find.text('AR')));
        final anchors = FakeAnchors();
        final ar = ArAdapter(cloudConfigured: () async => true);
        await ar.attach(native, anchors);
        ar.tracking = true;
        final floors = {
          for (final f in [1, 2]) f: adaptSnapshot(fixture(f), floorNumber: f),
        };
        AnchorMap capture(int floor, String landing) {
          final point = floors[floor]!.nodes[landing]!.point;
          final map = AnchorMap('capture-$floor', 'Floor $floor', [
            SavedAnchor(
              'a-$floor',
              'A',
              'cloud-a-$floor',
              Matrix4.identity(),
              DateTime.utc(2030),
            ),
            SavedAnchor(
              'b-$floor',
              'B',
              'cloud-b-$floor',
              Matrix4.translationValues(3, 0, 0),
              DateTime.utc(2030),
            ),
          ]);
          map.floor
            ..enabled = true
            ..floorNumber = floor;
          map.floor.anchorPoints.addAll({
            'a-$floor': point,
            'b-$floor': point + const Offset(30, 0),
          });
          map.floor.calibrationIds.addAll(['a-$floor', 'b-$floor']);
          return map;
        }

        final maps = [
          capture(
            1,
            mode == api.EdgeType.stairs
                ? 'f1-south-stairs'
                : 'f1-elevator-bank-approach',
          ),
          capture(
            2,
            mode == api.EdgeType.stairs
                ? 'f2-main-stairs-landing'
                : 'f2-elevator-landing',
          ),
        ];
        final links =
            (jsonDecode(
                      File(
                        '../madmaps_server/assets/floor_connectors.json',
                      ).readAsStringSync(),
                    )
                    as List)
                .map(
                  (j) => api.FloorConnector.fromJson(j as Map<String, dynamic>),
                )
                .toList();
        final target = mode == api.EdgeType.stairs
            ? 'f2-south-stairs'
            : 'f2-elevator-bank';
        final session = NavigationSession()
          ..avoidStairs = mode == api.EdgeType.elevator
          ..choose(floors[2]!.locations.firstWhere((l) => l.id == target));
        await tester.pumpWidget(
          MaterialApp(
            home: MapSessionScreen(
              map: maps.first,
              maps: maps,
              adapter: ar,
              session: session,
              floors: floors,
              connectors: links,
              save: () async {},
            ),
          ),
        );
        await tester.pump();
        final first = anchors.requests.entries
            .firstWhere((e) => e.value == 'cloud-a-1')
            .key;
        anchors.resolveRequest(first);
        await tester.pump();
        for (var i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(session.currentFloor, 1);
        expect(
          session.instruction,
          contains(
            mode == api.EdgeType.stairs ? 'South stairs' : 'Elevator bank',
          ),
        );
        expect(session.instruction, isNot(contains('arrived')));
        final second = anchors.requests.entries
            .lastWhere((e) => e.value == 'cloud-a-2')
            .key;
        anchors.resolveRequest(second);
        await tester.pump();
        for (var i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(session.currentFloor, 2);
        expect(session.destination!.id, target);
        expect(session.instruction, contains('arrived'));
        expect(ar.session, same(native));
        expect(native.closed, isFalse);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
      },
    );
  }

  testWidgets(
    'failed discovery retries after twenty seconds and reacquires after background',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Text('AR')));
      final anchors = FakeAnchors();
      final session = FakeSession(tester.element(find.text('AR')));
      final ar = ArAdapter(cloudConfigured: () async => true);
      await ar.attach(session, anchors);
      ar.tracking = true;
      final map = AnchorMap('floor', 'Selected floor', [
        SavedAnchor('a', 'A', 'cloud', Matrix4.identity(), DateTime.utc(2030)),
      ]);
      map.floor.enabled = true;
      await tester.pumpWidget(
        MaterialApp(
          home: MapSessionScreen(map: map, adapter: ar, save: () async {}),
        ),
      );
      await tester.pump();
      expect(anchors.requests.length, 1);
      anchors.onCloudAnchorError!(
        'resolve',
        anchors.requests.keys.single,
        'ERROR_CLOUD_ID_NOT_FOUND',
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 19));
      expect(anchors.requests.length, 1);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(anchors.requests.length, 2);
      anchors.resolveRequest(anchors.requests.keys.last);
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Selected floor'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(anchors.requests.length, 3);
      anchors.resolveRequest(anchors.requests.keys.last);
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Selected floor'), findsOneWidget);
      expect(identical(ar.session, session), true);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'cancelling automatic discovery suppresses retries until Locate',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Text('AR')));
      final anchors = FakeAnchors();
      final ar = ArAdapter(cloudConfigured: () async => true);
      await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
      ar.tracking = true;
      final map = AnchorMap('floor', 'Floor', [
        SavedAnchor('a', 'A', 'cloud', Matrix4.identity(), DateTime.utc(2030)),
      ]);
      map.floor.enabled = true;
      await tester.pumpWidget(
        MaterialApp(
          home: MapSessionScreen(map: map, adapter: ar, save: () async {}),
        ),
      );
      await tester.pump();
      expect(anchors.requests.length, 1);
      await tester.tap(find.text('Cancel search').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 40));
      await tester.pump();
      expect(anchors.requests.length, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(anchors.requests.length, 1);
      await tester.tap(find.byTooltip('Find my location again'));
      await tester.pump();
      expect(anchors.requests.length, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'associated map automatically searches every batch in its own catalog',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Text('AR')));
      final anchors = FakeAnchors();
      final ar = ArAdapter(cloudConfigured: () async => true);
      final session = FakeSession(tester.element(find.text('AR')));
      await ar.attach(session, anchors);
      ar.tracking = true;
      final map = AnchorMap(
        'f1',
        'Selected map',
        List.generate(
          21,
          (i) => SavedAnchor(
            'a$i',
            'Anchor $i',
            'cloud$i',
            Matrix4.identity(),
            DateTime.utc(2030),
          ),
        ),
      );
      map.floor.enabled = true;
      await tester.pumpWidget(
        MaterialApp(
          home: MapSessionScreen(map: map, adapter: ar, save: () async {}),
        ),
      );
      await tester.pump();
      expect(anchors.requests.length, 20);
      final cameraState = tester.state(find.byType(ARView));
      expect(tester.getSize(find.byType(ARView)), const Size(140, 170));
      await tester.tap(find.byTooltip('Expand AR'));
      await tester.pump();
      expect(tester.state(find.byType(ARView)), same(cameraState));
      expect(tester.getSize(find.byType(ARView)).width, greaterThan(140));
      await tester.tap(find.byTooltip('Collapse AR'));
      await tester.pump();
      expect(tester.state(find.byType(ARView)), same(cameraState));
      expect(tester.getSize(find.byType(ARView)), const Size(140, 170));
      expect(identical(ar.session, session), true);
      expect(anchors.requests.length, 20);
      for (final name in anchors.requests.keys.toList()) {
        anchors.onCloudAnchorError!(
          'resolve',
          name,
          'ERROR_CLOUD_ID_NOT_FOUND',
        );
      }
      await tester.pump();
      expect(anchors.requests.length, 21);
      expect(anchors.requests.values.toSet(), {
        for (var i = 0; i < 21; i++) 'cloud$i',
      });
      anchors.resolveRequest(anchors.requests.keys.last);
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Selected map'), findsOneWidget);
      expect(identical(ar.session, session), true);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'native cloud failure completes immediately with the ARCore state',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Text('AR')));
      final anchors = FakeAnchors()..failure = 'ERROR_NOT_AUTHORIZED';
      final ar = ArAdapter(cloudConfigured: () async => true);
      await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
      await expectLater(
        ar.host(Matrix4.identity()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'state',
            contains('ERROR_NOT_AUTHORIZED'),
          ),
        ),
      );
      expect(anchors.removed, isTrue);
      ar.dispose();
    },
  );

  testWidgets(
    'plugin registers upload before a fast native completion callback',
    (tester) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      const channel = MethodChannel('aranchors_801');
      const codec = StandardMethodCodec();
      final manager = ARAnchorManager(801);
      ARAnchor? delivered;
      manager.onAnchorUploaded = (anchor) => delivered = anchor;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'uploadAnchor') {
          await messenger.handlePlatformMessage(
            channel.name,
            codec.encodeMethodCall(
              const MethodCall('onCloudAnchorUploaded', {
                'name': 'test',
                'cloudanchorid': 'cloud-test',
              }),
            ),
            (_) {},
          );
          return true;
        }
        return null;
      });
      final anchor = ARPlaneAnchor(
        name: 'test',
        transformation: Matrix4.identity(),
      );
      expect(await manager.uploadAnchor(anchor), isTrue);
      expect(delivered, same(anchor));
      expect(anchor.cloudanchorid, 'cloud-test');
      expect(manager.pendingAnchors, isEmpty);
      messenger.setMockMethodCallHandler(channel, null);
    },
  );
  testWidgets('API-key configuration is rejected before native placement', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Text('AR')));
    final anchors = FakeAnchors();
    final ar = ArAdapter(cloudConfigured: () async => false);
    await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
    await expectLater(
      ar.host(Matrix4.identity()),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('keyless authorization'),
        ),
      ),
    );
    expect(anchors.removed, isFalse);
    ar.dispose();
  });
  testWidgets('tracking loss clears pose and disposal closes session', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Text('AR')));
    final session = FakeSession(tester.element(find.text('AR')));
    final ar = ArAdapter(cloudConfigured: () async => true);
    await ar.attach(session, FakeAnchors());
    session.onTrackingStateChanged!('TRACKING', 'NONE');
    await tester.pump(const Duration(milliseconds: 110));
    expect(ar.camera, isNotNull);
    session.onTrackingStateChanged!('PAUSED', 'INSUFFICIENT_FEATURES');
    expect(ar.camera, isNull);
    expect(ar.tracking, isFalse);
    ar.dispose();
    expect(session.closed, isTrue);
  });
  testWidgets('hosting success and failed placement', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('AR')));
    final anchors = FakeAnchors();
    final ar = ArAdapter(cloudConfigured: () async => true);
    await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
    final hosted = await ar.host(Matrix4.identity());
    expect(hosted.cloudanchorid, 'hosted');
    expect(hosted.ttl, 365);
    // A previously created draft must also get the current hosting lifetime.
    final draft = ARPlaneAnchor(transformation: Matrix4.identity(), ttl: 1);
    expect((await ar.host(Matrix4.identity(), existing: draft)).ttl, 365);
    anchors.accept = false;
    await expectLater(ar.host(Matrix4.identity()), throwsStateError);
    expect(anchors.removed, isTrue);
    ar.dispose();
  });
  testWidgets('resolve timeout ignores unrelated or late cloud IDs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Text('AR')));
    final anchors = FakeAnchors();
    final ar = ArAdapter(
      cloudConfigured: () async => true,
      cloudTimeout: const Duration(milliseconds: 20),
    );
    await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
    final first = expectLater(
      ar.resolve('old'),
      throwsA(isA<TimeoutException>()),
    );
    await tester.pump(const Duration(milliseconds: 30));
    await first;
    ar.tracking = true;
    final next = ar.resolve('new');
    var completed = false;
    unawaited(next.then((_) => completed = true));
    anchors.onAnchorDownloaded!(
      ARPlaneAnchor(
        transformation: Matrix4.identity(),
        cloudanchorid: 'old',
      ).toJson(),
    );
    await tester.pump();
    expect(completed, isFalse);
    await tester.pump();
    anchors.onAnchorDownloaded!(
      ARPlaneAnchor(
        name: anchors.requests.keys.last,
        transformation: Matrix4.identity(),
        cloudanchorid: 'new',
      ).toJson(),
    );
    expect((await next as ARPlaneAnchor).cloudanchorid, 'new');
    ar.dispose();
  });
  testWidgets(
    'discovery accepts first success, deduplicates and cancels all tasks',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Text('AR')));
      final anchors = FakeAnchors();
      final ar = ArAdapter(cloudConfigured: () async => true);
      await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
      ar.tracking = true;
      final result = ar.resolveAny(['a', 'b', 'a']);
      await tester.pump();
      expect(anchors.requests.length, 2);
      anchors.onCloudAnchorError!(
        'resolve',
        anchors.requests.keys.first,
        'ERROR_CLOUD_ID_NOT_FOUND',
      );
      anchors.resolveRequest(anchors.requests.keys.last);
      expect((await result as ARPlaneAnchor).cloudanchorid, 'b');
      expect(anchors.cancelled.toSet(), anchors.requests.keys.toSet());
      ar.dispose();
    },
  );

  testWidgets('cancel and retry ignore previous attempt callbacks', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Text('AR')));
    final anchors = FakeAnchors();
    final ar = ArAdapter(cloudConfigured: () async => true);
    await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
    ar.tracking = true;
    final cancelled = expectLater(ar.resolveAny(['same']), throwsStateError);
    await tester.pump();
    final old = anchors.requests.keys.single;
    await ar.cancelDiscovery();
    await cancelled;
    final retry = ar.resolveAny(['same']);
    var completed = false;
    unawaited(retry.then((_) => completed = true));
    await tester.pump();
    anchors.resolveRequest(old);
    await tester.pump();
    expect(completed, false);
    anchors.resolveRequest(anchors.requests.keys.last);
    await retry;
    ar.dispose();
  });

  testWidgets('all failures and oversized catalogs terminate discovery', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Text('AR')));
    final anchors = FakeAnchors();
    final ar = ArAdapter(cloudConfigured: () async => true);
    await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
    await expectLater(
      ar.resolveAny(List.generate(21, (i) => '$i')),
      throwsStateError,
    );
    final failed = expectLater(ar.resolveAny(['a', 'b']), throwsStateError);
    await tester.pump();
    for (final name in anchors.requests.keys) {
      anchors.onCloudAnchorError!('resolve', name, 'ERROR_CLOUD_ID_NOT_FOUND');
    }
    await failed;
    expect(ar.searching, false);
    ar.dispose();
  });
  testWidgets(
    'discovery selects the matching floor without replacing AR session',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Text('AR')));
      final anchors = FakeAnchors();
      final session = FakeSession(tester.element(find.text('AR')));
      final ar = ArAdapter(cloudConfigured: () async => true);
      await ar.attach(session, anchors);
      ar.tracking = true;
      final maps = List.generate(
        2,
        (i) => AnchorMap('floor$i', 'Floor $i', [
          SavedAnchor(
            'a$i',
            'Anchor $i',
            'cloud$i',
            Matrix4.translationValues(i * 5, 2, 3),
            DateTime.utc(2030),
          ),
        ]),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MapSessionScreen(
            maps: maps,
            adapter: ar,
            save: () async {},
          ),
        ),
      );
      await tester.tap(find.byTooltip('Find my location again'));
      await tester.pump();
      expect(anchors.requests.length, 2);
      anchors.resolveRequest(anchors.requests.keys.last);
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Floor 1'), findsOneWidget);
      expect(identical(ar.session, session), true);
      expect(session.closed, false);
      await tester.pumpWidget(const SizedBox());
      expect(session.closed, true);
    },
  );

  testWidgets('backgrounding cancels discovery and ignores late matches', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Text('AR')));
    final anchors = FakeAnchors();
    final ar = ArAdapter(cloudConfigured: () async => true);
    await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
    ar.tracking = true;
    await tester.pumpWidget(
      MaterialApp(
        home: MapSessionScreen(
          maps: [
            AnchorMap('f', 'Matched floor', [
              SavedAnchor(
                'a',
                'A',
                'cloud',
                Matrix4.identity(),
                DateTime.utc(2030),
              ),
            ]),
          ],
          adapter: ar,
          save: () async {},
        ),
      ),
    );
    await tester.tap(find.byTooltip('Find my location again'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(anchors.cancelled, isNotEmpty);
    anchors.resolveRequest(anchors.requests.keys.single);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Matched floor'), findsNothing);
    expect(find.text('Find my location'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('retained resolve keeps the winner until explicitly released', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Text('AR')));
    final anchors = FakeAnchors();
    final ar = ArAdapter(cloudConfigured: () async => true);
    await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
    ar.tracking = true;
    final result = ar.resolveAny(['a', 'b'], retain: true);
    await tester.pump();
    final winner = anchors.requests.keys.first;
    anchors.resolveRequest(winner);
    final retained = await result;
    expect(anchors.cancelled, isNot(contains(winner)));
    expect(anchors.cancelled, contains(anchors.requests.keys.last));
    await ar.release(retained);
    expect(anchors.cancelled, contains(winner));
    ar.dispose();
  });

  testWidgets(
    'hosting reuses a live draft and retains it after cloud failure',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Text('AR')));
      final anchors = FakeAnchors();
      final ar = ArAdapter(cloudConfigured: () async => true);
      await ar.attach(FakeSession(tester.element(find.text('AR'))), anchors);
      final draft = await ar.createDraft(Matrix4.identity());
      anchors.failure = 'ERROR_INTERNAL';
      await expectLater(
        ar.host(Matrix4.identity(), existing: draft),
        throwsStateError,
      );
      expect(anchors.placements, 1);
      expect(anchors.removed, false);
      anchors.failure = null;
      expect(await ar.host(Matrix4.identity(), existing: draft), same(draft));
      expect(anchors.placements, 1);
      ar.dispose();
    },
  );
}
