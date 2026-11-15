import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../localization/map_data.dart' show relativeBearing;
import 'floor_data.dart';
import 'interactive_floor_map.dart';
import 'routing.dart';

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
    this.onNavigate,
    this.distanceLabel,
    this.estimated = false,
    this.highContrast = false,
    this.destinationId,
  });
  final String? destinationId;
  final bool highContrast;
  final bool estimated;
  final String Function(double)? distanceLabel;
  final ValueChanged<FloorLocation>? onNavigate;
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
  final viewport = FloorViewportController();
  String? selectedLocation;
  @override
  void initState() {
    super.initState();
    viewport.navigation(widget.destination != null);
  }

  @override
  void didUpdateWidget(NavigationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    viewport.navigation(widget.destination != null);
  }

  @override
  void dispose() {
    viewport.dispose();
    super.dispose();
  }

  Future<void> showLocation(FloorLocation location) async {
    setState(() => selectedLocation = location.id);
    final node = widget.setup.locationNodes[location.id] ?? location.node;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                location.label,
                style: Theme.of(sheet).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Floor 1'),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.directions_walk),
                label: const Text('Navigate'),
                onPressed:
                    node == null ||
                        widget.calibration == null ||
                        widget.busy ||
                        widget.onNavigate == null
                    ? null
                    : () {
                        Navigator.pop(sheet);
                        widget.onNavigate!(location);
                      },
              ),
              if (widget.calibration == null)
                const Text('Set up floor calibration first.'),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() => selectedLocation = null);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget, g = w.guidance;
    String distance(double meters) =>
        w.distanceLabel?.call(meters) ?? '${meters.round()} m';
    final pose = w.pose, c = w.calibration;
    final position = pose == null || c == null
        ? null
        : c.toImage(Offset(pose.entry(0, 3), pose.entry(2, 3)));
    final horizontalHeadingSquared = pose == null
        ? 0.0
        : pose.entry(0, 2) * pose.entry(0, 2) +
              pose.entry(2, 2) * pose.entry(2, 2);
    final heading = pose == null || c == null || horizontalHeadingSquared < .01
        ? null
        : c.toImage(
            Offset(
              pose.entry(0, 3) - pose.entry(0, 2),
              pose.entry(2, 3) - pose.entry(2, 2),
            ),
          );
    final rejoin = g.rejoinPoint == null || c == null
        ? null
        : c.toMap(g.rejoinPoint!);
    final returnAngle = pose == null || rejoin == null
        ? 0.0
        : relativeBearing(pose, Vector3(rejoin.dx, 0, rejoin.dy));
    final duration = g.estimatedDuration;
    final eta = duration == null
        ? null
        : TimeOfDay.fromDateTime(DateTime.now().add(duration)).format(context);
    final points = g.route?.points ?? <Offset>[];
    final remaining = g.projected == null || points.length < 2
        ? points
        : <Offset>[g.projected!, ...points.skip(g.segment + 1)];
    return ColoredBox(
      color: const Color(0xfff6f4f0),
      child: Stack(
        children: [
          Positioned.fill(
            top: 140,
            bottom: 205,
            child: InteractiveFloorMap(
              graph: w.graph,
              setup: w.setup,
              controller: viewport,
              position: position,
              heading: heading,
              route: remaining,
              fullRoute: points,
              rejoinPoint: g.remainingMeters == null ? null : g.rejoinPoint,
              selectedLocation: selectedLocation ?? w.destinationId,
              highContrast: w.highContrast,
              onLocation: showLocation,
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
                    Transform.rotate(
                      angle: g.phase == NavigationPhase.returningToRoute
                          ? returnAngle
                          : 0,
                      child: Icon(
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w.destination == null
                            ? 'Where to? — Floor 1'
                            : g.remainingMeters == null
                            ? g.status
                            : g.phase == NavigationPhase.returningToRoute
                            ? 'Return to route - ${distance(g.rejoinMeters!)}'
                            : g.arrived
                            ? 'Near entrance'
                            : '${g.maneuver}${g.maneuverMeters == null ? '' : ' in ${distance(g.maneuverMeters!)}'}',
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
                  : position == null || w.estimated || w.busy
                  ? w.message
                  : g.phase == NavigationPhase.returningToRoute
                  ? 'Estimated return direction; check the floor plan'
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
                  onPressed: viewport.recenter,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'overview',
                  tooltip: 'Map overview',
                  onPressed: viewport.overview,
                  child: const Icon(Icons.zoom_out_map),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'north',
                  tooltip: 'Reset rotation',
                  onPressed: viewport.north,
                  child: const Icon(Icons.explore),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'heading',
                  tooltip: 'Heading follow',
                  onPressed: viewport.followHeading,
                  child: const Icon(Icons.navigation),
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
                              : '${duration.inSeconds < 60 ? 'Less than 1 min' : '${(duration.inSeconds / 60).ceil()} min'} • ${distance(g.remainingMeters!)} • ETA $eta',
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
