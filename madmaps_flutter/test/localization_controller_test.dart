import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:madmaps/features/localization/ar_adapter.dart';
import 'package:madmaps/features/localization/map_data.dart';
import 'package:madmaps/features/localization/localization_controller.dart';

class WalkingAr extends ArAdapter {
  WalkingAr() {
    tracking = true;
  }
  final released = <String>[];
  final batches = <List<String>>[];
  double x = 0, correction = .5, yaw = 0;
  bool sampleTracking = true;
  int timestamp = 0;
  Object? error;
  bool unstable = false;
  void Function()? onSample;
  Completer<ARAnchor>? pending;
  Completer<ArFrame?>? blockedFrame;
  Matrix4 candidatePose() {
    final target = Matrix4.translationValues(correction, 0, 0)..rotateY(yaw);
    final pose = Matrix4.inverted(target) * Matrix4.translationValues(10, 0, 0);
    if (unstable)
      pose.setEntry(
        0,
        3,
        pose.entry(0, 3) + (timestamp % 300000000 == 0 ? 1 : -1),
      );
    return pose;
  }

  @override
  Future<ArFrame?> captureFrame(Iterable<String> names) async {
    if (blockedFrame != null) return blockedFrame!.future;
    timestamp += 150000000;
    onSample?.call();
    return ArFrame(
      timestamp,
      Matrix4.translationValues(x, 1.6, 0),
      sampleTracking,
      {
        for (final name in names)
          name: AnchorSample(
            name == 'new' ? candidatePose() : Matrix4.identity(),
            sampleTracking,
          ),
      },
    );
  }

  @override
  Future<ARAnchor> resolveAny(
    List<String> ids, {
    bool retain = false,
    Duration? timeout,
  }) async {
    batches.add(ids);
    if (error != null) throw error!;
    return pending?.future ??
        Future.value(
          ARPlaneAnchor(
            name: 'new',
            transformation: candidatePose(),
            cloudanchorid: 'b',
          ),
        );
  }

  @override
  Future<void> release(ARAnchor anchor) async {
    released.add(anchor.name);
  }

  @override
  Future<void> cancelDiscovery() async {}
}

SavedAnchor saved(String id, double x, {bool expired = false}) => SavedAnchor(
  id,
  id,
  id,
  Matrix4.translationValues(x, 0, 0),
  expired ? DateTime.utc(2000) : DateTime.utc(2030),
);

Future<LocalizationController> setup(
  WalkingAr ar, {
  DateTime Function()? now,
}) async {
  final controller = LocalizationController(ar, now: now);
  final a = saved('a', 0);
  await controller.adopt(
    AnchorMap('floor', 'Floor', [a, saved('b', 10)]),
    a,
    ARPlaneAnchor(
      name: 'old',
      transformation: Matrix4.identity(),
      cloudanchorid: 'a',
    ),
    Matrix4.identity(),
  );
  return controller;
}

