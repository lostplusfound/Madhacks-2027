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
    this.onMapBoundsChanged,
  });
  final String? destinationId;
  final ValueChanged<Rect>? onMapBoundsChanged;
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
  final mapRegionKey = GlobalKey();
  final panelKey = GlobalKey();

  void reportMapBounds() {
    if (widget.onMapBoundsChanged == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final region = mapRegionKey.currentContext?.findRenderObject();
      final panel = panelKey.currentContext?.findRenderObject();
      if (region is RenderBox && panel is RenderBox && region.hasSize) {
        widget.onMapBoundsChanged!(
          region.localToGlobal(Offset.zero, ancestor: panel) & region.size,
        );
      }
    });
  }

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
              Text(widget.graph.floorLabel),
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
    final instruction = w.destination == null
        ? 'Explore ${w.graph.floorLabel}'
        : g.remainingMeters == null
        ? g.status
        : g.phase == NavigationPhase.returningToRoute
        ? 'Return to route - ${distance(g.rejoinMeters!)}'
        : g.arrived
        ? 'Near entrance'
        : '${g.maneuver}${g.maneuverMeters == null ? '' : ' in ${distance(g.maneuverMeters!)}'}';
    final status = c == null
        ? 'Calibrate two anchors in floor setup'
        : position == null || w.estimated || w.busy
        ? w.message
        : g.phase == NavigationPhase.returningToRoute
        ? 'Estimated return direction; check the floor plan'
        : '${w.graph.floorLabel} - Draft hallway map';
    final theme = Theme.of(context);
    reportMapBounds();
    return LayoutBuilder(
      builder: (context, bounds) => ColoredBox(
        key: panelKey,
        color: const Color(0xfff6f4f0),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: bounds.maxHeight * .42),
              child: SingleChildScrollView(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Transform.rotate(
                                angle:
                                    g.phase == NavigationPhase.returningToRoute
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
                                  size: 28,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                instruction,
                                key: const ValueKey('navigation-instruction'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: w.onSearch,
                              tooltip: 'Choose destination',
                              icon: const Icon(Icons.search),
                            ),
                          ],
                        ),
                        if (status.isNotEmpty && status != instruction) ...[
                          const SizedBox(height: 12),
                          Text(
                            status,
                            key: const ValueKey('navigation-status'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                key: mapRegionKey,
                children: [
                  Positioned.fill(
                    child: InteractiveFloorMap(
                      graph: w.graph,
                      setup: w.setup,
                      controller: viewport,
                      position: position,
                      heading: heading,
                      route: remaining,
                      fullRoute: points,
                      rejoinPoint: g.remainingMeters == null
                          ? null
                          : g.rejoinPoint,
                      selectedLocation: selectedLocation ?? w.destinationId,
                      highContrast: w.highContrast,
                      onLocation: showLocation,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    bottom: 12,
                    left: 16,
                    child: SingleChildScrollView(
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
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: bounds.maxHeight * .32),
              child: SingleChildScrollView(
                child: SafeArea(
                  top: false,
                  child: Card(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            w.destination ?? 'Explore ${w.graph.floorLabel}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (w.destination != null && duration != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              g.arrived
                                  ? 'Near entrance (estimated)'
                                  : '${duration.inSeconds < 60 ? 'Less than 1 min' : '${(duration.inSeconds / 60).ceil()} min'} - ${distance(g.tripMeters!)} - ETA $eta',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FilledButton.icon(
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
                              TextButton(
                                onPressed: w.onLocate,
                                child: Text(
                                  w.busy ? 'Cancel search' : 'Locate',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Walking times and map geometry are estimates.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
