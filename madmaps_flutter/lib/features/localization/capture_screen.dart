import 'dart:async';
import '../../client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import '../navigation/floor_data.dart';
import '../navigation/floor_screen.dart';
import '../navigation/map_repository.dart';
import 'ar_adapter.dart';
import 'cloud_anchor_config.dart';
import 'map_data.dart';
import 'scan_guidance.dart';
import 'shared_captures.dart';

class CaptureHome extends StatefulWidget {
  const CaptureHome({super.key, this.floors});
  final Map<int, FloorGraph>? floors;
  @override
  State<CaptureHome> createState() => _CaptureHomeState();
}

class _CaptureHomeState extends State<CaptureHome> {
  Map<int, FloorGraph>? floors;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (reconnectClient()) unawaited(load(refresh: true));
  }

  Future<void> load({bool refresh = false}) async {
    try {
      final value = !refresh && widget.floors != null
          ? widget.floors!
          : await ServerMapRepository().loadFloors();
      if (mounted)
        setState(() {
          floors = value;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> retry() async {
    try {
      await SharedCaptures().retryPending();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pending scans uploaded')));
    } catch (e) {
      if (mounted) setState(() => error = 'Upload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Map with AR'),
      actions: [
        IconButton(
          onPressed: retry,
          tooltip: 'Retry pending uploads',
          icon: const Icon(Icons.cloud_upload_outlined),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Choose a floor. Match two physical points to the existing plan and scan around each point. Captures are shared immediately with other visitors.',
        ),
        const SizedBox(height: 12),
        if (error != null) Text(error!),
        if (floors == null)
          TextButton(onPressed: load, child: const Text('Load floor plans')),
        for (final graph in floors?.values ?? <FloorGraph>[])
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(graph.floorLabel),
            subtitle: const Text('Two-point AR capture'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => GuidedCaptureScreen(graph: graph),
              ),
            ),
          ),
      ],
    ),
  );
}

class GuidedCaptureScreen extends StatefulWidget {
  const GuidedCaptureScreen({super.key, required this.graph, this.adapter});
  final FloorGraph graph;
  final ArAdapter? adapter;
  @override
  State<GuidedCaptureScreen> createState() => _GuidedCaptureScreenState();
}

class _GuidedCaptureScreenState extends State<GuidedCaptureScreen>
    with WidgetsBindingObserver {
  final backendUrl = serverUrl;
  late final ArAdapter ar = widget.adapter ?? ArAdapter();
  late final map =
      AnchorMap(
          'capture-${DateTime.now().microsecondsSinceEpoch}',
          '${widget.graph.floorLabel} scan',
          [],
        )
        ..floor.enabled = true
        ..floor.floorNumber = widget.graph.floor;
  final scan = ScanGuidance();
  final native = <ARPlaneAnchor>[];
  Offset? point;
  ARPlaneAnchor? draft;
  bool cameraMode = false,
      busy = false,
      ready = false,
      interrupted = false,
      complete = false;
  String? error;
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ar.addListener(changed);
    ar.onTap = (hits) async {
      if (!cameraMode ||
          busy ||
          !ar.tracking ||
          draft != null ||
          interrupted ||
          complete)
        return;
      final planes = hits.where((h) => h.type == ARHitTestResultType.plane);
      if (planes.isEmpty) return;
      setState(() => busy = true);
      try {
        final value = await ar.createDraft(planes.first.worldTransform);
        if (!mounted || interrupted) {
          await ar.release(value);
          return;
        }
        setState(() {
          draft = value;
          scan.reset(value.transformation.getTranslation());
        });
      } catch (e) {
        if (mounted) setState(() => error = '$e');
      } finally {
        if (mounted) setState(() => busy = false);
      }
    };
  }

  void changed() {
    if (!mounted) return;
    if (draft != null && ar.camera != null && ar.tracking)
      scan.sample(ar.camera!.getTranslation());
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !complete) {
      interrupted = true;
      unawaited(ar.cancelOperations());
      if (mounted)
        setState(
          () => error =
              'Capture interrupted. Restart so both points use the same AR coordinate frame.',
        );
    }
  }

  Future<void> host() async {
    if (draft == null || point == null || busy || !ar.tracking || interrupted)
      return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final anchor = await ar.host(draft!.transformation, existing: draft);
      if (!mounted || interrupted) {
        await ar.release(anchor);
        return;
      }
      final frame = await ar.captureFrame([
        ...native.map((a) => a.name),
        anchor.name,
      ]);
      if (frame == null ||
          !frame.tracking ||
          [
            ...native,
            anchor,
          ].any((a) => frame.anchors[a.name]?.tracking != true)) {
        await ar.release(anchor);
        draft = null;
        throw StateError(
          'Both points must still be tracked. Move closer and retry.',
        );
      }
      for (var i = 0; i < native.length; i++) {
        final previous = map.anchors[i];
        map.anchors[i] = SavedAnchor(
          previous.id,
          previous.name,
          previous.cloudId,
          frame.anchors[native[i].name]!.pose,
          previous.expiresAt,
        );
      }
      map.scanCoverage.add(scan.progress);
      native.add(anchor);
      map.anchors.add(
        SavedAnchor(
          anchor.name,
          'Point ${native.length}',
          anchor.cloudanchorid!,
          frame.anchors[anchor.name]!.pose,
          DateTime.now().add(cloudAnchorLifetime),
        ),
      );
      map.floor.anchorPoints[anchor.name] = point!;
      draft = null;
      if (native.length == 2) {
        map.floor.calibrationIds.addAll(map.anchors.map((a) => a.id));
        final calibration = map.floor.calibration(map);
        if (calibration == null ||
            calibration.scale < 1 ||
            calibration.scale > 200) {
          interrupted = true;
          throw StateError(
            'Points must be at least 2 meters apart with distinct matching map positions. Restart capture.',
          );
        }
        complete = true;
        final store = MapStore();
        final local = await store.load();
        local.add(map);
        await store.save(local);
        if (mounted) setState(() {});
      } else {
        if (mounted)
          setState(() {
            cameraMode = false;
            point = null;
          });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> publish() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (backendUrl != serverUrl)
        throw StateError(
          'Server changed during capture. Reopen the floor plan before starting a new shared scan.',
        );
      await SharedCaptures().publish(map, widget.graph);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan shared with visitors')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        setState(
          () => error =
              'Saved on this phone. Upload failed; retry here or from Map with AR: $e',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${widget.graph.floorLabel} - Point ${native.length < 2 ? native.length + 1 : 2} of 2',
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            complete
                ? 'Calibration ready. Scale: ${map.floor.calibration(map)!.scale.toStringAsFixed(1)} pixels/meter. Check the two positions before sharing.'
                : cameraMode
                ? 'At your selected map point, tap that point on a visible floor surface, then move around it and scan.'
                : 'Tap the plan at a recognizable physical point${native.isEmpty ? '.' : ', at least 2 meters from the first point.'}',
          ),
        ),
        if (error != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
        Expanded(
          child: Stack(
            children: [
              // Keep the same native session alive while selecting the second point.
              if (supported && ready || supported && cameraMode)
                Positioned.fill(
                  child: ARView(
                    planeDetectionConfig:
                        PlaneDetectionConfig.horizontalAndVertical,
                    onARViewCreated: (s, o, a, l) async {
                      try {
                        await ar.attach(s, a);
                        if (mounted) setState(() => ready = true);
                      } catch (e) {
                        if (mounted) setState(() => error = '$e');
                      }
                    },
                  ),
                ),
              if (!cameraMode || complete)
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: FloorCanvas(
                      graph: widget.graph,
                      setup: map.floor,
                      showGraph: false,
                      onPoint: busy || complete || interrupted
                          ? null
                          : (p) => setState(() => point = p),
                      camera: point,
                    ),
                  ),
                ),
              if (cameraMode && !supported)
                const Center(
                  child: Text(
                    'AR capture requires an ARCore-compatible Android phone.',
                  ),
                ),
            ],
          ),
        ),
        if (draft != null && !complete)
          ScanPanel(
            scan: scan,
            tracking: ar.tracking,
            busy: busy,
            onSave: busy || interrupted ? null : host,
            onCancel: busy
                ? null
                : () {
                    final value = draft;
                    setState(() => draft = null);
                    if (value != null) unawaited(ar.release(value));
                  },
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: interrupted
                ? FilledButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              GuidedCaptureScreen(graph: widget.graph),
                        ),
                      );
                    },
                    child: const Text('Restart capture'),
                  )
                : complete
                ? FilledButton.icon(
                    onPressed: busy ? null : publish,
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(busy ? 'Uploading...' : 'Share scan'),
                  )
                : !cameraMode
                ? FilledButton(
                    onPressed: point == null || busy || !supported
                        ? null
                        : () => setState(() => cameraMode = true),
                    child: const Text('Scan this point'),
                  )
                : Text(ar.cloudStage ?? ar.status),
          ),
        ),
      ],
    ),
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ar.removeListener(changed);
    ar.dispose();
    super.dispose();
  }
}
