import 'package:flutter/material.dart';
import 'floor_data.dart';
import 'floor_screen.dart';
import 'routing.dart';

/// Clips the camera without resizing its native surface.
class CameraOverlayClipper extends CustomClipper<Path> {
  CameraOverlayClipper({required this.compact});
  final bool compact;
  @override
  Path getClip(Size size) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        compact
            ? Rect.fromLTWH(size.width - 156, 190, 140, 170)
            : Offset.zero & size,
        Radius.circular(compact ? 20 : 0),
      ),
    );
  @override
  bool shouldReclip(CameraOverlayClipper oldClipper) =>
      compact != oldClipper.compact;
}

class NavigationPanel extends StatefulWidget {
  const NavigationPanel({
    super.key,
    required this.graph,
    required this.setup,
    required this.pose,
    required this.calibration,
    required this.guidance,
    required this.destination,
    required this.message,
    required this.busy,
    required this.onSearch,
    required this.onLocate,
    required this.onCancel,
  });
  final FloorGraph graph;
  final FloorSetup setup;
  final Matrix4? pose;
  final FloorCalibration? calibration;
  final GuidanceState guidance;
  final String? destination;
  final String message;
  final bool busy;
  final VoidCallback onSearch, onLocate, onCancel;
  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  final transform = TransformationController();
  bool follow = true;
  bool overview = false;
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget, g = w.guidance;
    final pose = w.pose, c = w.calibration;
    final position = pose == null || c == null
        ? null
        : c.toImage(Offset(pose.entry(0, 3), pose.entry(2, 3)));
    final heading = pose == null || c == null
        ? null
        : c.toImage(
            Offset(
              pose.entry(0, 3) - pose.entry(0, 2),
              pose.entry(2, 3) - pose.entry(2, 2),
            ),
          );
    final duration = g.estimatedDuration;
    final eta = duration == null
        ? null
        : TimeOfDay.fromDateTime(DateTime.now().add(duration)).format(context);
    final points = g.route?.points ?? <Offset>[];
    final remaining = g.projected == null || points.length < 2
        ? points
        : <Offset>[g.projected!, ...points.skip(g.segment + 1)];
    return ColoredBox(
      color: const Color(0xffeef2f6),
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, bounds) {
                final fitted = applyBoxFit(
                  BoxFit.contain,
                  floorImageSize,
                  bounds.biggest,
                ).destination;
                if (follow && position != null && !overview) {
                  final px = position.dx / floorImageSize.width * fitted.width;
                  final py =
                      position.dy / floorImageSize.height * fitted.height;
                  transform.value = Matrix4.identity()
                    ..translateByDouble(
                      fitted.width / 2 - px * 2,
                      fitted.height / 2 - py * 2,
                      0,
                      1,
                    )
                    ..scaleByDouble(2, 2, 1, 1);
                } else if (overview) {
                  transform.value = Matrix4.identity();
                }
                return Listener(
                  onPointerDown: (_) {
                    follow = false;
                    overview = false;
                  },
                  child: Stack(
                    children: [
                      FloorCanvas(
                        graph: w.graph,
                        setup: w.setup,
                        camera: position,
                        headingPoint: heading,
                        route: remaining,
                        fullRoute: points,
                        showLabels: false,
                        showGraph: false,
                        transformationController: transform,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      g.arrived
                          ? Icons.check_circle
                          : g.maneuver == 'Turn left'
                          ? Icons.turn_left
                          : g.maneuver == 'Turn right'
                          ? Icons.turn_right
                          : g.maneuver == 'Turn around'
                          ? Icons.u_turn_left
                          : Icons.straight,
                      size: 36,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w.destination == null
                            ? 'Where to? — Floor 1'
                            : g.remainingMeters == null
                            ? g.status
                            : g.arrived
                            ? 'Near entrance'
                            : '${g.maneuver}${g.maneuverMeters == null ? '' : ' in ${g.maneuverMeters!.round()} m'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: w.onSearch,
                      tooltip: 'Choose destination',
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Text(
              c == null
                  ? 'Calibrate two anchors in Floor 1 setup'
                  : position == null
                  ? w.message
                  : 'Floor 1 • Draft hallway map',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Positioned(
            left: 16,
            top: 190,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  tooltip: 'Recenter',
                  onPressed: () => setState(() {
                    follow = true;
                    overview = false;
                  }),
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'overview',
                  tooltip: 'Map overview',
                  onPressed: () => setState(() {
                    follow = false;
                    overview = true;
                  }),
                  child: const Icon(Icons.zoom_out_map),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              top: false,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.destination ?? 'Explore Floor 1',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (w.destination != null)
                        Text(
                          duration == null
                              ? g.status
                              : g.arrived
                              ? 'Near entrance (estimated)'
                              : '${duration.inSeconds < 60 ? 'Less than 1 min' : '${(duration.inSeconds / 60).ceil()} min'} • ${g.remainingMeters!.round()} m • ETA $eta',
                          maxLines: 2,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: w.destination == null
                                  ? w.onSearch
                                  : w.onCancel,
                              icon: Icon(
                                w.destination == null
                                    ? Icons.search
                                    : Icons.close,
                              ),
                              label: Text(
                                w.destination == null
                                    ? 'Choose destination'
                                    : 'Cancel',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: w.onLocate,
                            child: Text(w.busy ? 'Cancel search' : 'Locate'),
                          ),
                        ],
                      ),
                      const Text(
                        'Walking times and map geometry are estimates.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
