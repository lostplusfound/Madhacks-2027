import 'dart:async';
import '../../client.dart';
import 'package:madmaps_client/madmaps_client.dart' as api;
import '../localization/shared_captures.dart';
import '../localization/capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../localization/map_data.dart';
import '../localization/prototype_screen.dart';
import '../navigation/floor_data.dart';
import '../navigation/building_routing.dart';
import '../navigation/map_repository.dart';
import '../navigation/interactive_floor_map.dart';
import 'app_state.dart';
import 'explore_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';
import 'navigation_session.dart';
import 'shared_widgets.dart';
import 'route_planner_screen.dart';
import 'manual_route_steps.dart';

enum ShellTab { explore, contribute, profile }

class MadMapsShell extends StatefulWidget {
  const MadMapsShell({super.key, required this.state, this.repository});
  final AppState state;
  final MapRepository? repository;
  @override
  State<MadMapsShell> createState() => _MadMapsShellState();
}

class _MadMapsShellState extends State<MadMapsShell>
    with WidgetsBindingObserver {
  late final repository = widget.repository ?? ServerMapRepository();
  final session = NavigationSession();
  final mapNavigator = GlobalKey<NavigatorState>();
  final viewport = FloorViewportController();
  final tts = FlutterTts();
  FloorGraph? graph;
  Map<int, FloorGraph> floors = {};
  int displayedFloor = 1;
  List<api.FloorConnector> connectors = [];
  String? connectorError;
  int loadGeneration = 0;
  @override
  void reassemble() {
    super.reassemble();
    if (widget.repository == null && reconnectClient()) {
      (repository as ServerMapRepository).invalidate();
      unawaited(load());
    }
  }

  String? selectedPlace;
  String? error;
  ShellTab tab = ShellTab.explore;
  bool opening = false;
  String? lastAnnouncement;
  int spokenRevision = -1;
  int speechGeneration = 0;
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    session.addListener(sessionChanged);
    widget.state.addListener(preferencesChanged);
    load();
  }

  Future<void> load() async {
    final generation = ++loadGeneration;
    try {
      final source = repository;
      final loaded = source is MultiFloorMapRepository
          ? await source.loadFloors()
          : {1: await source.load()};
      final result = loaded[1]!;
      var catalog = <api.FloorConnector>[];
      String? issue;
      if (source is ServerMapRepository) {
        try {
          catalog = await (await source.connection).buildingMap
              .listConnectors('morgridge-hall')
              .timeout(const Duration(seconds: 12));
        } catch (e) {
          issue = 'Cross-floor connections unavailable: $e';
        }
      }
      if (!mounted || generation != loadGeneration) return;
      session.updateMaps(loaded, catalog);
      viewport.overview();
      if (mounted) {
        setState(() {
          graph = result;
          floors = loaded;
          connectors = catalog;
          connectorError = issue;
          error = null;
        });
      }
    } catch (e) {
      if (mounted && generation == loadGeneration)
        setState(() => error = 'Could not load destinations: $e');
    }
  }

  void sessionChanged() {
    if (!mounted) return;
    setState(() {});
    announce();
  }

  void preferencesChanged() {
    if (!widget.state.voice) {
      unawaited(stopSpeech());
      lastAnnouncement = null;
    } else {
      announce();
    }
  }

  void announce() {
    if (!foreground || !widget.state.voice || session.destination == null) {
      if (lastAnnouncement != null) unawaited(stopSpeech());
      lastAnnouncement = null;
      return;
    }
    final instruction = session.instruction;
    if (lastAnnouncement == instruction && spokenRevision == session.revision) {
      return;
    }
    lastAnnouncement = instruction;
    spokenRevision = session.revision;
    unawaited(speak(instruction, ++speechGeneration));
  }

  Future<void> stopSpeech() async {
    speechGeneration++;
    try {
      await tts.stop();
    } catch (_) {
      /* Text guidance remains available. */
    }
  }

  Future<void> speak(String instruction, int generation) async {
    try {
      await tts.stop();
      if (mounted &&
          foreground &&
          widget.state.voice &&
          lastAnnouncement == instruction &&
          generation == speechGeneration) {
        await tts.speak(instruction);
      }
    } catch (_) {
      /* Visible instructions remain available if speech is unavailable. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (!foreground) {
      unawaited(stopSpeech());
      lastAnnouncement = null;
    } else {
      announce();
    }
  }

  FloorLocation? previewPlace, previewStart;
  bool previewDirections = false;
  bool manualGuidance = false;
  int manualStepIndex = 0;

  List<ManualRouteStep> get previewSteps {
    final route = previewRoute;
    return route == null
        ? []
        : manualRouteSteps(
            route,
            floors,
            widget.state.label(previewPlace!),
            widget.state.distance,
          );
  }

  List<Offset> get previewPath {
    final route = previewRoute;
    if (route == null) return const [];
    final steps = previewSteps;
    final selectedStep = manualGuidance && steps.isNotEmpty
        ? steps[manualStepIndex.clamp(0, steps.length - 1)]
        : null;
    return [
      for (var i = 0; i < route.legs.length; i++)
        if (route.legs[i].floor == displayedFloor)
          ...route.legs[i].points.sublist(
            selectedStep != null && selectedStep.legIndex == i
                ? selectedStep.pointIndex
                : 0,
          ),
    ];
  }

  void advanceManualStep(int index) {
    final route = previewRoute;
    final steps = previewSteps;
    if (route == null || index < 0 || index >= steps.length) return;
    setState(() {
      manualStepIndex = index;
      displayedFloor = route.legs[steps[index].legIndex].floor;
    });
    viewport.overview();
  }

  void startLiveGuidance() {
    session.choose(previewPlace!);
    setState(() {
      previewPlace = null;
      previewStart = null;
      previewDirections = false;
      manualGuidance = false;
      manualStepIndex = 0;
    });
    unawaited(openSession());
  }

  BuildingRoute? get previewRoute {
    final start = previewStart, end = previewPlace;
    if (!previewDirections ||
        start == null ||
        end == null ||
        start.node == null)
      return null;
    final g = floors[start.floor]!;
    return planBuildingRoute(
      floors: floors,
      connectors: connectors,
      startFloor: start.floor,
      start: g.nodes[start.node]!.point,
      startNode: start.node,
      destination: end,
      avoidStairs: session.avoidStairs,
      travelMode: session.travelMode,
    );
  }

  void choose(FloorLocation place) => selectPreview(place, directions: true);

  void selectPreview(FloorLocation place, {bool directions = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      displayedFloor = place.floor;
      selectedPlace = place.id;
      previewPlace = place;
      previewStart = null;
      manualGuidance = false;
      manualStepIndex = 0;
      previewDirections = directions;
      tab = ShellTab.explore;
    });
    viewport.overview();
  }

  void closePreview() {
    setState(() {
      previewPlace = null;
      previewStart = null;
      previewDirections = false;
      manualGuidance = false;
      manualStepIndex = 0;
      selectedPlace = null;
    });
    viewport.overview();
  }

  Future<void> pickPreviewStart() async {
    final place = await pickRoutePlace(
      context,
      floors.values.expand((g) => g.locations).toList(),
      'Choose start',
    );
    if (!mounted || place == null) return;
    setState(() {
      previewStart = place;
      manualGuidance = false;
      manualStepIndex = 0;
      displayedFloor = place.floor;
    });
    viewport.overview();
  }

  Widget previewHeader() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        dense: true,
        leading: const Icon(Icons.my_location, color: routeCobalt),
        title: Text(
          previewStart == null
              ? 'Your location'
              : widget.state.label(previewStart!),
        ),
        subtitle: const Text('Choose starting point'),
        onTap: pickPreviewStart,
        trailing: IconButton(
          tooltip: 'Close directions',
          onPressed: closePreview,
          icon: const Icon(Icons.close),
        ),
      ),
      const Divider(height: 1, indent: 56),
      ListTile(
        dense: true,
        leading: const Icon(Icons.place, color: brandCrimson),
        title: Text(widget.state.label(previewPlace!)),
        subtitle: Text(previewPlace!.floorLabel),
      ),
    ],
  );

  Widget previewControls() {
    final place = previewPlace!;
    final route = previewRoute;
    final steps = previewSteps;
    final stepIndex = steps.isEmpty
        ? 0
        : manualStepIndex.clamp(0, steps.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                previewDirections ? 'Walking directions' : place.floorLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Close place',
              onPressed: closePreview,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        if (!previewDirections) ...[
          TextButton.icon(
            onPressed: () => widget.state.toggleSaved(place.id),
            icon: Icon(
              widget.state.saved.contains(place.id)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
            label: Text(
              widget.state.saved.contains(place.id)
                  ? 'Remove saved place'
                  : 'Save place',
            ),
          ),
          FilledButton.icon(
            onPressed: place.node == null
                ? null
                : () {
                    setState(() => previewDirections = true);
                    viewport.overview();
                  },
            icon: const Icon(Icons.directions_walk),
            label: const Text('Navigate'),
          ),
          if (place.node == null)
            const Text('This destination has no mapped entrance yet.'),
        ] else ...[
          if (!manualGuidance)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Avoid stairs'),
              value: session.avoidStairs,
              onChanged: (value) {
                manualGuidance = false;
                manualStepIndex = 0;
                session.setAvoidStairs(value);
                viewport.overview();
              },
            ),
          if (!manualGuidance)
            FloorTravelPicker(
              value: session.travelMode,
              avoidStairs: session.avoidStairs,
              onChanged: (value) {
                manualGuidance = false;
                manualStepIndex = 0;
                session.setTravelMode(value);
                viewport.overview();
              },
            ),
          if (previewStart == null)
            const Text(
              'Find your location to start live guidance, or choose a starting point above to preview a route.',
            )
          else if (route == null)
            const Text(
              'No connected route is available with these preferences.',
            )
          else ...[
            Text(
              '${widget.state.distance(route.meters)} - about ${(route.seconds / 60).ceil()} min (estimated)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (manualGuidance && steps.isNotEmpty)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Step ${stepIndex + 1} of ${steps.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[stepIndex].instruction,
                        key: const ValueKey('manual-instruction'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            key: const ValueKey('inline-previous-step'),
                            tooltip: 'Previous step',
                            onPressed: stepIndex == 0
                                ? null
                                : () => advanceManualStep(stepIndex - 1),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          IconButton(
                            key: const ValueKey('inline-next-step'),
                            tooltip: 'Next step',
                            onPressed: stepIndex == steps.length - 1
                                ? null
                                : () => advanceManualStep(stepIndex + 1),
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const Text(
              'Follow these steps manually. Your location and arrival are not tracked.',
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: opening || (previewStart != null && route == null)
                ? null
                : () {
                    if (previewStart == null) {
                      startLiveGuidance();
                      return;
                    }
                    if (manualGuidance) {
                      closePreview();
                      return;
                    }
                    setState(() => manualGuidance = true);
                    advanceManualStep(0);
                  },
            icon: const Icon(Icons.navigation_outlined),
            label: Text(
              opening
                  ? 'Opening...'
                  : previewStart == null
                  ? 'Start'
                  : manualGuidance
                  ? 'Finish directions'
                  : 'Start step-by-step',
            ),
          ),
          if (manualGuidance)
            TextButton(
              onPressed: () => setState(() {
                manualGuidance = false;
                manualStepIndex = 0;
              }),
              child: const Text('Route options'),
            ),
          if (previewStart != null)
            TextButton.icon(
              onPressed: opening ? null : startLiveGuidance,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Use live guidance'),
            ),
        ],
      ],
    );
  }

  Future<void> openTools() async {
    setState(() => tab = ShellTab.contribute);
  }

  Future<void> openSession() async {
    if (opening || session.attached) return;
    setState(() {
      opening = true;
      tab = ShellTab.explore;
    });
    try {
      final store = MapStore();
      final local = await store.load();
      final shared = repository is ServerMapRepository
          ? await SharedCaptures().load(floors)
          : <AnchorMap>[];
      final maps = await SharedCaptures().navigationMaps(local, shared);
      if (!mounted) return;
      final usable = maps.where((m) => m.floor.calibration(m) != null).toList();
      if (usable.isEmpty) {
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Scan a floor to enable live guidance',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text(
                    'Choose a floor in Contribute and capture two known points, or download shared scans. Your destination will stay selected.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(sheet);
                      unawaited(openTools());
                    },
                    child: const Text('Open mapping tools'),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }
      setState(() => displayedFloor = 1);
      await mapNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => MapSessionScreen(
            map: usable.length == 1 ? usable.single : null,
            maps: usable,
            save: () => store.save(local),
            session: session,
            appState: widget.state,
            graph: graph,
            floors: floors,
            connectors: connectors,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open navigation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Widget tripControls() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (displayedFloor != 1)
        TextButton.icon(
          onPressed: () => setState(() => displayedFloor = 1),
          icon: const Icon(Icons.navigation_outlined),
          label: const Text('Return to navigation'),
        ),
      Text(
        session.destination == null
            ? 'Explore Morgridge Hall'
            : widget.state.label(session.destination!),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(
        connectorError ??
            'Locate with shared or saved AR anchors to start live guidance.',
      ),
      const SizedBox(height: 12),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Avoid stairs'),
        secondary: PopupMenuButton<FloorTravelMode>(
          tooltip: 'Between floors',
          enabled: !session.avoidStairs,
          initialValue: session.travelMode,
          icon: Icon(
            session.avoidStairs ||
                    session.travelMode == FloorTravelMode.elevator
                ? Icons.elevator
                : Icons.stairs,
          ),
          onSelected: session.setTravelMode,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: FloorTravelMode.elevator,
              child: Text('Elevator'),
            ),
            PopupMenuItem(
              value: FloorTravelMode.stairs,
              child: Text('Stairs'),
            ),
          ],
        ),
        value: session.avoidStairs,
        onChanged: session.setAvoidStairs,
      ),
      FilledButton.icon(
        onPressed: opening ? null : openSession,
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(
          opening ? 'Opening...' : 'Find my location',
        ),
      ),
      if (session.destination != null)
        TextButton(
          onPressed: session.cancel,
          child: Text(session.arrived ? 'Finish' : 'Cancel'),
        ),
    ],
  );

  Widget mapLanding() => ExploreScreen(
    key: ValueKey(clientRevision.value),
    repository: repository,
    places: floors.values.expand((g) => g.locations).toList(),
    state: widget.state,
    floors: floors,
    displayedFloor: displayedFloor,
    selectedPlace: selectedPlace,
    viewport: viewport,
    onChoose: selectPreview,
    onFloor: (floor) {
      setState(() {
        displayedFloor = floor;
        selectedPlace = null;
      });
      viewport.overview();
    },
    onLocate: opening ? null : openSession,
    tripControls: previewPlace != null
        ? previewControls()
        : session.destination == null
        ? null
        : tripControls(),
    panelTitle: previewPlace == null ? null : widget.state.label(previewPlace!),
    directionsHeader: previewDirections && previewPlace != null
        ? previewHeader()
        : null,
    onDismissPlace: previewPlace == null ? null : closePreview,
    previewPath: previewPath,
    previewPosition: manualGuidance && previewPath.isNotEmpty
        ? previewPath.first
        : null,
    connectorError: connectorError,
  );

  @override
  Widget build(BuildContext context) {
    final places = floors.values.expand((g) => g.locations).toList();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!),
                    TextButton(onPressed: load, child: const Text('Retry')),
                  ],
                ),
              )
            : graph == null
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: tab.index,
                children: [
                  NavigatorPopHandler<void>(
                    enabled: tab == ShellTab.explore,
                    onPopWithResult: (_) =>
                        mapNavigator.currentState!.maybePop(),
                    child: Navigator(
                      key: mapNavigator,
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (_) => AnimatedBuilder(
                          animation: Listenable.merge([widget.state, session]),
                          builder: (_, _) => mapLanding(),
                        ),
                      ),
                    ),
                  ),
                  tab == ShellTab.contribute
                      ? CaptureHome(floors: floors)
                      : const SizedBox.shrink(),
                  ProfileScreen(
                    state: widget.state,
                    onTools: openTools,
                    saved: SavedScreen(
                      places: places,
                      state: widget.state,
                      onChoose: (place) {
                        Navigator.pop(context);
                        choose(place);
                      },
                      displayedFloor: displayedFloor,
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.state.storageError != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(widget.state.storageError!),
            ),
          if (session.destination != null && tab != ShellTab.explore)
            Material(
              color: const Color(0xffe8f1f7),
              child: ListTile(
                leading: const Icon(Icons.directions_walk, color: routeCobalt),
                title: Text(session.instruction, maxLines: 2),
                subtitle: Text(
                  '${widget.state.label(session.destination!)}${session.remainingMeters == null ? '' : ' - ${widget.state.distance(session.remainingMeters!)} remaining'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() {
                  tab = ShellTab.explore;
                  displayedFloor = 1;
                }),
              ),
            ),
          NavigationBar(
            selectedIndex: tab.index,
            onDestinationSelected: (v) =>
                setState(() => tab = ShellTab.values[v]),
            backgroundColor: Colors.white,
            indicatorColor: brandCrimson.withValues(alpha: .1),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore, color: brandCrimson),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: brandCrimson),
                label: 'Contribute',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: brandCrimson),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.state.removeListener(preferencesChanged);
    session.removeListener(sessionChanged);
    session.dispose();
    viewport.dispose();
    unawaited(stopSpeech());
    super.dispose();
  }
}
