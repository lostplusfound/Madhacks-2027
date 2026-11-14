import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:vector_math/vector_math_64.dart';
import 'ar_adapter.dart';
import 'map_data.dart';

class LocalizationTuning {
  static const refreshMeters = 20.0;
  static const refreshAfter = Duration(seconds: 20);
  static const staleMeters = 24.0;
  static const staleAfter = Duration(seconds: 30);
  static const mappingMeters = 20.0;
  static const batchTimeout = Duration(seconds: 10);
  static const stableFor = Duration(milliseconds: 500);
  static const stableMeters = .15;
  static const stableRadians = 3 * math.pi / 180;
  static const blendFor = Duration(milliseconds: 500);
}

double headingDifference(Matrix4 a, Matrix4 b) {
  final angle = heading(a) - heading(b);
  return math.atan2(math.sin(angle), math.cos(angle)).abs();
}

/// Validates alignment, not camera motion. All samples use frame timestamps.
class AlignmentWindow {
  final List<(int, Matrix4)> _samples = [];
  Matrix4? add(int timestamp, Matrix4 alignment) {
    if (_samples.isNotEmpty && timestamp <= _samples.last.$1) return null;
    final inconsistent = _samples.any(
      (sample) =>
          horizontalDistance(
                sample.$2.getTranslation(),
                alignment.getTranslation(),
              ) >
              LocalizationTuning.stableMeters ||
          headingDifference(sample.$2, alignment) >
              LocalizationTuning.stableRadians,
    );
    if (inconsistent) _samples.clear();
    _samples.add((timestamp, alignment.clone()));
    if (_samples.length >= 5 &&
        timestamp - _samples.first.$1 >=
            LocalizationTuning.stableFor.inMicroseconds * 1000) {
      return alignment;
    }
    return null;
  }

  void clear() => _samples.clear();
}

