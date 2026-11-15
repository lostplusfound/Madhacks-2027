import 'dart:async';
import 'cloud_anchor_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart';

class AnchorSample {
  AnchorSample(this.pose, this.tracking);
  final Matrix4 pose;
  final bool tracking;
}

class ArFrame {
  ArFrame(this.timestamp, this.camera, this.tracking, this.anchors);
  final int timestamp;
  final Matrix4 camera;
  final bool tracking;
  final Map<String, AnchorSample> anchors;
}

/// Owns plugin callbacks and serializes cloud operations. Late results are ignored.
class ArAdapter extends ChangeNotifier {
  ArAdapter({
    this.cloudTimeout = const Duration(seconds: 90),
    Future<bool> Function()? cloudConfigured,
  }) : _cloudConfigured = cloudConfigured ?? _hasKeylessCloudConfig;
  final Future<bool> Function() _cloudConfigured;
  static Future<bool> _hasKeylessCloudConfig() async =>
      await const MethodChannel(
        'madmaps/ar_config',
      ).invokeMethod<bool>('hasKeylessCloudAnchorConfig') ==
      true;
  Future<void> _checkCloudConfig() async {
    if (!await _cloudConfigured()) {
      throw StateError(
        'ARCore keyless authorization requires an app rebuild without an API key. Follow docs/AR_PROTOTYPE.md and register the signing SHA-1 in Google Cloud.',
      );
    }
  }

  final Duration cloudTimeout;
  String? cloudStage;
  void _stage(String message) {
    cloudStage = message;
    debugPrint('[MadMaps AR] $message');
    if (!_closed) notifyListeners();
  }

