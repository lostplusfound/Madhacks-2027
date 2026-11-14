import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'ar_adapter.dart';
import 'map_data.dart';
import 'scan_guidance.dart';

Future<String?> askName(
  BuildContext context,
  String title, [
  String initial = '',
]) async {
  var value = initial;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextFormField(
        initialValue: initial,
        autofocus: true,
        maxLength: 60,
        onChanged: (v) => value = v,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});
  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final store = MapStore();
  List<AnchorMap>? maps;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final value = await store.load();
      if (mounted) {
        setState(() {
          maps = value;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Could not read saved maps: $e');
    }
  }

  Future<void> save() async {
    await store.save(maps!);
    if (mounted) setState(() {});
  }

  Future<void> guarded(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MadMaps • AR maps')),
    body: error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!),
                TextButton(onPressed: load, child: const Text('Retry')),
              ],
            ),
          )
        : maps == null
        ? const Center(child: CircularProgressIndicator())
        : maps!.isEmpty
        ? const Center(
            child: Text(
              'Create a map, then tap a surface\nto place your first anchor.',
              textAlign: TextAlign.center,
            ),
          )
        : ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Cloud Anchors last 24 hours. Internet is required.\nMap records stay on this phone.',
                ),
              ),
              for (final map in maps!)
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(map.name),
                  subtitle: Text('${map.anchors.length} anchors'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MapSessionScreen(map: map, save: save),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => guarded(() async {
                      if (value == 'rename') {
                        final name = await askName(
                          context,
                          'Rename map',
                          map.name,
                        );
                        if (name == null) return;
                        map.name = name;
                      } else {
                        maps!.remove(map);
                      }
                      await save();
                    }),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete local map'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
    floatingActionButton: maps == null
        ? null
        : FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Create map'),
            onPressed: () => guarded(() async {
              final name = await askName(context, 'Create map');
              if (name == null) return;
              maps!.add(
                AnchorMap(
                  DateTime.now().microsecondsSinceEpoch.toString(),
                  name,
                  [],
                ),
              );
              await save();
            }),
          ),
  );
}

class MapSessionScreen extends StatefulWidget {
  const MapSessionScreen({super.key, required this.map, required this.save});
  final AnchorMap map;
  final Future<void> Function() save;
  @override
  State<MapSessionScreen> createState() => _MapSessionScreenState();
}