/// Owns floor-local alignment and bounded reference handoffs. No map mutation.
class LocalizationController extends ChangeNotifier {
  LocalizationController(this.ar, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final ArAdapter ar;
  final DateTime Function() now;
  AnchorMap? map;
  SavedAnchor? reference;
  ARAnchor? nativeReference;
  Matrix4? alignment;
  Matrix4? camera;
  DateTime? lastConfirmed;
  String? failure;
  bool suspended = false, refreshing = false;
  bool _mapping = false;
  Object? _operation;
  DateTime? lastAttemptCompleted;
  bool referenceTracking = false;
  bool _closed = false, _sampling = false;
  int _epoch = 0;
  Timer? _timer;
  DateTime? _intervalStarted, _blendStarted;
  Matrix4? _blendFrom;
  Vector3? _lastPosition, _sessionPosition;
  double traveled = 0, correctionMeters = 0, correctionRadians = 0;
  int _batchOffset = 0;
  List<SavedAnchor> _cycle = [];

  bool get mapping => _mapping;
  set mapping(bool value) {
    if (_mapping == value) return;
    _mapping = value;
    if (value) {
      // Invalidates both resolving and already-resolved candidate validation.
      _epoch++;
      unawaited(ar.cancelDiscovery());
    } else {
      _resetInterval();
    }
  }

  void _resetInterval() {
    _intervalStarted = now();
    traveled = 0;
    _lastPosition = _sessionPosition?.clone();
  }

  bool get estimated => stale || failure != null;

  bool get stale =>
      lastConfirmed == null ||
      now().difference(lastConfirmed!) >= LocalizationTuning.staleAfter ||
      (camera != null &&
          reference != null &&
          horizontalDistance(
                camera!.getTranslation(),
                reference!.pose.getTranslation(),
              ) >
              LocalizationTuning.staleMeters);
  bool get mappingRecommended =>
      lastConfirmed != null &&
      now().difference(lastConfirmed!) < LocalizationTuning.staleAfter &&
      referenceTracking &&
      camera != null &&
      nativeReference != null &&
      reference != null &&
      horizontalDistance(
            camera!.getTranslation(),
            reference!.pose.getTranslation(),
          ) <=
          LocalizationTuning.mappingMeters;
  bool placementRecommended(Matrix4 sessionPose) =>
      mappingRecommended &&
      alignment != null &&
      horizontalDistance(
            (alignment! * sessionPose).getTranslation(),
            reference!.pose.getTranslation(),
          ) <=
          LocalizationTuning.mappingMeters;
  String get status =>
      '${failure ?? (stale ? "Using previous location (estimated)." : "Localized")}${refreshing ? "\nRefreshing location..." : ""}';

  void start() => _timer ??= Timer.periodic(
    const Duration(milliseconds: 100),
    (_) => unawaited(tick()),
  );

  Future<void> adopt(
    AnchorMap selectedMap,
    SavedAnchor saved,
    ARAnchor native,
    Matrix4 frameAlignment,
  ) async {
    final previous = nativeReference;
    referenceTracking = false;
    map = selectedMap;
    reference = saved;
    nativeReference = native;
    alignment = frameAlignment.clone();
    lastConfirmed = now();
    _resetInterval();
    _cycle.clear();
    _batchOffset = 0;
    failure = null;
    if (previous != null && previous.name != native.name) {
      await ar.release(previous);
    }
    if (!_closed) notifyListeners();
  }

  Matrix4? alignmentFor(ArFrame frame) {
    final sample = frame.anchors[nativeReference?.name];
    if (!frame.tracking ||
        sample == null ||
        !sample.tracking ||
        reference == null) {
      return null;
    }
    return alignMap(reference!.pose, sample.pose);
  }

  Future<void> tick() async {
    if (_closed || _sampling || nativeReference == null) return;
    _sampling = true;
    final epoch = _epoch;
    try {
      final frame = await ar.captureFrame([nativeReference!.name]);
      if (_closed || epoch != _epoch) return;
      if (frame == null || !frame.tracking || !ar.tracking) {
        camera = null;
        referenceTracking = false;
        return;
      }
      final live = alignmentFor(frame);
      referenceTracking = live != null;
      if (!suspended && !mapping && live != null) {
        alignment = _blend(live);
      }
      camera = alignment == null ? null : alignment! * frame.camera;
      _sessionPosition = frame.camera.getTranslation();
      if (camera != null && !suspended && !mapping && !refreshing) {
        // Corrections aren't walking, and travel during an attempt isn't a new interval.
        if (_lastPosition != null) {
          traveled += horizontalDistance(_sessionPosition!, _lastPosition!);
        }
        _lastPosition = _sessionPosition!.clone();
        if (map != null &&
            _intervalStarted != null &&
            (traveled >= LocalizationTuning.refreshMeters ||
                now().difference(_intervalStarted!) >=
                    LocalizationTuning.refreshAfter)) {
          unawaited(refresh());
        }
      }
    } catch (error) {
      camera = null;
      debugPrint('[MadMaps localization] tracking sample unavailable: $error');
    } finally {
      _sampling = false;
      if (!_closed) notifyListeners();
    }
  }

  Matrix4 _blend(Matrix4 target) {
    if (_blendStarted == null || _blendFrom == null) return target;
    final t =
        (now().difference(_blendStarted!).inMicroseconds /
                LocalizationTuning.blendFor.inMicroseconds)
            .clamp(0.0, 1.0);
    if (t >= 1) {
      _blendStarted = null;
      _blendFrom = null;
      return target;
    }
    final from = Quaternion.fromRotation(_blendFrom!.getRotation());
    final to = Quaternion.fromRotation(target.getRotation());
    // Normalized quaternion interpolation follows the short arc.
    if (from.x * to.x + from.y * to.y + from.z * to.z + from.w * to.w < 0) {
      to.scale(-1);
    }
    final rotation = Quaternion(
      from.x * (1 - t) + to.x * t,
      from.y * (1 - t) + to.y * t,
      from.z * (1 - t) + to.z * t,
      from.w * (1 - t) + to.w * t,
    )..normalize();
    final translation =
        _blendFrom!.getTranslation() * (1 - t) + target.getTranslation() * t;
    return Matrix4.compose(translation, rotation, Vector3.all(1));
  }

  List<SavedAnchor> nextBatch() {
    if (_cycle.isEmpty || _batchOffset >= _cycle.length) {
      final position =
          camera?.getTranslation() ?? reference!.pose.getTranslation();
      _cycle = liveAnchorCandidates([
        map!,
      ]).values.map((c) => c.anchor).toList();
      _cycle.sort((a, b) {
        if (a.id == reference!.id && b.id != reference!.id) return 1;
        if (b.id == reference!.id && a.id != reference!.id) return -1;
        return horizontalDistance(
          position,
          a.pose.getTranslation(),
        ).compareTo(horizontalDistance(position, b.pose.getTranslation()));
      });
      _batchOffset = 0;
    }
    final batch = _cycle.skip(_batchOffset).take(3).toList();
    _batchOffset += batch.length;
    return batch.where((anchor) => !anchor.expired).toList();
  }

  Future<void> refresh({bool explicit = false}) async {
    if (_closed ||
        suspended ||
        mapping ||
        refreshing ||
        map == null ||
        nativeReference == null) {
      return;
    }
    final epoch = _epoch;
    refreshing = true;
    final operation = Object();
    _operation = operation;
    ARAnchor? candidate;
    try {
      if (explicit) {
        _cycle.clear();
        _batchOffset = 0;
      }
      final batch = explicit
          ? liveAnchorCandidates([
              map!,
            ]).values.map((candidate) => candidate.anchor).take(20).toList()
          : nextBatch();
      if (batch.isEmpty) throw StateError('No unexpired anchors available');
      candidate = await ar.resolveAny(
        batch.map((a) => a.cloudId).toList(),
        retain: true,
        timeout: LocalizationTuning.batchTimeout,
      );
      if (_closed || epoch != _epoch || suspended || mapping) return;
      final saved = batch.firstWhere(
        (a) => a.cloudId == (candidate as ARPlaneAnchor).cloudanchorid,
      );
      if (saved.expired) throw StateError('Anchor expired during refresh');
      final validation = await validate(candidate, saved, epoch);
      if (validation == null ||
          _closed ||
          epoch != _epoch ||
          suspended ||
          mapping) {
        throw StateError('Anchor did not stabilize; scan its surroundings');
      }
      final (frame, proposed) = validation;
      final oldCamera = (alignmentFor(frame) ?? alignment!) * frame.camera;
      final newCamera = proposed * frame.camera;
      correctionMeters = horizontalDistance(
        oldCamera.getTranslation(),
        newCamera.getTranslation(),
      );
      correctionRadians = headingDifference(oldCamera, newCamera);
      final old = alignment!.clone();
      await adopt(map!, saved, candidate, proposed);
      candidate = null;
      if (_closed || epoch != _epoch) return;
      _blendFrom = old;
      _blendStarted = now();
      alignment = old;
      debugPrint(
        '[MadMaps localization] correction=$correctionMeters m heading=${correctionRadians * 180 / math.pi} degrees reference=${reference?.id}',
      );
    } catch (error) {
      if (!_closed && epoch == _epoch) {
        failure = 'Refresh failed. Will retry automatically.';
        debugPrint('[MadMaps localization] refresh failed: $error');
      }
    } finally {
      if (candidate != null) await ar.release(candidate);
      if (identical(_operation, operation)) {
        _operation = null;
        refreshing = false;
        lastAttemptCompleted = now();
        _resetInterval();
      }
      if (!_closed) notifyListeners();
    }
  }

  Future<(ArFrame, Matrix4)?> validate(
    ARAnchor candidate,
    SavedAnchor saved,
    int epoch,
  ) async {
    final window = AlignmentWindow();
    final deadline = now().add(LocalizationTuning.batchTimeout);
    while (!_closed &&
        epoch == _epoch &&
        !suspended &&
        !mapping &&
        now().isBefore(deadline)) {
      final frame = await ar.captureFrame([
        candidate.name,
        if (nativeReference != null) nativeReference!.name,
      ]);
      if (_closed || epoch != _epoch || suspended || mapping) return null;
      final sample = frame?.anchors[candidate.name];
      if (frame != null &&
          frame.tracking &&
          ar.tracking &&
          sample != null &&
          sample.tracking) {
        final proposed = alignMap(saved.pose, sample.pose);
        // Map and AR session must agree on gravity, including wall anchors.
        if (proposed.entry(1, 1) < math.cos(5 * math.pi / 180)) {
          window.clear();
        } else if (window.add(frame.timestamp, proposed) != null) {
          return (frame, proposed);
        }
      } else {
        window.clear();
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  void invalidate() {
    _epoch++;
    unawaited(ar.cancelDiscovery());
    final previous = nativeReference;
    _operation = null;
    _mapping = false;
    _intervalStarted = null;
    lastAttemptCompleted = null;
    traveled = 0;
    nativeReference = null;
    reference = null;
    referenceTracking = false;
    alignment = null;
    camera = null;
    lastConfirmed = null;
    _blendFrom = null;
    _blendStarted = null;
    _lastPosition = null;
    _sessionPosition = null;
    refreshing = false;
    failure = null;
    if (previous != null) unawaited(ar.release(previous));
  }

  @override
  void dispose() {
    _closed = true;
    _timer?.cancel();
    invalidate();
    super.dispose();
  }
}
