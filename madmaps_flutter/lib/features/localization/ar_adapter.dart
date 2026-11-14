import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart';

/// Owns plugin callbacks and serializes cloud operations. Late results are ignored.
class ArAdapter extends ChangeNotifier {
  ArAdapter({
    this.cloudTimeout = const Duration(seconds: 90),
    Future<bool> Function()? cloudConfigured,
  }) : _cloudConfigured = cloudConfigured ?? _hasCloudKey;
  final Future<bool> Function() _cloudConfigured;
  static Future<bool> _hasCloudKey() async =>
      await const MethodChannel(
        'madmaps/ar_config',
      ).invokeMethod<bool>('hasCloudAnchorKey') ==
      true;
  Future<void> _checkCloudKey() async {
    if (!await _cloudConfigured()) {
      throw StateError(
        'ARCore API key not configured. Add arcore.apiKey to android/local.properties, then rebuild the app.',
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
  Completer<ARAnchor>? _resolve;
  String? _hostName;
  String? _resolveId;
  void Function(List<ARHitTestResult>)? onTap;

  Future<void> attach(ARSessionManager s, ARAnchorManager a) async {
    if (_closed) {
      await s.dispose();
      return;
    }
    session = s;
    anchors = a;
    a.onCloudAnchorError = (operation, identifier, state) {
      final pending = operation == 'host' ? _host : _resolve;
      if (!_closed &&
          pending != null &&
          !pending.isCompleted &&
          identifier == (operation == 'host' ? _hostName : _resolveId)) {
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
      if (!_closed &&
          anchor is ARPlaneAnchor &&
          anchor.cloudanchorid == _resolveId &&
          _resolve != null &&
          !_resolve!.isCompleted) {
        _resolve!.complete(anchor);
      }
      return anchor;
    };
    await s.onInitialize(showPlanes: true, showFeaturePoints: false);
    await a.initGoogleCloudAnchorMode();
    // Cloud mode creates a fresh native Config. Restore horizontal-only scanning
    // using onInitialize, which reads and preserves the session's cloud config.
    await s.onInitialize(showPlanes: true, showFeaturePoints: false);
    if (_closed) {
      await s.dispose();
      return;
    }
    status = 'Move phone slowly to detect horizontal surfaces';
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

  Future<ARPlaneAnchor> host(Matrix4 pose) async {
    _checkReady();
    await _step(
      'Checking cloud configuration',
      _checkCloudKey,
      const Duration(seconds: 5),
    );
    _checkReady();
    final anchor = ARPlaneAnchor(
      transformation: pose,
      name: 'a${DateTime.now().microsecondsSinceEpoch}',
      ttl: 1,
    );
    _hostName = anchor.name;
    _host = Completer<ARAnchor>();
    // A native failure may arrive before uploadAnchor's acknowledgement.
    _host!.future.ignore();
    try {
      if (await _step(
            'Placing native anchor',
            () => anchors!.addAnchor(anchor),
            cloudTimeout,
          ) !=
          true) {
        throw StateError('Could not place anchor.');
      }
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
      if (!_closed) anchors!.removeAnchor(anchor);
      rethrow;
    } finally {
      _host = null;
      _hostName = null;
    }
  }

  Future<ARAnchor> resolve(String id) async {
    _checkReady();
    await _checkCloudKey();
    _checkReady();
    _resolve = Completer<ARAnchor>();
    _resolve!.future.ignore();
    _resolveId = id;
    try {
      await anchors!.downloadAnchor(id);
      return await _resolve!.future.timeout(cloudTimeout);
    } finally {
      _resolve = null;
      _resolveId = null;
    }
  }

  void _checkReady() {
    if (_closed || anchors == null || _host != null || _resolve != null) {
      throw StateError(
        'AR session unavailable or another cloud operation is running.',
      );
    }
  }

  @override
  void dispose() {
    _closed = true;
    _timer?.cancel();
    session?.dispose();
    super.dispose();
  }
}
