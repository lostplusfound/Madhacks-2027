import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'floor_data.dart';
import 'floor_screen.dart';

enum FloorFollowMode { heading, position, free }

/// View state is independent of the floor image and AR camera.
class FloorViewportController extends ChangeNotifier {
  FloorFollowMode mode = FloorFollowMode.position;
  bool _navigating = false;
  bool get following => mode != FloorFollowMode.free;
  set following(bool value) =>
      mode = value ? FloorFollowMode.position : FloorFollowMode.free;
  int overviewRevision = 0, northRevision = 0;
  void navigation(bool active) {
    if (_navigating == active) return;
    _navigating = active;
    if (active) {
      mode = FloorFollowMode.heading;
    } else if (mode == FloorFollowMode.heading) {
      mode = FloorFollowMode.position;
    }
    notifyListeners();
  }

  void followHeading() {
    mode = FloorFollowMode.heading;
    notifyListeners();
  }

  void recenter() {
    mode = _navigating ? FloorFollowMode.heading : FloorFollowMode.position;
    notifyListeners();
  }

  void overview() {
    mode = FloorFollowMode.free;
    overviewRevision++;
    notifyListeners();
  }

  void north() {
    mode = FloorFollowMode.position;
    northRevision++;
    notifyListeners();
  }
}

class InteractiveFloorMap extends StatefulWidget {
  const InteractiveFloorMap({
    super.key,
    required this.graph,
    required this.setup,
    required this.controller,
    required this.position,
    required this.heading,
    required this.route,
    required this.fullRoute,
    this.rejoinPoint,
    required this.onLocation,
    this.selectedLocation,
  });
  final FloorGraph graph;
  final FloorSetup setup;
  final FloorViewportController controller;
  final Offset? position, heading, rejoinPoint;
  final List<Offset> route, fullRoute;
  final ValueChanged<FloorLocation> onLocation;
  final String? selectedLocation;
  @override
  State<InteractiveFloorMap> createState() => _InteractiveFloorMapState();
}