  Future<T> _step<T>(
    String label,
    Future<T> Function() action,
    Duration timeout,
  ) async {
    _stage(label);
    return action().timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(
          '$label did not complete. Reopen the map and retry.',
          timeout,
        );
      },
    );
  }

  ARSessionManager? session;
  ARAnchorManager? anchors;
  Matrix4? camera;
  bool tracking = false;
  bool _closed = false;
  bool _polling = false;
  Timer? _timer;
  String status = 'Starting camera…';
  Completer<ARAnchor>? _host;
  String? _hostName;
  final Map<String, Completer<ARAnchor>> _requests = {};
  final Map<String, String> _requestCloudIds = {};
  Completer<ARAnchor>? _search;
  int _requestSequence = 0;
  int _discoveryEpoch = 0;
  bool get searching => _search != null;

  Future<void> cancelDiscovery() async {
    _discoveryEpoch++;
    final pending = _search;
    _search = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(StateError('Localization cancelled'));
    }
    final ids = _requests.keys.toList();
    _requests.clear();
    _requestCloudIds.clear();
    await _cancelRequests(ids);
  }

  Future<void> cancelOperations() async {
    final name = _hostName;
    final host = _host;
    if (host != null && !host.isCompleted) {
      host.completeError(StateError('AR session interrupted'));
    }
    await cancelDiscovery();
    if (name != null) await _cancelRequests([name]);
  }

  Future<void> _cancelRequests(List<String> ids) async {
    await Future.wait(
      ids.map((id) async {
        try {
          await anchors!.cancelResolve(id).timeout(const Duration(seconds: 3));
        } catch (error) {
          // Disposal can close the platform view before its cleanup reply arrives.
          debugPrint('[MadMaps AR] Resolve cleanup failed: $error');
        }
      }),
    );
  }

  /// Resolves a small candidate catalog; native names uniquely identify attempts.
  Future<ARAnchor> resolveAny(
    List<String> ids, {
    bool retain = false,
    Duration? timeout,
  }) async {
    _checkReady();
    final epoch = _discoveryEpoch;
    await _checkCloudConfig().timeout(const Duration(seconds: 5));
    if (epoch != _discoveryEpoch || _closed) {
      throw StateError('Localization cancelled');
    }
    _checkReady();
    final cloudIds = ids.toSet().toList();
    if (cloudIds.isEmpty || cloudIds.length > 20) {
      throw StateError('Choose between 1 and 20 live anchors.');
    }
    final result = Completer<ARAnchor>();
    result.future.ignore();
    _search = result;
    final failures = <String>[];
    final requests = <String>[];
    for (var i = 0; i < cloudIds.length; i++) {
      final name =
          'resolve_${DateTime.now().microsecondsSinceEpoch}_${_requestSequence++}';
      final request = Completer<ARAnchor>();
      _requests[name] = request;
      _requestCloudIds[name] = cloudIds[i];
      requests.add(name);
      request.future.then(
        (anchor) {
          if (identical(_search, result) && !result.isCompleted && tracking) {
            result.complete(anchor);
          }
        },
        onError: (Object error) {
          failures.add('$error');
          if (!result.isCompleted &&
              identical(_search, result) &&
              (failures.length == cloudIds.length ||
                  '$error'.contains('NOT_AUTHORIZED') ||
                  '$error'.contains('RESOURCE_EXHAUSTED'))) {
            result.completeError(StateError(failures.last));
          }
        },
      );
    }
    ARAnchor? winner;
    try {
      for (var i = 0; i < requests.length; i++) {
        final name = requests[i];
        final id = cloudIds[i];
        // Start independently: one failed acknowledgement must not block others.
        unawaited(() async {
          try {
            final accepted = await anchors!.downloadAnchor(id, requestId: name);
            if (accepted == false) {
              throw StateError('Could not start resolving anchor');
            }
          } catch (error) {
            final pending = _requests[name];
            if (pending != null && !pending.isCompleted) {
              pending.completeError(error);
            }
          }
        }());
      }
      winner = await result.future.timeout(timeout ?? cloudTimeout);
      return winner;
    } finally {
      if (identical(_search, result)) _search = null;
      _requests.removeWhere((key, value) => requests.contains(key));
      _requestCloudIds.removeWhere((key, value) => requests.contains(key));
      await _cancelRequests(
        requests.where((name) => !retain || name != winner?.name).toList(),
      );
    }
  }

  void Function(List<ARHitTestResult>)? onTap;

  Future<void> attach(ARSessionManager s, ARAnchorManager a) async {
    if (_closed) {
      await s.dispose();
      return;
    }
    session = s;
    anchors = a;
    a.onCloudAnchorError = (operation, identifier, state) {
      final request = _requests[identifier];
      if (operation == 'resolve' && request != null && !request.isCompleted) {
        request.completeError(StateError('ARCore resolve failed: $state'));
        return;
      }
      final pending = operation == 'host' ? _host : null;
      if (!_closed &&
          pending != null &&
          !pending.isCompleted &&
          identifier == _hostName) {
        pending.completeError(StateError('ARCore $operation failed: $state'));
      }
    };
    s.onPlaneOrPointTap = (hits) => onTap?.call(hits);
    s.onTrackingStateChanged = (state, reason) {
      tracking = state.toUpperCase() == 'TRACKING';
      status = tracking ? 'Tracking' : 'Tracking paused: $reason';
      if (!tracking) camera = null;
      if (!_closed) notifyListeners();
    };
    a.onAnchorUploaded = (anchor) {
      if (!_closed &&
          anchor.name == _hostName &&
          _host != null &&
          !_host!.isCompleted) {
        _host!.complete(anchor);
      }
    };
    a.onAnchorDownloaded = (json) {
      final anchor = ARAnchor.fromJson(json);
      final request = _requests[anchor.name];
      if (!_closed &&
          request != null &&
          !request.isCompleted &&
          anchor is ARPlaneAnchor &&
          anchor.cloudanchorid == _requestCloudIds[anchor.name]) {
        if (tracking) {
          request.complete(anchor);
        } else {
          request.completeError(StateError('Tracking paused; scan again'));
        }
      }
      return anchor;
    };
    await s.onInitialize(showPlanes: true, showFeaturePoints: false);
    await a.initGoogleCloudAnchorMode();
    // Cloud mode creates a fresh native Config. Restore the requested plane detection
    // using onInitialize, which reads and preserves the session's cloud config.
    await s.onInitialize(showPlanes: true, showFeaturePoints: false);
    if (_closed) {
      await s.dispose();
      return;
    }
    status = 'Move phone slowly to detect horizontal or vertical surfaces';
    notifyListeners();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (_polling || _closed) return;
      _polling = true;
      try {
        final pose = await s.getCameraPose();
        if (!_closed) {
          camera = tracking ? pose : null;
          notifyListeners();
        }
      } finally {
        _polling = false;
      }
    });
  }

  Future<ArFrame?> captureFrame(Iterable<String> names) async {
    if (_closed || session == null) return null;
    final raw = await session!
        .getLocalizationFrame(names.toList())
        .timeout(const Duration(seconds: 2));
    if (raw == null) return null;
    Matrix4 matrix(dynamic values) => Matrix4.fromList(
      (values as List).map((v) => (v as num).toDouble()).toList(),
    );
    final samples = <String, AnchorSample>{};
    final entries = Map<String, dynamic>.from(raw['anchors'] as Map);
    for (final entry in entries.entries) {
      if (entry.value == null) continue;
      final value = Map<String, dynamic>.from(entry.value as Map);
      samples[entry.key] = AnchorSample(
        matrix(value['pose']),
        value['tracking'] == 'TRACKING',
      );
    }
    return ArFrame(
      raw['timestamp'] as int,
      matrix(raw['camera']),
      raw['tracking'] == 'TRACKING',
      samples,
    );
  }

  Future<void> release(ARAnchor anchor) => _cancelRequests([anchor.name]);

  Future<ARPlaneAnchor> createDraft(Matrix4 pose) async {
    _checkReady();
    final anchor = ARPlaneAnchor(
      transformation: pose,
      name: 'draft_${DateTime.now().microsecondsSinceEpoch}',
      ttl: cloudAnchorTtlDays,
    );
    if (await anchors!.addAnchor(anchor) != true) {
      throw StateError('Could not place anchor');
    }
    return anchor;
  }

  Future<ARPlaneAnchor> host(Matrix4 pose, {ARPlaneAnchor? existing}) async {
    _checkReady();
    final epoch = _discoveryEpoch;
    await _step(
      'Checking cloud configuration',
      _checkCloudConfig,
      const Duration(seconds: 5),
    );
    _checkReady();
    if (epoch != _discoveryEpoch) throw StateError('AR session interrupted');
    final anchor =
        existing ??
        ARPlaneAnchor(
          transformation: pose,
          name: 'a${DateTime.now().microsecondsSinceEpoch}',
          ttl: cloudAnchorTtlDays,
        );
    anchor.ttl = cloudAnchorTtlDays;
    _hostName = anchor.name;
    _host = Completer<ARAnchor>();
    // A native failure may arrive before uploadAnchor's acknowledgement.
    _host!.future.ignore();
    try {
      if (existing == null &&
          await _step(
                'Placing native anchor',
                () => anchors!.addAnchor(anchor),
                cloudTimeout,
              ) !=
              true) {
        throw StateError('Could not place anchor.');
      }
      if (epoch != _discoveryEpoch) throw StateError('AR session interrupted');
      if (await _step(
            'Starting cloud hosting',
            () => anchors!.uploadAnchor(anchor),
            cloudTimeout,
          ) !=
          true) {
        throw StateError('Could not start hosting.');
      }
      final hosted =
          await _step(
                'Waiting for ARCore hosting result',
                () => _host!.future,
                cloudTimeout,
              )
              as ARPlaneAnchor;
      _stage('Cloud hosting succeeded');
      return hosted;
    } catch (_) {
      try {
        await anchors!
            .cancelCloudTask(anchor.name)
            .timeout(const Duration(seconds: 3));
      } catch (error) {
        debugPrint('[MadMaps AR] Hosting cleanup failed: $error');
      }
      if (!_closed && existing == null) anchors!.removeAnchor(anchor);
      rethrow;
    } finally {
      anchors?.pendingAnchors.removeWhere(
        (pending) => pending.name == anchor.name,
      );
      _host = null;
      _hostName = null;
    }
  }

  Future<ARAnchor> resolve(String id, {bool retain = false}) async {
    return resolveAny([id], retain: retain);
  }

  void _checkReady() {
    if (_closed || anchors == null || _host != null || _search != null) {
      throw StateError(
        'AR session unavailable or another cloud operation is running.',
      );
    }
  }

  @override
  void dispose() {
    unawaited(cancelOperations());
    _closed = true;
    _timer?.cancel();
    session?.dispose();
    super.dispose();
  }
}