void main() {
  test('timed retries do not wait for an outstanding camera sample', () async {
    var time = DateTime.utc(2026, 11, 14);
    final ar = WalkingAr()..error = StateError('offline');
    final c = await setup(ar, now: () => time);
    await c.tick();
    ar.blockedFrame = Completer<ArFrame?>();
    final pendingSample = c.tick();
    time = time.add(const Duration(seconds: 20));
    await c.tick();
    await Future<void>.delayed(Duration.zero);
    expect(ar.batches.length, 1);
    await c.tick();
    expect(ar.batches.length, 1);
    ar.blockedFrame!.complete(null);
    await pendingSample;
    expect(c.camera, isNull);
    expect(c.alignment, isNotNull);
    c.dispose();
    ar.dispose();
  });

  test(
    'tracking loss does not prevent timed refresh retries or erase alignment',
    () async {
      var time = DateTime.utc(2026, 11, 14);
      final ar = WalkingAr()..error = StateError('no match');
      final c = await setup(ar, now: () => time);
      await c.tick();
      final alignment = c.alignment!.clone();
      ar.sampleTracking = false;
      ar.tracking = false;
      for (var i = 1; i <= 2; i++) {
        time = time.add(const Duration(seconds: 20));
        await c.tick();
        await Future<void>.delayed(Duration.zero);
        expect(ar.batches.length, i);
        expect(c.camera, isNull);
        expect(c.alignment!.storage, alignment.storage);
        expect(c.status, contains('Tracking lost'));
        expect(c.reference!.id, 'a');
      }
      ar.sampleTracking = true;
      ar.tracking = true;
      ar.x = 3;
      await c.tick();
      expect(c.camera!.entry(0, 3), 3);
      expect(c.estimated, true);
      expect(c.status, contains('estimated'));
      expect(ar.batches.length, 2);
      c.dispose();
      ar.dispose();
    },
  );
  test(
    'failed cloud refresh keeps updating AR movement using the previous alignment',
    () async {
      var time = DateTime.utc(2026, 11, 14);
      final ar = WalkingAr()..error = StateError('offline');
      final c = await setup(ar, now: () => time);
      await c.tick();
      time = time.add(const Duration(seconds: 20));
      await c.tick();
      await Future<void>.delayed(Duration.zero);
      final confirmed = c.lastConfirmed;
      ar.x = 4;
      await c.tick();
      expect(c.camera!.entry(0, 3), 4);
      ar.x = 7;
      await c.tick();
      expect(c.camera!.entry(0, 3), 7);
      expect(c.lastConfirmed, confirmed);
      expect(c.estimated, true);
      expect(ar.batches.length, 1);
      c.dispose();
      ar.dispose();
    },
  );

  test(
    'alignment window rejects motion, repeated timestamps and insufficient duration',
    () {
      final window = AlignmentWindow();
      for (var i = 0; i < 5; i++) {
        expect(window.add(i * 10000000, Matrix4.identity()), isNull);
      }
      expect(window.add(40000000, Matrix4.identity()), isNull);
      expect(window.add(600000000, Matrix4.identity()), isNotNull);
      expect(window.add(700000000, Matrix4.translationValues(1, 0, 0)), isNull);
      final rotation = Matrix4.identity()..rotateY(.2);
      expect(window.add(800000000, rotation), isNull);
    },
  );

  test(
    'walk refresh starts at twenty meters and resets after each attempt',
    () async {
      var time = DateTime.utc(2026, 11, 14);
      final ar = WalkingAr()..error = StateError('not found');
      final controller = await setup(ar, now: () => time);
      await controller.tick();
      ar.x = 3;
      await controller.tick();
      expect(ar.batches, isEmpty);
      ar.x = 19.9;
      await controller.tick();
      expect(ar.batches, isEmpty);
      ar.x = 20;
      await controller.tick();
      await Future<void>.delayed(Duration.zero);
      expect(ar.batches.length, 1);
      await controller.tick();
      expect(ar.batches.length, 1);
      time = time.add(const Duration(seconds: 20));
      await controller.tick();
      await Future<void>.delayed(Duration.zero);
      expect(ar.batches.length, 2);
      controller.dispose();
      ar.dispose();
    },
  );

  test(
    'time trigger and advisory mapping recommendations use separate thresholds',
    () async {
      var time = DateTime.utc(2026, 11, 14);
      final ar = WalkingAr()..error = StateError('no match');
      final c = await setup(ar, now: () => time);
      await c.tick();
      expect(
        c.placementRecommended(Matrix4.translationValues(20, 20, 0)),
        true,
      );
      expect(
        c.placementRecommended(Matrix4.translationValues(20.1, 0, 0)),
        false,
      );
      ar.x = 20;
      await c.tick();
      await Future<void>.delayed(Duration.zero);
      expect(c.stale, false);
      expect(c.mappingRecommended, true);
      expect(
        c.placementRecommended(Matrix4.translationValues(20, 50, 0)),
        true,
      );
      ar.x = 20.1;
      await c.tick();
      expect(c.mappingRecommended, false);
      ar.x = 0;
      time = time.add(const Duration(seconds: 20));
      await c.tick();
      await Future<void>.delayed(Duration.zero);
      expect(ar.batches.length, 2);
      time = time.add(const Duration(seconds: 11));
      await c.tick();
      expect(c.stale, true);
      expect(c.camera, isNotNull);
      expect(c.mappingRecommended, false);
      expect(
        c.alignment,
        isNotNull,
        reason:
            "Advisory warnings must preserve the alignment used to continue mapping",
      );
      c.dispose();
      ar.dispose();
    },
  );

  test(
    'search broadens in batches and skips expired anchors and other floors',
    () async {
      final ar = WalkingAr();
      final c = await setup(ar);
      c.map!.anchors.addAll([
        for (var i = 0; i < 6; i++) saved('extra$i', 20 + i.toDouble()),
        saved('expired', 1, expired: true),
      ]);
      c.camera = Matrix4.identity();
      final first = c.nextBatch(),
          second = c.nextBatch(),
          third = c.nextBatch();
      expect(first.length, 3);
      expect(second.length, 3);
      expect(
        [...first, ...second, ...third].map((a) => a.id).toSet().length,
        8,
      );
      expect(third.last.id, 'a');
      expect([...first, ...second, ...third].any((a) => a.expired), false);
      c.dispose();
      ar.dispose();
    },
  );

  test(
    'stable small handoff retains winner, releases previous reference and blends',
    () async {
      var time = DateTime.utc(2026, 11, 14);
      final ar = WalkingAr();
      final c = await setup(ar, now: () => time);
      await c.tick();
      await c.refresh();
      expect(c.reference!.id, 'b');
      expect(ar.released, ['old']);
      expect(c.alignment!.entry(0, 3), 0);
      time = time.add(const Duration(milliseconds: 250));
      await c.tick();
      expect(c.alignment!.entry(0, 3), closeTo(.25, 1e-6));
      time = time.add(const Duration(milliseconds: 250));
      await c.tick();
      expect(c.alignment!.entry(0, 3), closeTo(.5, 1e-6));
      c.dispose();
      expect(ar.released, contains('new'));
      ar.dispose();
    },
  );

  for (final yaw in [0.0, 1.2]) {
    test(
      'large stable corrections are accepted and blended (yaw=$yaw)',
      () async {
        var time = DateTime.utc(2026, 11, 14);
        final ar = WalkingAr()
          ..correction = 3
          ..yaw = yaw;
        final c = await setup(ar, now: () => time);
        await c.tick();
        await c.refresh();
        expect(c.reference!.id, 'b');
        expect(c.failure, isNull);
        expect(c.alignment!.entry(0, 3), 0);
        time = time.add(const Duration(milliseconds: 250));
        await c.tick();
        expect(c.alignment!.entry(0, 3), closeTo(1.5, 1e-6));
        expect(c.camera, isNotNull);
        time = time.add(const Duration(milliseconds: 250));
        await c.tick();
        expect(c.alignment!.entry(0, 3), closeTo(3, 1e-6));
        c.dispose();
        ar.dispose();
      },
    );
  }

  test('suspension prevents cloud work and tracking loss hides pose', () async {
    final ar = WalkingAr();
    final c = await setup(ar);
    c.suspended = true;
    await c.refresh();
    expect(ar.batches, isEmpty);
    c.suspended = false;
    await c.tick();
    expect(c.camera, isNotNull);
    ar.sampleTracking = false;
    await c.tick();
    expect(c.camera, isNull);
    c.dispose();
    ar.dispose();
  });

  test(
    'authorization and quota errors keep retrying without changing the fix',
    () async {
      var time = DateTime.utc(2026, 11, 14);
      final ar = WalkingAr()..error = StateError('ERROR_NOT_AUTHORIZED');
      final c = await setup(ar, now: () => time);
      final confirmed = c.lastConfirmed;
      for (final error in [
        'ERROR_NOT_AUTHORIZED',
        'ERROR_RESOURCE_EXHAUSTED',
        'network disconnected',
      ]) {
        ar.error = StateError(error);
        time = time.add(const Duration(seconds: 20));
        await c.tick();
        await Future<void>.delayed(Duration.zero);
        expect(c.reference!.id, 'a');
        expect(c.lastConfirmed, confirmed);
        expect(c.camera, isNotNull);
        expect(c.failure, contains('Refresh failed'));
        expect(c.estimated, true);
      }
      expect(ar.batches.length, 3);
      ar.error = null;
      await c.refresh();
      expect(c.failure, isNull);
      expect(c.reference!.id, 'b');
      c.dispose();
      ar.dispose();
    },
  );

  test(
    'failed completion resets distance and time independently of fix age',
    () async {
      var time = DateTime.utc(2026, 11, 14);
      final ar = WalkingAr()..error = StateError('not found');
      final c = await setup(ar, now: () => time);
      await c.tick();
      ar.x = 20;
      await c.tick();
      await Future<void>.delayed(Duration.zero);
      expect(ar.batches.length, 1);
      expect(c.traveled, 0);
      time = time.add(const Duration(seconds: 19));
      ar.x = 39.9;
      await c.tick();
      expect(ar.batches.length, 1);
      ar.x = 40;
      await c.tick();
      await Future<void>.delayed(Duration.zero);
      expect(ar.batches.length, 2);
      expect(c.lastAttemptCompleted, time);
      await c.tick();
      expect(ar.batches.length, 2);
      c.dispose();
      ar.dispose();
    },
  );

  test(
    'only one attempt runs and movement during it is not the next interval',
    () async {
      var time = DateTime.utc(2026, 11, 14);
      final ar = WalkingAr()..pending = Completer<ARAnchor>();
      final c = await setup(ar, now: () => time);
      await c.tick();
      final attempt = c.refresh();
      await Future<void>.delayed(Duration.zero);
      time = time.add(const Duration(seconds: 60));
      ar.x = 100;
      await c.tick();
      await c.refresh();
      expect(ar.batches.length, 1);
      ar.pending!.completeError(StateError('timeout'));
      await attempt;
      await c.tick();
      expect(ar.batches.length, 1);
      expect(c.traveled, 0);
      expect(c.lastAttemptCompleted, time);
      c.dispose();
      ar.dispose();
    },
  );

  test(
    'mapping cancels pending handoff and resumes on a fresh interval',
    () async {
      var time = DateTime.utc(2026, 11, 14);
      final ar = WalkingAr()..pending = Completer<ARAnchor>();
      final c = await setup(ar, now: () => time);
      await c.tick();
      final confirmed = c.lastConfirmed;
      final attempt = c.refresh();
      await Future<void>.delayed(Duration.zero);
      c.mapping = true;
      time = time.add(const Duration(seconds: 60));
      ar.x = 60;
      await c.tick();
      await c.refresh(explicit: true);
      expect(ar.batches.length, 1);
      ar.pending!.complete(
        ARPlaneAnchor(
          name: 'late',
          transformation: Matrix4.identity(),
          cloudanchorid: 'b',
        ),
      );
      await attempt;
      expect(c.reference!.id, 'a');
      expect(c.alignment!.entry(0, 3), 0);
      expect(ar.released, contains('late'));
      expect(ar.released, isNot(contains('old')));
      expect(c.failure, isNull);
      c.mapping = false;
      ar.pending = null;
      ar.error = StateError('no match');
      await c.tick();
      expect(ar.batches.length, 1);
      expect(c.lastConfirmed, confirmed);
      time = time.add(const Duration(seconds: 20));
      await c.tick();
      await Future<void>.delayed(Duration.zero);
      expect(ar.batches.length, 2);
      c.dispose();
      ar.dispose();
    },
  );

  test(
    'unstable matches keep the old fix and the next interval still retries',
    () async {
      var time = DateTime.utc(2026, 11, 14);
      final ar = WalkingAr()..unstable = true;
      final c = await setup(ar, now: () => time);
      await c.tick();
      ar.onSample = () => time = time.add(const Duration(seconds: 2));
      await c.refresh();
      expect(c.reference!.id, 'a');
      expect(c.camera, isNotNull);
      expect(c.failure, contains('Refresh failed'));
      expect(ar.released, contains('new'));
      ar.onSample = null;
      ar.error = StateError('no match');
      time = time.add(const Duration(seconds: 20));
      await c.tick();
      await Future<void>.delayed(Duration.zero);
      expect(ar.batches.length, 2);
      c.dispose();
      ar.dispose();
    },
  );

  test(
    'entering mapping during candidate validation discards the candidate',
    () async {
      final ar = WalkingAr();
      final c = await setup(ar);
      ar.onSample = () => c.mapping = true;
      await c.refresh();
      expect(c.mapping, true);
      expect(c.reference!.id, 'a');
      expect(ar.released, contains('new'));
      expect(ar.released, isNot(contains('old')));
      expect(c.failure, isNull);
      c.dispose();
      ar.dispose();
    },
  );

  test(
    'invalidation releases a late candidate without resurrecting alignment',
    () async {
      final ar = WalkingAr()..pending = Completer<ARAnchor>();
      final c = await setup(ar);
      final refreshing = c.refresh();
      await Future<void>.delayed(Duration.zero);
      c.invalidate();
      ar.pending!.complete(
        ARPlaneAnchor(
          name: 'late',
          transformation: Matrix4.identity(),
          cloudanchorid: 'b',
        ),
      );
      await refreshing;
      expect(c.alignment, isNull);
      expect(c.nativeReference, isNull);
      expect(ar.released, containsAll(['old', 'late']));
      c.dispose();
      ar.dispose();
    },
  );
}
