import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart'
    show MethodCall, MethodChannel, StandardMethodCodec;
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:madmaps/features/localization/ar_adapter.dart';

class FakeSession extends ARSessionManager {
  FakeSession(BuildContext context)
    : super(700, context, PlaneDetectionConfig.horizontal);
  bool closed = false;
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
  bool accept = true;
  bool completeHosting = true;
  bool removed = false;
  String? failure;
  @override
  Future<void> initGoogleCloudAnchorMode() async {}
  @override
  Future<bool?> addAnchor(ARAnchor anchor) async => accept;
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
  Future<bool?> downloadAnchor(String cloudanchorid) async => null;
}

void main() {
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
  testWidgets('missing API key fails before any native placement', (
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
          contains('API key not configured'),
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
    expect((await ar.host(Matrix4.identity())).cloudanchorid, 'hosted');
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
    anchors.onAnchorDownloaded!(
      ARPlaneAnchor(
        transformation: Matrix4.identity(),
        cloudanchorid: 'new',
      ).toJson(),
    );
    expect((await next as ARPlaneAnchor).cloudanchorid, 'new');
    ar.dispose();
  });
}
