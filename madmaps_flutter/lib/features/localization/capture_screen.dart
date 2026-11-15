import 'dart:async';
import 'package:madmaps_client/madmaps_client.dart' as api;
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
import 'prototype_screen.dart';
import 'scan_guidance.dart';
import 'shared_captures.dart';
import 'local_floor1_import.dart';

class CaptureHome extends StatefulWidget {
  const CaptureHome({super.key, this.floors, this.captures});
  final Map<int, FloorGraph>? floors;
  final SharedCaptures? captures;
  @override
  State<CaptureHome> createState() => _CaptureHomeState();
}

class _CaptureHomeState extends State<CaptureHome> {
  Map<int, FloorGraph>? floors;
  String? error;
  List<AnchorMap> shared = [];
  List<AnchorMap> local = [];
  bool loading = true;
  bool importing = false;
  String? importMessage;
  late final captures = widget.captures ?? SharedCaptures();
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
    if (mounted) setState(() => loading = true);
    try {
      final saved = await MapStore().load();
      final value = !refresh && widget.floors != null
          ? widget.floors!
          : await ServerMapRepository().loadFloors();
      if (mounted)
        setState(() {
          local = saved;
          floors = value;
        });
      var scans = await captures.load(value);
      String? seedError;
      if (!importing && value[1] != null) {
        importing = true;
        try {
          importMessage = await LocalFloor1Import().run(
            saved,
            value[1]!,
            captures,
          );
          if (importMessage != null) scans = await captures.load(value);
        } catch (e) {
          seedError =
              'Floor 1 import pending; your local points are preserved. Refresh Contribute to retry: $e';
        } finally {
          importing = false;
        }
      }
      if (mounted)
        setState(() {
          shared = scans;
          floors = value;
          error = seedError;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> retry() async {
    try {
      await captures.retryPending();
      await load();
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
      title: const Text('Contribute'),
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
        Text(
          'Help Badgers find their way',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage points saved on this phone and shared community scans. Existing local maps stay on this phone unless you share a compatible scan.',
        ),
        const SizedBox(height: 12),
        if (error != null) Text(error!),
        if (importMessage != null) Text(importMessage!),
        if (loading) const LinearProgressIndicator(),
        ListTile(
          leading: const Icon(Icons.phone_android),
          title: const Text('Manage maps on this phone'),
          subtitle: const Text(
            'Original AR points, calibration, and local map tools',
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MapsScreen(graph: floors?[1]),
              ),
            );
            await load();
          },
        ),
        if (floors == null)
          TextButton(onPressed: load, child: const Text('Load floor plans')),
        TextButton.icon(
          onPressed: load,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh shared points'),
        ),
        for (final graph in floors?.values ?? <FloorGraph>[]) ...[
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(graph.floorLabel),
            subtitle: Text(
              shared.any((m) => m.floor.floorNumber == graph.floor) ||
                      local.any(
                        (m) =>
                            m.floor.floorNumber == graph.floor &&
                            m.anchors.isNotEmpty,
                      )
                  ? 'Manage saved and shared AR points'
                  : loading
                  ? 'Checking saved and shared points...'
                  : 'No saved or compatible shared points - Start two-point capture',
            ),
            onTap:
                loading ||
                    shared.any((m) => m.floor.floorNumber == graph.floor) ||
                    local.any(
                      (m) =>
                          m.floor.floorNumber == graph.floor &&
                          m.anchors.isNotEmpty,
                    )
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => GuidedCaptureScreen(graph: graph),
                      ),
                    );
                    await load();
                  },
          ),
          for (final map in local.where(
            (m) =>
                m.floor.floorNumber == graph.floor &&
                m.anchors.isNotEmpty &&
                !shared.any((s) => s.id == m.id),
          ))
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text(map.name),
              subtitle: Text(
                '${map.anchors.length} points saved on this phone${map.anchors.every((a) => a.expired) ? ' - anchors expired' : ''}${map.floor.calibration(map) == null ? ' - calibration needed' : ''}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => MapSessionScreen(
                      map: map,
                      graph: graph,
                      save: () => MapStore().save(local),
                    ),
                  ),
                );
                await load();
              },
            ),
          for (final map in shared.where(
            (m) => m.floor.floorNumber == graph.floor,
          ))
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(map.name),
              subtitle: Text('${map.anchors.length} shared points'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SharedPointEditor(graph: graph, map: map),
                  ),
                );
                await load();
              },
            ),
        ],
      ],
    ),
  );
}

class SharedPointEditor extends StatefulWidget {
  const SharedPointEditor({super.key, required this.graph, required this.map});
  final FloorGraph graph;
  final AnchorMap map;
  @override
  State<SharedPointEditor> createState() => _SharedPointEditorState();
}