class _InteractiveFloorMapState extends State<InteractiveFloorMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController rotation;
  Tween<double> rotationTween = Tween(begin: 0, end: 0);
  double? headingTarget;
  bool hasHeading = false;
  Offset gestureFocal = Offset.zero;
  Offset center = const Offset(760, 490), anchor = Offset.zero;
  double zoom = 1, angle = 0, startZoom = 1, startAngle = 0;
  int overviewRevision = 0, northRevision = 0;
  Matrix4 matrix = Matrix4.identity();
  Size viewport = Size.zero;
  @override
  void initState() {
    super.initState();
    rotation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          if (mounted && widget.controller.mode == FloorFollowMode.heading) {
            setState(() => angle = rotationTween.transform(rotation.value));
          }
        });
    widget.controller.addListener(changed);
    updateHeading();
  }

  void updateHeading() {
    final p = widget.position, h = widget.heading;
    if (widget.controller.mode != FloorFollowMode.heading ||
        p == null ||
        h == null ||
        (h - p).distance < 1e-6) {
      rotation.stop();
      headingTarget = null;
      return;
    }
    final d = h - p;
    final target = -math.pi / 2 - math.atan2(d.dy, d.dx);
    if (headingTarget != null &&
        math
                .atan2(
                  math.sin(target - headingTarget!),
                  math.cos(target - headingTarget!),
                )
                .abs() <
            1e-5) {
      return;
    }
    headingTarget = target;
    final delta = math.atan2(
      math.sin(target - angle),
      math.cos(target - angle),
    );
    if (!hasHeading) {
      hasHeading = true;
      angle += delta;
      return;
    }
    rotationTween = Tween(begin: angle, end: angle + delta);
    rotation.forward(from: 0);
  }

  void changed() {
    updateHeading();
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(InteractiveFloorMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(changed);
      widget.controller.addListener(changed);
    }
    updateHeading();
  }

  @override
  void dispose() {
    widget.controller.removeListener(changed);
    rotation.dispose();
    super.dispose();
  }

  Offset unrotate(Offset delta) =>
      Offset(
        math.cos(angle) * delta.dx + math.sin(angle) * delta.dy,
        -math.sin(angle) * delta.dx + math.cos(angle) * delta.dy,
      ) /
      zoom;
  Matrix4 get viewMatrix => Matrix4.identity()
    ..translateByDouble(viewport.width / 2, viewport.height / 2, 0, 1)
    ..rotateZ(angle)
    ..scaleByDouble(zoom, zoom, 1, 1)
    ..translateByDouble(-center.dx, -center.dy, 0, 1);
  void fit() {
    final points = widget.fullRoute.isNotEmpty
        ? [...widget.fullRoute, if (widget.position != null) widget.position!]
        : widget.graph.nodes.keys
              .map((id) => widget.graph.point(id, widget.setup))
              .toList();
    if (points.isEmpty) return;
    var left = points.first.dx,
        right = left,
        top = points.first.dy,
        bottom = top;
    for (final p in points) {
      left = math.min(left, p.dx);
      right = math.max(right, p.dx);
      top = math.min(top, p.dy);
      bottom = math.max(bottom, p.dy);
    }
    center = Offset((left + right) / 2, (top + bottom) / 2);
    if (widget.controller.mode != FloorFollowMode.heading) angle = 0;
    zoom = math
        .min(
          viewport.width / math.max(180, right - left + 120),
          viewport.height / math.max(180, bottom - top + 120),
        )
        .clamp(.1, 4.0);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final firstLayout = viewport == Size.zero;
      viewport = bounds.biggest;
      if (firstLayout ||
          overviewRevision != widget.controller.overviewRevision) {
        overviewRevision = widget.controller.overviewRevision;
        fit();
      }
      if (northRevision != widget.controller.northRevision) {
        northRevision = widget.controller.northRevision;
        angle = 0;
      }
      if (widget.controller.following && widget.position != null) {
        center = widget.position!;
      }
      matrix = viewMatrix;
      return ClipRect(
        child: GestureDetector(
          key: const ValueKey('interactive-floor-map'),
          behavior: HitTestBehavior.opaque,
          onScaleStart: (d) {
            gestureFocal = d.localFocalPoint;
            startZoom = zoom;
            startAngle = angle;
            anchor = MatrixUtils.transformPoint(
              Matrix4.inverted(matrix),
              d.localFocalPoint,
            );
          },
          onScaleUpdate: (d) => setState(() {
            zoom = (startZoom * d.scale).clamp(.1, 4.0);
            final panning =
                (d.localFocalPoint - gestureFocal).distance > 8 &&
                (d.pointerCount == 1 || (d.scale - 1).abs() < .03);
            if (panning || d.rotation.abs() > .12) {
              widget.controller.mode = FloorFollowMode.free;
              rotation.stop();
              headingTarget = null;
            }
            if (!widget.controller.following) {
              angle = startAngle + d.rotation;
              center =
                  anchor -
                  unrotate(
                    d.localFocalPoint -
                        Offset(viewport.width / 2, viewport.height / 2),
                  );
            }
          }),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: floorImageSize.width,
                height: floorImageSize.height,
                child: Transform(
                  alignment: Alignment.topLeft,
                  transform: matrix,
                  child: IgnorePointer(
                    child: FloorCanvas(
                      graph: widget.graph,
                      setup: widget.setup,
                      camera: widget.position,
                      headingPoint: widget.heading,
                      route: widget.route,
                      fullRoute: widget.fullRoute,
                      rejoinPoint: widget.rejoinPoint,
                      interactive: false,
                      showGraph: false,
                      showLabels: false,
                    ),
                  ),
                ),
              ),
              for (final group in markerGroups()) marker(group),
            ],
          ),
        ),
      );
    },
  );

  Offset locationPoint(FloorLocation location) => MatrixUtils.transformPoint(
    matrix,
    widget.graph.point(
      widget.setup.locationNodes[location.id] ?? location.node!,
      widget.setup,
    ),
  );
  List<List<FloorLocation>> markerGroups() {
    final groups = <List<FloorLocation>>[];
    for (final location in widget.graph.locations) {
      if (!widget.graph.nodes.containsKey(
        widget.setup.locationNodes[location.id] ?? location.node,
      ))
        continue;
      final p = locationPoint(location);
      List<FloorLocation>? match;
      for (final group in groups) {
        if (group.any((l) => (locationPoint(l) - p).distance < 44)) {
          match = group;
          break;
        }
      }
      if (match == null) {
        groups.add([location]);
      } else {
        match.add(location);
      }
    }
    return groups;
  }

  Future<void> selectGroup(List<FloorLocation> group) async {
    if (group.length == 1) {
      widget.onLocation(group.single);
      return;
    }
    final location = await showModalBottomSheet<FloorLocation>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Places here')),
            for (final l in group)
              ListTile(
                title: Text(l.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(sheet, l),
              ),
          ],
        ),
      ),
    );
    if (mounted && location != null) widget.onLocation(location);
  }

  Widget marker(List<FloorLocation> group) {
    final location = group.first;
    final p =
        group.map(locationPoint).reduce((a, b) => a + b) /
        group.length.toDouble();
    final selected = group.any((l) => widget.selectedLocation == l.id);
    final label = group.length == 1 ? location.label : '${group.length} places';
    final name = location.label.toLowerCase();
    final icon = name.contains('restroom')
        ? Icons.wc
        : name.contains('cafe')
        ? Icons.local_cafe
        : name.contains('elevator')
        ? Icons.elevator
        : name.contains('stair')
        ? Icons.stairs
        : Icons.place;

    return Positioned(
      left: p.dx - 22,
      top: p.dy - 22,
      width: 44,
      height: 44,
      child: Semantics(
        label: label,
        button: true,
        child: Tooltip(
          message: label,
          child: GestureDetector(
            key: ValueKey(
              group.length == 1
                  ? 'place-${location.id}'
                  : 'cluster-${location.id}',
            ),
            behavior: HitTestBehavior.opaque,
            onTap: () => selectGroup(group),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: selected ? Colors.blue : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 3),
                  ],
                ),
                child: group.length == 1
                    ? Icon(
                        icon,
                        size: 20,
                        color: selected ? Colors.white : Colors.indigo,
                      )
                    : Text(
                        '${group.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : Colors.indigo,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