class _MapSessionScreenState extends State<MapSessionScreen>
    with WidgetsBindingObserver {
  final ar = ArAdapter();
  Matrix4? mapFromSession;
  Matrix4? draftPose;
  final scan = ScanGuidance();
  SavedAnchor? destination;
  bool busy = false, placing = false, expanded = false, active = true;
  String? operation;
  int generation = 0;
  Matrix4? get camera =>
      active && ar.tracking && ar.camera != null && mapFromSession != null
      ? mapFromSession! * ar.camera!
      : null;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ar.addListener(refresh);
    ar.onTap = (hits) async {
      if (!placing || busy || !ar.tracking || !active) return;
      final planes = hits.where((h) => h.type == ARHitTestResultType.plane);
      if (planes.isEmpty) return;
      final pose = planes.first.worldTransform;
      if (pose.entry(1, 1).abs() < 0.95) return;
      setState(() {
        placing = false;
        expanded = false;
        draftPose = pose.clone();
        scan.reset(pose.getTranslation());
      });
    };
  }

  Future<void> saveDraft() async {
    final draft = draftPose;
    if (draft == null || busy || !active || !ar.tracking) return;
    final tappedGeneration = generation;
    setState(() => busy = true);
    final name = await askName(context, 'Save anchor');
    if (!mounted) return;
    if (name == null) {
      setState(() => busy = false);
      return;
    }
    await runOperation(
      'Saving anchor to cloud? Keep the area in view.',
      () async {
        if (!active || tappedGeneration != generation) {
          throw StateError('Session interrupted; localize again');
        }
        final hosted = await ar.host(draft);
        if (!mounted || !active || tappedGeneration != generation) {
          throw StateError('Session interrupted; reopen the map');
        }
        final hostedPose =
            await ar.session!
                .getPose(hosted)
                .timeout(const Duration(seconds: 3), onTimeout: () => null) ??
            hosted.transformation;
        final frame =
            mapFromSession ??
            Matrix4.translationValues(
              -hostedPose.entry(0, 3),
              -hostedPose.entry(1, 3),
              -hostedPose.entry(2, 3),
            );
        final anchor = SavedAnchor(
          hosted.name,
          name,
          hosted.cloudanchorid!,
          frame * hostedPose,
          DateTime.now().add(const Duration(hours: 24)),
        );
        widget.map.anchors.add(anchor);
        try {
          await widget.save();
        } catch (_) {
          widget.map.anchors.remove(anchor);
          rethrow;
        }
        mapFromSession = frame;
        draftPose = null;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved anchor: $name')));
        }
      },
    );
  }

  void refresh() {
    if (draftPose != null && active && ar.tracking && ar.camera != null) {
      scan.sample(ar.camera!.getTranslation());
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (!active) {
      mapFromSession = null;
      placing = false;
      draftPose = null;
      generation++;
    }
    refresh();
  }

  Future<void> runOperation(
    String message,
    Future<void> Function() action,
  ) async {
    final current = generation;
    setState(() {
      busy = true;
      operation = message;
    });
    try {
      await action();
      if (current != generation) mapFromSession = null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Operation failed: $e. Check internet, ARCore credentials, expiry and scan quality.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          operation = null;
        });
      }
    }
  }

  Future<void> resolve(SavedAnchor anchor) => runOperation(
    'Resolving ${anchor.name}: scan its surroundings…',
    () async {
      if (anchor.expired) throw StateError('Anchor expired');
      final resolved = await ar.resolve(anchor.cloudId);
      mapFromSession = alignMap(anchor.pose, resolved.transformation);
    },
  );
  Future<void> showAnchors() async {
    setState(() => placing = false);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('Anchors'),
              subtitle: Text('Tap a destination. Use its menu to localize.'),
            ),
            for (final a in widget.map.anchors)
              ListTile(
                title: Text(a.name),
                subtitle: Text(
                  a.expired
                      ? 'Expired'
                      : 'Expires ${a.expiresAt.toLocal().toString().substring(0, 16)}',
                ),
                onTap: () {
                  Navigator.pop(sheet);
                  setState(() => destination = a);
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    Navigator.pop(sheet);
                    if (value == 'resolve') {
                      await resolve(a);
                      return;
                    }
                    if (value == 'rename') {
                      final name = await askName(
                        context,
                        'Rename anchor',
                        a.name,
                      );
                      if (name == null) return;
                      a.name = name;
                    }
                    if (value == 'delete') {
                      widget.map.anchors.remove(a);
                      if (destination == a) destination = null;
                    }
                    if (!mounted) return;
                    await runOperation('Saving…', widget.save);
                  },
                  itemBuilder: (_) => [
                    if (!a.expired)
                      const PopupMenuItem(
                        value: 'resolve',
                        child: Text('Localize here'),
                      ),
                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete locally'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ar.removeListener(refresh);
    ar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supported =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final pose = camera, target = destination;
    final distance = pose != null && target != null
        ? horizontalDistance(
            pose.getTranslation(),
            target.pose.getTranslation(),
          )
        : null;
    final canPlace =
        supported &&
        active &&
        ar.tracking &&
        !busy &&
        (mapFromSession != null || widget.map.anchors.isEmpty);
    return Scaffold(
      // Resizing the virtual-display AR view for the name keyboard destroys its
      // camera surfaces. Keep the native view size stable while dialogs type.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.map.name)),
      body: supported
          ? Stack(
              children: [
                Positioned.fill(
                  child: ARView(
                    planeDetectionConfig: PlaneDetectionConfig.horizontal,
                    onARViewCreated: (s, o, a, l) async {
                      try {
                        await ar.attach(s, a);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('AR initialization failed: $e'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        (operation == null
                                ? null
                                : '$operation\n${ar.cloudStage ?? ""}') ??
                            (draftPose != null
                                ? 'Anchor placed — scan, then press Save anchor.'
                                : placing
                                ? 'Tap a detected horizontal surface'
                                : '${ar.status}\n${mapFromSession == null ? (widget.map.anchors.isEmpty ? 'Place the first anchor to establish this map.' : 'Select Anchors → Localize here to align this map.') : 'Localized • Direct guidance ignores walls and obstacles.'}'),
                      ),
                    ),
                  ),
                ),
                if (draftPose == null && target != null)
                  Positioned(
                    left: 16,
                    top: 130,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(target.name),
                            if (distance != null) ...[
                              Transform.rotate(
                                angle: relativeBearing(
                                  pose!,
                                  target.pose.getTranslation(),
                                ),
                                child: Icon(
                                  distance <= 1
                                      ? Icons.check_circle
                                      : Icons.arrow_upward,
                                  size: 72,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                distance <= 1
                                    ? 'Arrived • ${distance.toStringAsFixed(1)} m'
                                    : '${distance.toStringAsFixed(1)} m',
                              ),
                            ] else
                              const Text('Guidance paused'),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (draftPose != null)
                  Positioned(
                    top: 125,
                    left: 12,
                    right: 12,
                    child: ScanPanel(
                      scan: scan,
                      tracking: ar.tracking,
                      busy: busy,
                      onSave: ar.tracking && active && !busy ? saveDraft : null,
                      onCancel: busy
                          ? null
                          : () => setState(() => draftPose = null),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 90,
                  left: expanded ? 12 : null,
                  child: SizedBox(
                    width: expanded ? null : 190,
                    height: expanded
                        ? MediaQuery.sizeOf(context).height * .48
                        : 190,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 36,
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                const Expanded(child: Text('Map • up = −Z')),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      setState(() => expanded = !expanded),
                                  icon: Icon(
                                    expanded
                                        ? Icons.close_fullscreen
                                        : Icons.open_in_full,
                                  ),
                                  tooltip: 'Expand map',
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final size = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );
                                final layout = MapLayout(
                                  widget.map,
                                  pose,
                                  size,
                                );
                                return InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 6,
                                  child: GestureDetector(
                                    onTapUp: (details) {
                                      SavedAnchor? closest;
                                      var best = 24.0;
                                      for (final a in widget.map.anchors) {
                                        final d =
                                            (layout.point(a.pose) -
                                                    details.localPosition)
                                                .distance;
                                        if (d < best) {
                                          best = d;
                                          closest = a;
                                        }
                                      }
                                      if (closest != null) {
                                        setState(() => destination = closest);
                                      }
                                    },
                                    child: CustomPaint(
                                      size: size,
                                      painter: BirdMapPainter(
                                        layout,
                                        destination,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FilledButton.icon(
                        onPressed: busy || draftPose != null
                            ? null
                            : showAnchors,
                        icon: const Icon(Icons.place),
                        label: const Text('Anchors'),
                      ),
                      FilledButton.icon(
                        onPressed: canPlace && draftPose == null
                            ? () => setState(() => placing = !placing)
                            : null,
                        icon: Icon(
                          placing ? Icons.close : Icons.add_location_alt,
                        ),
                        label: Text(placing ? 'Cancel' : 'Add anchor'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: Text(
                'This AR prototype requires an ARCore-compatible Android phone.',
              ),
            ),
    );
  }
}

class MapLayout {
  MapLayout(this.map, this.camera, this.size) {
    final positions = [
      ...map.anchors.map((a) => a.pose.getTranslation()),
      if (camera != null) camera!.getTranslation(),
    ];
    if (positions.isEmpty) return;
    var minX = positions.first.x,
        maxX = minX,
        minZ = positions.first.z,
        maxZ = minZ;
    for (final p in positions) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minZ = math.min(minZ, p.z);
      maxZ = math.max(maxZ, p.z);
    }
    cx = (minX + maxX) / 2;
    cz = (minZ + maxZ) / 2;
    scale = math.max(
      .001,
      math.min(
        math.max(1, size.width - 70) / math.max(4, maxX - minX),
        math.max(1, size.height - 50) / math.max(4, maxZ - minZ),
      ),
    );
  }
  final AnchorMap map;
  final Matrix4? camera;
  final Size size;
  double cx = 0, cz = 0, scale = 20;
  Offset point(Matrix4 pose) => Offset(
    size.width / 2 + (pose.entry(0, 3) - cx) * scale,
    size.height / 2 + (pose.entry(2, 3) - cz) * scale,
  );
}

class BirdMapPainter extends CustomPainter {
  BirdMapPainter(this.layout, this.destination);
  final MapLayout layout;
  final SavedAnchor? destination;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xffedf2f7),
    );
    for (final a in layout.map.anchors) {
      final p = layout.point(a.pose);
      canvas.drawCircle(
        p,
        a == destination ? 8 : 5,
        Paint()
          ..color = a == destination
              ? Colors.orange
              : (a.expired ? Colors.grey : Colors.teal),
      );
      final text = TextPainter(
        text: TextSpan(
          text: a.name,
          style: const TextStyle(color: Colors.black, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 90);
      text.paint(canvas, p + const Offset(8, -8));
    }
    final camera = layout.camera;
    if (camera != null) {
      final p = layout.point(camera), angle = heading(camera);
      canvas.drawLine(
        p,
        p + Offset(math.sin(angle) * 22, -math.cos(angle) * 22),
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 3,
      );
      canvas.drawCircle(p, 7, Paint()..color = Colors.blue);
      canvas.drawCircle(
        p,
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BirdMapPainter oldDelegate) => true;
}
