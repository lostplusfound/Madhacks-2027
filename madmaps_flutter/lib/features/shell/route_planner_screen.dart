import 'package:flutter/material.dart';
import 'package:madmaps_client/madmaps_client.dart' as api;
import '../navigation/building_routing.dart';
import '../navigation/floor_data.dart';
import '../navigation/floor_screen.dart';
import '../navigation/routing.dart';
import 'app_state.dart';

Future<FloorLocation?> pickRoutePlace(
  BuildContext context,
  List<FloorLocation> places,
  String title,
) => showDialog<FloorLocation>(
  context: context,
  builder: (context) {
    var query = '';
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          height: 400,
          child: Column(
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Search places'),
                onChanged: (value) =>
                    setState(() => query = value.toLowerCase()),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final p in places.where(
                      (p) => '${p.label} ${p.aliases} ${p.floorLabel}'
                          .toLowerCase()
                          .contains(query),
                    ))
                      ListTile(
                        title: Text(p.label),
                        subtitle: Text(p.floorLabel),
                        onTap: () => Navigator.pop(context, p),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  },
);

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({
    super.key,
    required this.floors,
    required this.connectors,
    required this.state,
    required this.onLocalize,
    this.destination,
    this.initialAvoidStairs = false,
    this.initialTravelMode = FloorTravelMode.elevator,
    this.onTravelModeChanged,
  });
  final Map<int, FloorGraph> floors;
  final List<api.FloorConnector> connectors;
  final AppState state;
  final FloorLocation? destination;
  final bool initialAvoidStairs;
  final FloorTravelMode initialTravelMode;
  final ValueChanged<FloorTravelMode>? onTravelModeChanged;
  final void Function(FloorLocation, bool) onLocalize;
  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  FloorLocation? start;
  late FloorLocation? end = widget.destination;
  late bool avoidStairs = widget.initialAvoidStairs;
  late FloorTravelMode travelMode = widget.initialTravelMode;
  BuildingRoute? route;
  String? error;
  int legIndex = 0;
  final completed = <int>{};
  List<FloorLocation> get places =>
      widget.floors.values.expand((g) => g.locations).toList();
  void calculate() {
    route = null;
    error = null;
    legIndex = 0;
    completed.clear();
    if (start == null || end == null) return;
    final g = widget.floors[start!.floor]!;
    if (start!.node == null || !g.nodes.containsKey(start!.node)) {
      error = 'This start has no mapped entrance. Choose another place.';
      return;
    }
    route = planBuildingRoute(
      floors: widget.floors,
      connectors: widget.connectors,
      startFloor: start!.floor,
      start: g.nodes[start!.node]!.point,
      startNode: start!.node,
      destination: end!,
      avoidStairs: avoidStairs,
      travelMode: travelMode,
    );
    if (route == null)
      error = 'No connected route is available with these preferences.';
  }

  List<String> instructions() {
    if (route == null) return [];
    final steps = <String>[];
    for (final leg in route!.legs) {
      final label = widget.floors[leg.floor]!.floorLabel;
      final scale = widget.floors[leg.floor]!.metersPerPixel;
      if (leg.points.length > 1) {
        var distance = 0.0;
        var action = 'Follow the highlighted path';
        for (var i = 1; i < leg.points.length; i++) {
          distance += (leg.points[i] - leg.points[i - 1]).distance * scale;
          final turn = i + 1 < leg.points.length
              ? turnInstruction(
                  leg.points[i] - leg.points[i - 1],
                  leg.points[i + 1] - leg.points[i],
                )
              : null;
          if (turn != 'Continue') {
            steps.add(
              '$label: $action for about ${widget.state.distance(distance)}.',
            );
            action = turn ?? 'Continue';
            distance = 0;
          }
        }
      }
      if (leg.exit case final exit?) {
        steps.add(
          '${floorTransitionInstruction(exit)}.',
        );
      }
    }
    steps.add('Reach the entrance to ${widget.state.label(end!)}.');
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final steps = instructions();
    final leg = route?.legs[legIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('Directions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Start'),
            subtitle: Text(
              start == null
                  ? 'Current location'
                  : '${widget.state.label(start!)} · ${start!.floorLabel}',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final selected = await pickRoutePlace(
                context,
                places,
                'Choose start',
              );
              if (mounted && selected != null)
                setState(() {
                  start = selected;
                  calculate();
                });
            },
          ),
          if (start != null)
            TextButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('Use current location'),
              onPressed: () => setState(() {
                start = null;
                calculate();
              }),
            ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Destination'),
            subtitle: Text(
              end == null
                  ? 'Choose destination'
                  : '${widget.state.label(end!)} · ${end!.floorLabel}',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final selected = await pickRoutePlace(
                context,
                places,
                'Choose destination',
              );
              if (mounted && selected != null)
                setState(() {
                  end = selected;
                  calculate();
                });
            },
          ),
          SwitchListTile(
            title: const Text('Avoid stairs'),
            value: avoidStairs,
            onChanged: (v) => setState(() {
              avoidStairs = v;
              calculate();
            }),
          ),
          FloorTravelPicker(
            value: travelMode,
            avoidStairs: avoidStairs,
            onChanged: (value) => setState(() {
              travelMode = value;
              widget.onTravelModeChanged?.call(value);
              calculate();
            }),
          ),
          if (start == null)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Current location requires visual localization. Scan your surroundings to find your position before live guidance begins. To get directions without the camera, choose a start place.',
              ),
            ),
          if (error != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
          if (route != null) ...[
            Text(
              '${widget.state.distance(route!.meters)} · about ${(route!.seconds / 60).ceil()} min (estimated)',
            ),
            const Text(
              'Follow these steps manually. Your location and arrival are not tracked.',
            ),
            if (route!.legs.length > 1)
              DropdownButton<int>(
                value: legIndex,
                isExpanded: true,
                items: [
                  for (var i = 0; i < route!.legs.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        'Part ${i + 1}: ${widget.floors[route!.legs[i].floor]!.floorLabel}',
                      ),
                    ),
                ],
                onChanged: (i) => setState(() => legIndex = i!),
              ),
            SizedBox(
              height: 300,
              child: FloorCanvas(
                graph: widget.floors[leg!.floor]!,
                setup: FloorSetup(),
                showGraph: false,
                showLabels: false,
                route: leg.points,
                fullRoute: leg.points,
              ),
            ),
            for (var i = 0; i < steps.length; i++)
              CheckboxListTile(
                value: completed.contains(i),
                title: Text('${i + 1}. ${steps[i]}'),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    completed.add(i);
                  } else {
                    completed.remove(i);
                  }
                }),
              ),
          ],
          FilledButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(
              start == null
                  ? 'Localize and navigate'
                  : 'Localize visually for live guidance',
            ),
            onPressed: end == null
                ? null
                : () => widget.onLocalize(end!, avoidStairs),
          ),
        ],
      ),
    );
  }
}

/// Shared preference for manual planning and live cross-floor rerouting.
class FloorTravelPicker extends StatelessWidget {
  const FloorTravelPicker({
    super.key,
    required this.value,
    required this.avoidStairs,
    required this.onChanged,
  });
  final FloorTravelMode value;
  final bool avoidStairs;
  final ValueChanged<FloorTravelMode> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: DropdownButtonFormField<FloorTravelMode>(
      key: ValueKey((value, avoidStairs)),
      initialValue: avoidStairs ? FloorTravelMode.elevator : value,
      decoration: const InputDecoration(labelText: 'Between floors'),
      items: const [
        DropdownMenuItem(
          value: FloorTravelMode.elevator,
          child: Text('Elevator'),
        ),
        DropdownMenuItem(value: FloorTravelMode.stairs, child: Text('Stairs')),
      ],
      onChanged: avoidStairs
          ? null
          : (v) {
              if (v != null) onChanged(v);
            },
    ),
  );
}