class _SharedPointEditorState extends State<SharedPointEditor> {
  late AnchorMap map = AnchorMap.fromJson(widget.map.toJson());
  String? expected;
  String? error;
  bool busy = true;
  bool conflict = false;
  @override
  void initState() {
    super.initState();
    unawaited(loadOriginal());
  }

  bool get canLocalize =>
      map.anchors.length >= 2 &&
      map.floor.calibration(map) != null &&
      map.anchors.any((a) => !a.expired);

  Future<void> loadOriginal() async {
    try {
      expected = await SharedCaptures().originalJson(map.id);
    } catch (e) {
      error = 'Refresh Contribute before editing: $e';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update shared points?'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> remove([SavedAnchor? anchor]) async {
    final draft = AnchorMap.fromJson(map.toJson());
    if (anchor != null) {
      draft.anchors.removeWhere((a) => a.id == anchor.id);
      draft.floor.anchorPoints.remove(anchor.id);
      draft.floor.anchorNodes.remove(anchor.id);
    }
    final deleting = anchor == null || !repairCaptureCalibration(draft);
    if (!await confirm(
      deleting
          ? 'This removes the shared scan for everyone. A usable scan needs two valid calibration points. You can create a new scan afterward.'
          : 'Remove ${anchor.name} for everyone? A valid remaining calibration pair will be kept.',
    ))
      return;
    if (!mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await SharedCaptures().edit(
        draft,
        widget.graph,
        expected!,
        delete: deleting,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        setState(() {
          conflict = e is api.MapApiException && e.code == 'captureConflict';
          error = conflict
              ? 'Someone changed this scan. Discard this pending edit and refresh Contribute before trying again.'
              : 'Edit saved for retry in Contribute. $e';
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(map.name)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'These points are shared with everyone. Adding a point requires localizing against this scan first.',
        ),
        SizedBox(
          height: 250,
          child: FloorCanvas(
            graph: widget.graph,
            setup: map.floor,
            showGraph: false,
            showLabels: false,
            anchorLabels: {
              for (final anchor in map.anchors) anchor.id: anchor.name,
            },
          ),
        ),
        if (error != null) Text(error!),
        if (conflict)
          TextButton(
            onPressed: () async {
              await SharedCaptures().discardEdit(map.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Discard edit and refresh'),
          ),
        if (!conflict)
          TextButton(
            onPressed: busy
                ? null
                : () async {
                    await SharedCaptures().discardEdit(map.id);
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Discard pending edit and refresh'),
          ),
        for (final anchor in map.anchors)
          ListTile(
            title: Text(anchor.name),
            subtitle: Text(
              map.floor.calibrationIds.contains(anchor.id)
                  ? 'Calibration point'
                  : 'Localization point',
            ),
            trailing: IconButton(
              tooltip: 'Remove point',
              icon: const Icon(Icons.delete_outline),
              onPressed: busy || expected == null || conflict
                  ? null
                  : () => remove(anchor),
            ),
          ),
        if (canLocalize)
          FilledButton.icon(
            icon: const Icon(Icons.my_location),
            label: const Text('Localize and add point'),
            onPressed:
                busy || expected == null || conflict || map.anchors.length >= 20
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => GuidedCaptureScreen(
                          graph: widget.graph,
                          existingMap: map,
                          expectedJson: expected,
                          automaticPlacement: true,
                        ),
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
          ),
        if (!canLocalize)
          const Text(
            'Automatic placement needs a calibrated scan with at least two points and an unexpired anchor.',
          ),
        FilledButton.icon(
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Add point with map pin'),
          onPressed:
              busy || expected == null || conflict || map.anchors.length >= 20
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GuidedCaptureScreen(
                        graph: widget.graph,
                        existingMap: map,
                        expectedJson: expected,
                      ),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
        ),
        if (map.anchors.length >= 20)
          const Text('This scan has the maximum of 20 points.'),
        TextButton(
          onPressed: busy || expected == null || conflict ? null : remove,
          child: const Text('Remove entire shared scan'),
        ),
      ],
    ),
  );
}

class GuidedCaptureScreen extends StatefulWidget {
  const GuidedCaptureScreen({
    super.key,
    required this.graph,
    this.adapter,
    this.existingMap,
    this.expectedJson,
    this.automaticPlacement = false,
  });
  final FloorGraph graph;
  final ArAdapter? adapter;
  final AnchorMap? existingMap;
  final String? expectedJson;
  final bool automaticPlacement;
  @override
  State<GuidedCaptureScreen> createState() => _GuidedCaptureScreenState();
}

class _GuidedCaptureScreenState extends State<GuidedCaptureScreen>
    with WidgetsBindingObserver {
  final backendUrl = serverUrl;
  late final ArAdapter ar = widget.adapter ?? ArAdapter();
  late final map = widget.existingMap != null
      ? AnchorMap.fromJson(widget.existingMap!.toJson())
      : (AnchorMap(
            'capture-${DateTime.now().microsecondsSinceEpoch}',
            '${widget.graph.floorLabel} scan',
            [],
          )
          ..floor.enabled = true
          ..floor.floorNumber = widget.graph.floor);
  ARAnchor? reference;
  SavedAnchor? savedReference;
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
    cameraMode = widget.automaticPlacement;
    ar.addListener(changed);
    ar.onTap = (hits) async {
      if (!cameraMode ||
          busy ||
          !ar.tracking ||
          draft != null ||
          interrupted ||
          complete ||
          (widget.existingMap != null && reference == null))
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

  Future<void> resolveReference() async {
    if (busy || reference != null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final candidates = map.anchors.where((a) => !a.expired).toList();
      final resolved = await ar.resolveAny(
        candidates.map((a) => a.cloudId).toList(),
        retain: true,
      );
      if (!mounted || interrupted) {
        await ar.release(resolved);
        return;
      }
      savedReference = candidates.firstWhere(
        (a) => a.cloudId == (resolved as ARPlaneAnchor).cloudanchorid,
      );
      reference = resolved;
    } catch (e) {
      if (mounted)
        setState(
          () => error =
              'Could not localize this scan. Keep a saved point in view and retry: $e',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> host() async {
    if (draft == null ||
        (!widget.automaticPlacement && point == null) ||
        busy ||
        !ar.tracking ||
        interrupted)
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
        if (reference != null) reference!.name,
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
      if (widget.existingMap != null) {
        final refSample = frame.anchors[reference?.name];
        final hostedSample = frame.anchors[anchor.name];
        if (refSample == null ||
            !refSample.tracking ||
            hostedSample == null ||
            !hostedSample.tracking) {
          await ar.release(anchor);
          draft = null;
          throw StateError(
            'Keep the saved reference and new point tracked together, then retry.',
          );
        }
        final alignment = alignMap(savedReference!.pose, refSample.pose);
        final pose = alignment * hostedSample.pose;
        late final Offset imagePoint;
        try {
          imagePoint = widget.automaticPlacement
              ? captureImagePoint(map, pose, widget.graph.imageSize)
              : point!;
        } catch (_) {
          await ar.release(anchor);
          draft = null;
          rethrow;
        }
        map.anchors.add(
          SavedAnchor(
            anchor.name,
            'Point ${map.anchors.length + 1}',
            anchor.cloudanchorid!,
            pose,
            DateTime.now().add(cloudAnchorLifetime),
          ),
        );
        map.floor.anchorPoints[anchor.name] = imagePoint;
        point = imagePoint;
        map.scanCoverage.add(scan.progress);
        draft = null;
        complete = true;
        setState(() {});
        return;
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
      if (widget.existingMap == null) {
        await SharedCaptures().publish(map, widget.graph);
      } else {
        await SharedCaptures().edit(map, widget.graph, widget.expectedJson!);
      }
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
              'Upload failed. Retry here or from Contribute. If this scan changed, return to Contribute and refresh before editing again: $e',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.existingMap != null
            ? '${widget.graph.floorLabel} - Add point'
            : '${widget.graph.floorLabel} - Point ${native.length < 2 ? native.length + 1 : 2} of 2',
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            complete
                ? widget.existingMap != null
                      ? 'New point ready. Check its position on the plan before sharing.'
                      : 'Calibration ready. Scale: ${map.floor.calibration(map)!.scale.toStringAsFixed(1)} pixels/meter. Check the two positions before sharing.'
                : cameraMode && widget.existingMap != null && reference == null
                ? 'Scan around an existing point to localize before placing the new point.'
                : cameraMode && widget.automaticPlacement
                ? 'Walk to the next spot, tap a visible floor surface, then move around it and scan.'
                : cameraMode
                ? 'At your selected map point, tap that point on a visible floor surface, then move around it and scan.'
                : 'Drop a pin anywhere on the plan where you want to scan${native.isEmpty ? '.' : ', at least 2 meters from the first point.'}',
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
                        if (mounted) {
                          setState(() => ready = true);
                          if (widget.existingMap != null)
                            await resolveReference();
                        }
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
                      showLabels: false,
                      onPoint: busy || complete || interrupted
                          ? null
                          : (p) => setState(() => point = p),
                      pin: point,
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
                          builder: (_) => GuidedCaptureScreen(
                            graph: widget.graph,
                            existingMap: widget.existingMap,
                            expectedJson: widget.expectedJson,
                            automaticPlacement: widget.automaticPlacement,
                          ),
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
                : widget.existingMap != null && reference == null
                ? FilledButton(
                    onPressed: busy || !ready ? null : resolveReference,
                    child: Text(busy ? 'Localizing...' : 'Retry localization'),
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
