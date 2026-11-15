import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../localization/map_data.dart';
import '../localization/prototype_screen.dart';
import '../navigation/floor_data.dart';
import '../navigation/map_repository.dart';
import '../navigation/interactive_floor_map.dart';
import 'app_state.dart';
import 'home_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';
import 'navigation_session.dart';
import 'shared_widgets.dart';

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
  String? selectedPlace;
  String? error;
  int tab = 0;
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
    try {
      final source = repository;
      final loaded = source is MultiFloorMapRepository
          ? await source.loadFloors()
          : {1: await source.load()};
      final result = loaded[1]!;
      if (mounted) {
        setState(() {
          graph = result;
          floors = loaded;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Could not load destinations: $e');
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

  void choose(FloorLocation place) {
    setState(() {
      displayedFloor = place.floor;
      selectedPlace = place.id;
      tab = 1;
    });
    viewport.overview();
    if (place.floor != 1) return;
    session.choose(place);
    setState(() => tab = 1);
    if (!session.attached) unawaited(openSession());
  }

  Future<void> openTools() async {
    setState(() => tab = 1);
    if (session.attached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Use Mapping tools and Floor 1 setup in the active map toolbar. Back closes the session to manage maps.',
          ),
        ),
      );
      return;
    }
    await mapNavigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => MapsScreen(graph: graph!)),
    );
    if (mounted) setState(() {});
  }

  Future<void> openSession() async {
    if (opening || session.attached) return;
    setState(() {
      opening = true;
      tab = 1;
    });
    try {
      final store = MapStore();
      final maps = await store.load();
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
                    'Set up Floor 1',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text(
                    'Create or open an AR map, save two anchors, then calibrate them in Floor 1 setup. Your destination will stay selected.',
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
      await mapNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => MapSessionScreen(
            map: usable.length == 1 ? usable.single : null,
            maps: usable,
            save: () => store.save(maps),
            session: session,
            appState: widget.state,
            graph: graph,
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

  Widget mapLanding([int floorNumber = 1]) {
    final g = floors[floorNumber];
    if (g == null) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Morgridge Hall',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Chip(label: Text(g.floorLabel)),
              IconButton(
                tooltip: 'Map help',
                icon: const Icon(Icons.help_outline),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tap a room or marker for details. Pinch to zoom and rotate; drag to pan.',
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Show whole floor',
                icon: const Icon(Icons.center_focus_strong),
                onPressed: viewport.overview,
              ),
              IconButton(
                tooltip: 'Mapping tools',
                onPressed: openTools,
                icon: const Icon(Icons.edit_location_alt_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveFloorMap(
            key: ValueKey(g.floor),
            graph: g,
            selectedLocation: selectedPlace,
            highContrast: widget.state.contrast,
            setup: FloorSetup(),
            controller: viewport,
            position: null,
            heading: null,
            route: const [],
            fullRoute: const [],
            onLocation: (place) {
              setState(() => selectedPlace = place.id);
              showPlaceDetails(
                context,
                place,
                widget.state,
                () => choose(place),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Card(
              key: ValueKey('$floorNumber-${session.destination?.id}'),
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      floorNumber != 1 || session.destination == null
                          ? 'Explore ${g.floorLabel}'
                          : widget.state.label(session.destination!),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      floorNumber == 1
                          ? 'Locate with saved AR anchors to start live guidance.'
                          : 'Navigation available on Floor 1 only',
                    ),
                    const SizedBox(height: 12),
                    if (floorNumber == 1)
                      FilledButton.icon(
                        onPressed: opening ? null : openSession,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(
                          opening ? 'Opening...' : 'Find my location',
                        ),
                      ),
                    if (floorNumber == 1 && session.destination != null)
                      TextButton(
                        onPressed: session.cancel,
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = floors.values.expand((g) => g.locations).toList();
    return Scaffold(
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
                index: tab,
                children: [
                  HomeScreen(
                    repository: repository,
                    places: places,
                    state: widget.state,
                    onChoose: choose,
                    onMap: () => setState(() => tab = 1),
                    onProfile: () => setState(() => tab = 3),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text('Floor: '),
                            DropdownButton<int>(
                              value: displayedFloor,
                              items: [
                                for (final f in [0, 1, 2, 3])
                                  if (floors.containsKey(f))
                                    DropdownMenuItem(
                                      value: f,
                                      child: Text(floors[f]!.floorLabel),
                                    ),
                              ],
                              onChanged: (f) {
                                if (f != null) {
                                  setState(() {
                                    displayedFloor = f;
                                    selectedPlace = null;
                                  });
                                  viewport.overview();
                                }
                              },
                            ),
                            const Spacer(),
                            if (session.destination != null &&
                                displayedFloor != 1)
                              TextButton(
                                onPressed: () =>
                                    setState(() => displayedFloor = 1),
                                child: const Text('Return to navigation'),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: displayedFloor == 1 ? 0 : 1,
                          children: [
                            NavigatorPopHandler<void>(
                              enabled: tab == 1 && displayedFloor == 1,
                              onPopWithResult: (_) =>
                                  mapNavigator.currentState!.pop(),
                              child: Navigator(
                                key: mapNavigator,
                                onGenerateRoute: (_) => MaterialPageRoute<void>(
                                  builder: (_) => AnimatedBuilder(
                                    animation: Listenable.merge([
                                      widget.state,
                                      session,
                                    ]),
                                    builder: (_, _) => mapLanding(),
                                  ),
                                ),
                              ),
                            ),
                            if (displayedFloor != 1)
                              mapLanding(displayedFloor)
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SavedScreen(
                    places: places,
                    state: widget.state,
                    onChoose: choose,
                    displayedFloor: displayedFloor,
                  ),
                  ProfileScreen(state: widget.state, onTools: openTools),
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
          if (session.destination != null && tab != 1)
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
                  tab = 1;
                  displayedFloor = 1;
                }),
              ),
            ),
          NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (v) => setState(() => tab = v),
            backgroundColor: Colors.white,
            indicatorColor: brandCrimson.withValues(alpha: .1),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: brandCrimson),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map, color: brandCrimson),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border),
                selectedIcon: Icon(Icons.bookmark, color: brandCrimson),
                label: 'Saved',
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
