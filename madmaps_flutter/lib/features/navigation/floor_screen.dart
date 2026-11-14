import 'package:flutter/material.dart';
import '../localization/map_data.dart';
import 'floor_data.dart';

class FloorCanvas extends StatelessWidget {
  const FloorCanvas({
    super.key,
    required this.graph,
    required this.setup,
    this.camera,
    this.headingPoint,
    this.route = const [],
    this.onPoint,
    this.showLabels = true,
    this.transformationController,
  });
  final FloorGraph graph;
  final FloorSetup setup;
  final Offset? camera, headingPoint;
  final List<Offset> route;
  final ValueChanged<Offset>? onPoint;
  final bool showLabels;
  final TransformationController? transformationController;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final fitted = applyBoxFit(
        BoxFit.contain,
        floorImageSize,
        bounds.biggest,
      ).destination;
      return Center(
        child: SizedBox(
          width: fitted.width,
          height: fitted.height,
          child: InteractiveViewer(
            transformationController: transformationController,
            maxScale: 8,
            child: GestureDetector(
              onTapUp: onPoint == null
                  ? null
                  : (d) => onPoint!(
                      Offset(
                        d.localPosition.dx /
                            fitted.width *
                            floorImageSize.width,
                        d.localPosition.dy /
                            fitted.height *
                            floorImageSize.height,
                      ),
                    ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/floor1/plan.png', fit: BoxFit.fill),
                  CustomPaint(
                    painter: _FloorPainter(
                      graph,
                      setup,
                      camera,
                      headingPoint,
                      route,
                      showLabels,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _FloorPainter extends CustomPainter {
  _FloorPainter(
    this.graph,
    this.setup,
    this.camera,
    this.headingPoint,
    this.route,
    this.labels,
  );
  final FloorGraph graph;
  final FloorSetup setup;
  final Offset? camera, headingPoint;
  final List<Offset> route;
  final bool labels;
  @override
  void paint(Canvas canvas, Size size) {
    Offset p(Offset q) => Offset(
      q.dx / floorImageSize.width * size.width,
      q.dy / floorImageSize.height * size.height,
    );
    final edgePaint = Paint()
      ..color = Colors.orange.withValues(alpha: .8)
      ..strokeWidth = 2;
    for (final e in graph.edges) {
      canvas.drawLine(
        p(graph.point(e.from, setup)),
        p(graph.point(e.to, setup)),
        edgePaint,
      );
    }
    for (final n in graph.nodes.values) {
      canvas.drawCircle(
        p(graph.point(n.id, setup)),
        3,
        Paint()..color = Colors.deepOrange,
      );
    }
    for (var i = 1; i < route.length; i++) {
      canvas.drawLine(
        p(route[i - 1]),
        p(route[i]),
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 4,
      );
    }
    for (final entry in setup.anchorPoints.entries) {
      canvas.drawCircle(p(entry.value), 6, Paint()..color = Colors.teal);
    }
    if (labels) {
      for (final l in graph.locations) {
        final node = setup.locationNodes[l.id] ?? l.node;
        if (node == null || !graph.nodes.containsKey(node)) continue;
        final text = TextPainter(
          text: TextSpan(
            text: l.label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black,
              backgroundColor: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 130);
        text.paint(canvas, p(graph.point(node, setup)) + const Offset(5, 3));
      }
    }
    if (camera != null) {
      if (headingPoint != null) {
        final direction = p(headingPoint!) - p(camera!);
        if (direction.distance > 0) {
          canvas.drawLine(
            p(camera!),
            p(camera!) + direction / direction.distance * 22,
            Paint()
              ..color = Colors.blue
              ..strokeWidth = 3,
          );
        }
      }
      canvas.drawCircle(p(camera!), 7, Paint()..color = Colors.blue);
      canvas.drawCircle(
        p(camera!),
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloorPainter oldDelegate) => true;
}

class FloorSetupScreen extends StatefulWidget {
  const FloorSetupScreen({
    super.key,
    required this.map,
    required this.graph,
    required this.save,
  });
  final AnchorMap map;
  final FloorGraph graph;
  final Future<void> Function() save;
  @override
  State<FloorSetupScreen> createState() => _FloorSetupScreenState();
}

class _FloorSetupScreenState extends State<FloorSetupScreen> {
  String mode = 'anchor';
  String? selected, location, linkNode;
  String message =
      'Select an anchor, then tap its physical location on the plan.';
  FloorSetup get setup => widget.map.floor;
  Future<void> persist() async {
    try {
      await widget.save();
    } catch (e) {
      if (mounted) setState(() => message = 'Could not save: $e');
    }
  }

  Future<void> place(Offset p) async {
    if (selected == null) return;
    setState(() {
      if (mode == 'anchor') {
        setup.anchorPoints[selected!] = p;
        if (setup.calibrationIds.contains(selected)) {
          setup.calibrationIds.clear();
        }
        message = 'Anchor placed. Choose two calibration anchors below.';
      } else {
        setup.nodePoints[selected!] = p;
        message = 'Draft node moved; incident edge lengths updated.';
      }
    });
    await persist();
  }

  @override
  Widget build(BuildContext context) {
    final calibration = setup.calibration(widget.map);
    final placed = widget.map.anchors
        .where((a) => setup.anchorPoints.containsKey(a.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Floor 1 setup • draft')),
      body: Column(
        children: [
          Expanded(
            child: FloorCanvas(
              graph: widget.graph,
              setup: setup,
              onPoint: place,
            ),
          ),
          SizedBox(
            height: 310,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                SwitchListTile(
                  title: const Text('Associate this AR map with floor 1'),
                  value: setup.enabled,
                  onChanged: (v) {
                    setState(() => setup.enabled = v);
                    persist();
                  },
                ),
                Text(message),
                Text(
                  calibration == null
                      ? 'Not calibrated. Place two anchors at least 2 m apart.'
                      : 'Calibrated: ${calibration.scale.toStringAsFixed(2)} pixels/meter',
                ),
                DropdownButton<String>(
                  value: mode,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'anchor',
                      child: Text('Place anchor on image'),
                    ),
                    DropdownMenuItem(
                      value: 'node',
                      child: Text('Correct draft graph node'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    mode = v!;
                    selected = null;
                  }),
                ),
                DropdownButton<String>(
                  value: selected,
                  hint: const Text('Select item, then tap image'),
                  isExpanded: true,
                  items: mode == 'anchor'
                      ? widget.map.anchors
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
                            .toList()
                      : widget.graph.nodes.keys
                            .map(
                              (id) =>
                                  DropdownMenuItem(value: id, child: Text(id)),
                            )
                            .toList(),
                  onChanged: (v) => setState(() => selected = v),
                ),
                Wrap(
                  children: [
                    for (final a in placed)
                      Padding(
                        padding: const EdgeInsets.all(3),
                        child: FilterChip(
                          label: Text('Calibrate: ${a.name}'),
                          selected: setup.calibrationIds.contains(a.id),
                          onSelected: (v) async {
                            setState(() {
                              if (!v) {
                                setup.calibrationIds.remove(a.id);
                              } else if (setup.calibrationIds.length < 2) {
                                setup.calibrationIds.add(a.id);
                              }
                              message =
                                  setup.calibrationIds.length == 2 &&
                                      setup.calibration(widget.map) == null
                                  ? 'Invalid pair: anchors must be at least 2 m apart.'
                                  : 'Use a third placed anchor to check the alignment below.';
                            });
                            await persist();
                          },
                        ),
                      ),
                  ],
                ),
                if (calibration != null)
                  for (final a in placed.where(
                    (a) => !setup.calibrationIds.contains(a.id),
                  ))
                    Text(
                      '${a.name}: check error ${((calibration.toImage(anchorPosition(a)) - setup.anchorPoints[a.id]!).distance / calibration.scale).toStringAsFixed(2)} m',
                    ),
                const Divider(),
                const Text('Assign room or anchor to a graph approach point'),
                DropdownButton<String>(
                  value: location,
                  isExpanded: true,
                  hint: const Text('Choose destination'),
                  items: [
                    for (final l in widget.graph.locations)
                      DropdownMenuItem(
                        value: 'room:${l.id}',
                        child: Text(l.label),
                      ),
                    for (final a in widget.map.anchors)
                      DropdownMenuItem(
                        value: 'anchor:${a.id}',
                        child: Text('Anchor: ${a.name}'),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    location = v;
                    linkNode = null;
                  }),
                ),
                DropdownButton<String>(
                  value: linkNode,
                  isExpanded: true,
                  hint: const Text('Choose approach node'),
                  items: [
                    for (final n in widget.graph.nodes.values.where(
                      (n) => n.kind == 'approach',
                    ))
                      DropdownMenuItem(value: n.id, child: Text(n.id)),
                  ],
                  onChanged: (v) => setState(() => linkNode = v),
                ),
                FilledButton(
                  onPressed: location == null || linkNode == null
                      ? null
                      : () async {
                          setState(() {
                            if (location!.startsWith('room:')) {
                              setup.locationNodes[location!.substring(5)] =
                                  linkNode!;
                            } else {
                              setup.anchorNodes[location!.substring(7)] =
                                  linkNode!;
                            }
                            message = 'Destination linked to $linkNode';
                          });
                          await persist();
                        },
                  child: const Text('Save destination link'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
