import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/morgridge_mock_data.dart';
import '../models/navigation_models.dart';
import '../state/madmaps_state.dart';
import '../widgets/floor_plan_canvas.dart';

class MadMapsShell extends StatefulWidget {
  const MadMapsShell({super.key, required this.state});
  final MadMapsState state;

  @override
  State<MadMapsShell> createState() => _MadMapsShellState();
}

class _MadMapsShellState extends State<MadMapsShell> {
  int tab = 0;

  MadMapsState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    if (state.takeArrivalNotice()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: state.highContrast
                  ? const Color(0xff005f73)
                  : brandCrimson,
              content: const Row(
                children: [
                  Icon(Icons.celebration_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'You have arrived!',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(tab),
              duration: const Duration(milliseconds: 220),
              tween: Tween(begin: .86, end: 1),
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: IndexedStack(
                index: tab,
                children: [
                  HomeScreen(
                    state: state,
                    onChoose: _chooseDestination,
                    onOpenTab: _openTab,
                  ),
                  MapScreen(
                    state: state,
                    onPlaceTap: _showPlace,
                    onCheckIn: _openCheckIn,
                    onScan: _openScanner,
                    onDescribe: _openDescription,
                    onReport: _reportIssue,
                  ),
                  SavedScreen(
                    state: state,
                    onChoose: _chooseDestination,
                    onPlaceTap: _showPlace,
                  ),
                  ProfileScreen(state: state),
                ],
              ),
            ),
            if (state.floorPromptPending)
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Material(
                  elevation: 8,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Now on floor ${state.floorPromptTarget ?? state.floor}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.nextInstruction?.contains('elevator') == true
                              ? 'Elevator transfer complete. Continue on this floor.'
                              : 'Stair transfer complete. Continue on this floor.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: state.dismissFloorPrompt,
                              child: const Text('Later'),
                            ),
                            FilledButton.tonal(
                              onPressed: () {
                                state.dismissFloorPrompt();
                                _openTab(1);
                                unawaited(_openDescription());
                              },
                              child: const Text('Describe location'),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                state.dismissFloorPrompt();
                                _openTab(1);
                                unawaited(_openScanner());
                              },
                              tooltip: 'Scan floor',
                              icon: const Icon(Icons.camera_alt_outlined),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.walkStarted) const SizedBox(height: 14),
          if (state.walkStarted)
            Material(
              color: const Color(0xffe8f1f7),
              child: InkWell(
                onTap: () => _openTab(1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.isWalking
                            ? Icons.turn_right_rounded
                            : Icons.directions_walk_rounded,
                        color: routeCobalt,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.nextInstruction ??
                                  'Arrived at ${state.destination == null ? 'destination' : state.displayName(state.destination!)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${state.destination == null ? '' : state.displayName(state.destination!)} · ${state.distanceLabel(state.remainingFeet)} remaining',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          NavigationBar(
            height: 68,
            selectedIndex: tab,
            onDestinationSelected: _openTab,
            backgroundColor: Colors.white,
            indicatorColor: brandCrimson.withValues(alpha: .1),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: brandCrimson),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded, color: brandCrimson),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border_rounded),
                selectedIcon: Icon(Icons.bookmark_rounded, color: brandCrimson),
                label: 'Saved',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: brandCrimson),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTab(int value) => setState(() => tab = value);

  Future<void> _chooseDestination(Place place) async {
    state.setDestination(place);
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    _openTab(1);
    if (state.currentLocation == null) unawaited(_openCheckIn());
  }

  Future<void> _openCheckIn() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LocationCheckInSheet(
        onCamera: () {
          Navigator.pop(sheetContext);
          unawaited(_openScanner());
        },
        onDescribe: () {
          Navigator.pop(sheetContext);
          unawaited(_openDescription());
        },
      ),
    );
  }

  Future<void> _openScanner() async {
    if (!state.cameraPromptSeen) {
      final allowed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.camera_alt_outlined,
            color: brandCrimson,
            size: 32,
          ),
          title: const Text('Use your camera?'),
          content: const Text(
            'MadMaps uses a camera check-in to estimate where you are inside the building. This demo simulates the permission and scan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: brandCrimson),
              child: const Text('Allow camera'),
            ),
          ],
        ),
      );
      if (allowed != true) {
        await state.setCameraChoice(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera demo unavailable. Describe your location to continue.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          unawaited(_openDescription());
        }
        return;
      }
      await state.setCameraChoice(true);
    } else if (!state.simulatedCameraAllowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Camera demo is turned off. Use location description instead.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final location = await showModalBottomSheet<LocationFix>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MockScannerSheet(
        resolveLocation: state.resolveDescription,
        onConfirm: (fix) => Navigator.pop(sheetContext, fix),
      ),
    );
    if (location != null && mounted) {
      state.setCurrentLocation(location);
      setState(() => tab = 1);
    }
  }

  Future<void> _openDescription() async {
    final location = await showModalBottomSheet<LocationFix>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DescribeLocationSheet(
        resolveLocation: state.resolveDescription,
        onConfirm: (fix) => Navigator.pop(sheetContext, fix),
      ),
    );
    if (location != null && mounted) {
      state.setCurrentLocation(location);
      setState(() => tab = 1);
    }
  }

  Future<void> _reportIssue() async {
    final issue = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ReportIssueSheet(
        onSubmit: (value) => Navigator.pop(sheetContext, value),
      ),
    );
    if (issue != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$issue reported · Thanks for helping others.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPlace(Place place) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PlaceDetailSheet(
        place: place,
        state: state,
        onDirections: () {
          Navigator.pop(sheetContext);
          _chooseDestination(place);
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.onChoose,
    required this.onOpenTab,
  });
  final MadMapsState state;
  final ValueChanged<Place> onChoose;
  final ValueChanged<int> onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController search = TextEditingController();
  String query = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.state.places
        .where(
          (place) =>
              query.isNotEmpty && widget.state.matchesPlace(place, query),
        )
        .toList();
    final saved = widget.state.savedPlaces
        .map(widget.state.placeByName)
        .whereType<Place>()
        .take(4)
        .toList();
    final recentNames = widget.state.recentPlaces.isNotEmpty
        ? widget.state.recentPlaces
        : seededRecentPlaces;
    final suggestedNames = <String>{
      ...recentNames,
      ...widget.state.frequentPlaces,
    }.toList();
    final suggested = suggestedNames
        .map(widget.state.placeByName)
        .whereType<Place>()
        .take(4)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: brandCrimson,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.explore_rounded, color: Colors.white),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MORGRIDGE HALL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xff65717a),
                      ),
                    ),
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => widget.onOpenTab(3),
                icon: const Icon(Icons.person_outline_rounded),
                tooltip: 'Profile',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Where are you\nheaded?',
            style: TextStyle(
              fontSize: 31,
              height: 1.08,
              fontWeight: FontWeight.w800,
              color: widget.state.highContrast ? Colors.black : deepInk,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Find a room, a study spot, or a way across Morgridge Hall.',
            style: TextStyle(
              color: Color(0xff5d6b73),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: search,
            onChanged: (value) => setState(() => query = value.trim()),
            onSubmitted: (_) {
              if (results.isNotEmpty) widget.onChoose(results.first);
            },
            decoration: InputDecoration(
              hintText: 'Search room or destination',
              prefixIcon: const Icon(Icons.search_rounded, color: brandCrimson),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        search.clear();
                        setState(() => query = '');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'No places match that search yet.',
                  style: TextStyle(color: Color(0xff65717a)),
                ),
              )
            else
              ...results
                  .take(5)
                  .map(
                    (place) => _SearchResult(
                      place: place,
                      displayName: widget.state.displayName(place),
                      onTap: () => widget.onChoose(place),
                    ),
                  ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.wc_rounded,
                  title: 'Bathrooms',
                  subtitle: 'Accessible options',
                  color: const Color(0xff31846c),
                  onTap: () => widget.onChoose(
                    widget.state.places.firstWhere(
                      (place) =>
                          place.category == 'Restroom' && place.floor == 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.exit_to_app_rounded,
                  title: 'Exits',
                  subtitle: 'Nearest way out',
                  color: loungeSlate,
                  onTap: () => widget.onChoose(
                    widget.state.places.firstWhere(
                      (place) => place.category == 'Exit',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          _SectionHeading(
            title: 'Saved Locations',
            action: 'See all',
            onAction: () => widget.onOpenTab(2),
          ),
          const SizedBox(height: 10),
          if (saved.isEmpty)
            const _EmptyCard(
              icon: Icons.bookmark_border_rounded,
              text: 'Save a place and it will appear here.',
            )
          else
            SizedBox(
              height: 105,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: saved.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _SavedMiniCard(
                  place: saved[index],
                  displayName: widget.state.displayName(saved[index]),
                  onTap: () => widget.onChoose(saved[index]),
                ),
              ),
            ),
          const SizedBox(height: 24),
          _SectionHeading(
            title: 'Suggested',
            action: 'Explore map',
            onAction: () => widget.onOpenTab(1),
          ),
          const SizedBox(height: 4),
          Text(
            widget.state.visitOrder.isEmpty
                ? 'Popular places to get started'
                : 'Based on your recent and frequent visits',
            style: const TextStyle(fontSize: 12, color: Color(0xff68747b)),
          ),
          const SizedBox(height: 8),
          for (final place in suggested)
            _SuggestionRow(
              place: place,
              displayName: widget.state.displayName(place),
              onTap: () => widget.onChoose(place),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => widget.onOpenTab(1),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open interactive floor map'),
              style: OutlinedButton.styleFrom(
                foregroundColor: deepInk,
                side: const BorderSide(color: Color(0xffd6dcda)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.state,
    required this.onPlaceTap,
    required this.onCheckIn,
    required this.onScan,
    required this.onDescribe,
    required this.onReport,
  });
  final MadMapsState state;
  final ValueChanged<Place> onPlaceTap;
  final VoidCallback onCheckIn;
  final VoidCallback onScan;
  final VoidCallback onDescribe;
  final VoidCallback onReport;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TransformationController _mapController = TransformationController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _resetMap() {
    _mapController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final onPlaceTap = widget.onPlaceTap;
    final onCheckIn = widget.onCheckIn;
    final onScan = widget.onScan;
    final onDescribe = widget.onDescribe;
    final onReport = widget.onReport;
    final route = state.isNavigating ? state.activeRoute : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final mapHeight = (availableHeight * (state.walkStarted ? .59 : .42))
            .clamp(
              state.walkStarted ? 230.0 : 155.0,
              state.walkStarted ? 520.0 : 360.0,
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.destination == null
                              ? 'MORGRIDGE HALL'
                              : 'DIRECTIONS TO ${state.destination!.room.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.3,
                            color: Color(0xff68747b),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          state.destination == null
                              ? 'Interactive map'
                              : state.displayName(state.destination!),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.isNavigating)
                    IconButton.filledTonal(
                      onPressed: onCheckIn,
                      icon: const Icon(Icons.my_location_rounded),
                      tooltip: 'Recalibrate location',
                    )
                  else
                    IconButton.filledTonal(
                      onPressed: onCheckIn,
                      icon: const Icon(Icons.my_location_rounded),
                      tooltip: 'Set current location',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Floor 1')),
                  ButtonSegment(value: 2, label: Text('Floor 2')),
                ],
                selected: {state.floor},
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onSelectionChanged: (selection) =>
                    state.setFloor(selection.first),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: mapHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: InteractiveViewer(
                          transformationController: _mapController,
                          minScale: .75,
                          maxScale: 3,
                          boundaryMargin: const EdgeInsets.all(80),
                          child: FloorPlanCanvas(
                            floor: state.floor,
                            highContrast: state.highContrast,
                            places: state.destination == null
                                ? state.places
                                : const [],
                            route: route,
                            origin: state.currentLocation,
                            destination: state.destination,
                            onPlaceTap: onPlaceTap,
                            displayName: state.displayName,
                            routeStep: state.stepIndex,
                            walking: state.isWalking,
                          ),
                        ),
                      ),
                      if (!state.walkStarted)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Material(
                            elevation: 3,
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: _resetMap,
                              icon: const Icon(
                                Icons.center_focus_strong_rounded,
                              ),
                              tooltip: 'Recenter map',
                            ),
                          ),
                        ),
                      if (!state.walkStarted)
                        Positioned(
                          left: 12,
                          top: 12,
                          child: _MapLegend(
                            highContrast: state.highContrast,
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: const Text('Select a location to view more information and set it as the destination.'),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
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
                  child: route == null
                      ? _MapBrowsePanel(
                          key: const ValueKey('browse'),
                          onCheckIn: onCheckIn,
                          state: state,
                        )
                      : _NavigationPanel(
                          key: ValueKey(
                            'route-${state.walkStarted}-${state.arrived}',
                          ),
                          state: state,
                          onScan: onScan,
                          onDescribe: onDescribe,
                          onReport: onReport,
                          onResetMap: _resetMap,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({
    super.key,
    required this.state,
    required this.onChoose,
    required this.onPlaceTap,
  });
  final MadMapsState state;
  final ValueChanged<Place> onChoose;
  final ValueChanged<Place> onPlaceTap;

  @override
  Widget build(BuildContext context) {
    final places = state.savedPlaces
        .map(state.placeByName)
        .whereType<Place>()
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SAVED PLACES',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              color: Color(0xff68747b),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Go somewhere familiar',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            '${places.length} saved ${places.length == 1 ? 'place' : 'places'} · stored on this device',
            style: const TextStyle(fontSize: 12, color: Color(0xff68747b)),
          ),
          const SizedBox(height: 16),
          if (places.isEmpty)
            const _EmptyCard(
              icon: Icons.bookmark_border_rounded,
              text:
                  'Your saved places will show up here. Open the map and bookmark a destination.',
            )
          else
            for (final place in places)
              _SavedPlaceCard(
                place: place,
                onChoose: () => onChoose(place),
                onTap: () => onPlaceTap(place),
                onRemove: () => state.removeSaved(place.name),
                displayName: state.displayName(place),
                onRename: (name) => state.renameSavedPlace(place.name, name),
              ),
          const SizedBox(height: 16),
          const Text('SUGGESTED', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: Color(0xff68747b), fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final place in state.places.where((place) => !state.savedPlaces.contains(place.name)).take(3))
            _SavedPlaceCard(
              place: place,
              displayName: state.displayName(place),
              onTap: () => onPlaceTap(place),
              onChoose: () => onChoose(place),
              onRemove: () {},
              onRename: (_) {},
              suggested: true,
            ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state});
  final MadMapsState state;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR PROFILE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.4,
            color: Color(0xff68747b),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Personal Preferences',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Set the wayfinding options that work best for you.',
          style: TextStyle(fontSize: 13, color: Color(0xff68747b)),
        ),
        const SizedBox(height: 20),
        _ProfileToggle(
          icon: Icons.accessible_forward_rounded,
          title: 'Wheelchair access',
          subtitle: 'Prefer elevators and step-free routes',
          value: state.wheelchairMode,
          onChanged: state.setWheelchairMode,
        ),
        _ProfileToggle(
          icon: Icons.visibility_off_outlined,
          title: 'Blind or low vision',
          subtitle: 'Turn on spoken directions automatically',
          value: state.blindMode,
          onChanged: state.setBlindMode,
        ),
        _ProfileToggle(
          icon: Icons.volume_up_outlined,
          title: 'Spoken directions',
          subtitle: 'Read each navigation step aloud',
          value: state.voiceGuidance,
          onChanged: state.setVoiceGuidance,
        ),
        _ProfileToggle(
          icon: Icons.contrast_rounded,
          title: 'High contrast map',
          subtitle: 'Strengthen map and text contrast',
          value: state.highContrast,
          onChanged: state.setHighContrast,
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xffe4e8e5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    color: state.useFeet ? brandCrimson : routeCobalt,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distance units',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Choose how route distances are shown',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xff68747b),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 150,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Feet')),
                        ButtonSegment(value: false, label: Text('Meters')),
                      ],
                      selected: {state.useFeet},
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? (state.useFeet ? brandCrimson : routeCobalt)
                              : const Color(0xfff1f3f1),
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? Colors.white
                              : deepInk,
                        ),
                      ),
                      onSelectionChanged: (value) =>
                          state.setUseFeet(value.first),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (state.cameraPromptSeen &&
            state.simulatedCameraAllowed &&
            !state.simulatedCameraAllowed)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffe4e8e5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.camera_alt_outlined, color: brandCrimson),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Camera check-in demo',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.cameraPromptSeen
                            ? (state.simulatedCameraAllowed
                                  ? 'Demo camera allowed'
                                  : 'Demo camera declined')
                            : 'You’ll be asked the first time you check in.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff68747b),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.cameraPromptSeen)
                  TextButton(
                    onPressed: () =>
                        state.setCameraChoice(!state.simulatedCameraAllowed),
                    child: Text(
                      state.simulatedCameraAllowed ? 'Turn off' : 'Turn on',
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class LocationCheckInSheet extends StatelessWidget {
  const LocationCheckInSheet({
    super.key,
    required this.onCamera,
    required this.onDescribe,
  });
  final VoidCallback onCamera;
  final VoidCallback onDescribe;

  @override
  Widget build(BuildContext context) => _SheetFrame(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where are you now?',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'Set your starting point to build or recalibrate the route.',
          style: TextStyle(fontSize: 12, color: Color(0xff68747b)),
        ),
        const SizedBox(height: 17),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Scan surroundings'),
            style: FilledButton.styleFrom(
              backgroundColor: brandCrimson,
              minimumSize: const Size(0, 50),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onDescribe,
            icon: const Icon(Icons.edit_location_alt_outlined),
            label: const Text('Describe where you are'),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Both options update your current location; your destination stays the one you searched for.',
          style: TextStyle(fontSize: 11, height: 1.4, color: Color(0xff68747b)),
        ),
      ],
    ),
  );
}

class MockScannerSheet extends StatefulWidget {
  const MockScannerSheet({
    super.key,
    required this.onConfirm,
    required this.resolveLocation,
  });
  final ValueChanged<LocationFix> onConfirm;
  final LocationFix Function(String) resolveLocation;

  @override
  State<MockScannerSheet> createState() => _MockScannerSheetState();
}

class _MockScannerSheetState extends State<MockScannerSheet> {
  bool analyzing = false;

  @override
  Widget build(BuildContext context) => _SheetFrame(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scan your surroundings',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'Look for a nearby room number, hallway sign, or landmark.',
          style: TextStyle(fontSize: 12, color: Color(0xff68747b)),
        ),
        const SizedBox(height: 15),
        Container(
          height: 185,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xffe7ece8),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.center_focus_strong_rounded,
                size: 88,
                color: Color(0xff91a4a0),
              ),
              Positioned(left: 14, top: 14, child: _corner(0)),
              Positioned(right: 14, top: 14, child: _corner(1)),
              Positioned(left: 14, bottom: 14, child: _corner(2)),
              Positioned(right: 14, bottom: 14, child: _corner(3)),
              Positioned(
                bottom: 12,
                child: Text(
                  analyzing
                      ? 'Analyzing nearby signage…'
                      : 'Camera preview demo',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: deepInk,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 2,
          children: [
            _DemoLocationChip(
              label: 'Main hall',
              onTap: () =>
                  widget.onConfirm(widget.resolveLocation('Main hall')),
            ),
            _DemoLocationChip(
              label: 'By elevator · 2F',
              onTap: () => widget.onConfirm(
                widget.resolveLocation('elevator second floor'),
              ),
            ),
            _DemoLocationChip(
              label: 'Near restrooms',
              onTap: () => widget.onConfirm(
                widget.resolveLocation('restroom second floor'),
              ),
            ),
            _DemoLocationChip(
              label: 'Main hall · Floor 1',
              onTap: () =>
                  widget.onConfirm(widget.resolveLocation('main hall floor 1')),
            ),
            _DemoLocationChip(
              label: 'Learning Center · Floor 2',
              onTap: () => widget.onConfirm(
                widget.resolveLocation('learning center floor 2'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: analyzing ? null : _analyze,
            icon: Icon(
              analyzing
                  ? Icons.hourglass_top_rounded
                  : Icons.camera_alt_outlined,
            ),
            label: Text(analyzing ? 'Analyzing…' : 'Capture demo scan'),
            style: FilledButton.styleFrom(
              backgroundColor: brandCrimson,
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _corner(int corner) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      border: Border(
        top: corner < 2
            ? const BorderSide(color: brandCrimson, width: 3)
            : BorderSide.none,
        bottom: corner >= 2
            ? const BorderSide(color: brandCrimson, width: 3)
            : BorderSide.none,
        left: corner.isEven
            ? const BorderSide(color: brandCrimson, width: 3)
            : BorderSide.none,
        right: corner.isOdd
            ? const BorderSide(color: brandCrimson, width: 3)
            : BorderSide.none,
      ),
    ),
  );

  Future<void> _analyze() async {
    setState(() => analyzing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted) widget.onConfirm(widget.resolveLocation('Main hall'));
  }
}

class DescribeLocationSheet extends StatefulWidget {
  const DescribeLocationSheet({
    super.key,
    required this.onConfirm,
    required this.resolveLocation,
  });
  final ValueChanged<LocationFix> onConfirm;
  final LocationFix Function(String) resolveLocation;

  @override
  State<DescribeLocationSheet> createState() => _DescribeLocationSheetState();
}

class ReportIssueSheet extends StatefulWidget {
  const ReportIssueSheet({super.key, required this.onSubmit});
  final ValueChanged<String> onSubmit;

  @override
  State<ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<ReportIssueSheet> {
  String selectedIssue = 'Bathroom out of order';
  final TextEditingController description = TextEditingController();
  bool photoAdded = false;
  bool analyzing = false;

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report an issue',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'Help others choose a clear route through the building.',
          style: TextStyle(fontSize: 12, color: Color(0xff68747b)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 2,
          children: [
            for (final issue in const [
              'Bathroom out of order',
              'Elevator out of service',
              'Hallway blocked',
              'Spill or maintenance',
              'Other',
            ])
              ChoiceChip(
                label: Text(
                  issue,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: selectedIssue == issue,
                onSelected: (_) => setState(() => selectedIssue = issue),
                selectedColor: brandCrimson.withValues(alpha: .12),
                checkmarkColor: brandCrimson,
              ),
          ],
        ),
        const SizedBox(height: 5),
        if (selectedIssue == 'Other')
          TextField(
            controller: description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Describe the issue',
              hintText: 'Tell us what needs attention',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        OutlinedButton.icon(
          onPressed: photoAdded ? null : _analyzeSample,
          icon: Icon(
            photoAdded
                ? Icons.check_circle_outline
                : Icons.add_a_photo_outlined,
            color: photoAdded ? const Color(0xff31846c) : brandCrimson,
          ),
          label: Text(
            analyzing
                ? 'Checking sample photo…'
                : photoAdded
                ? 'Sample issue photo verified'
                : 'Use sample issue photo',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                selectedIssue == 'Other' && description.text.trim().isEmpty
                ? null
                : () => widget.onSubmit(
                    selectedIssue == 'Other'
                        ? 'Other: ${description.text.trim()}'
                        : selectedIssue,
                  ),
            style: FilledButton.styleFrom(
              backgroundColor: brandCrimson,
              minimumSize: const Size(0, 48),
            ),
            child: const Text('Submit report'),
          ),
        ),
      ],
    ),
  );

  Future<void> _analyzeSample() async {
    setState(() => analyzing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        analyzing = false;
        photoAdded = true;
      });
    }
  }
}

class _DescribeLocationSheetState extends State<DescribeLocationSheet> {
  final TextEditingController description = TextEditingController();
  bool analyzing = false;

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Describe where you are',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'We’ll use your description to adjust your current position.',
          style: TextStyle(fontSize: 12, color: Color(0xff68747b)),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: description,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'By the elevator on the second floor',
            prefixIcon: const Icon(Icons.edit_location_alt_outlined),
            filled: true,
            fillColor: alabaster,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 1,
          children: [
            _DemoLocationChip(
              label: 'By the elevator · 2F',
              onTap: () => _useExample('By the elevator on the second floor'),
            ),
            _DemoLocationChip(
              label: 'Outside Learning Center',
              onTap: () => _useExample('Outside the Learning Center'),
            ),
            _DemoLocationChip(
              label: 'Near the main entrance',
              onTap: () => _useExample('Near the main entrance'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: analyzing ? null : _analyze,
            icon: Icon(
              analyzing
                  ? Icons.hourglass_top_rounded
                  : Icons.auto_awesome_rounded,
            ),
            label: Text(
              analyzing ? 'Recalibrating…' : 'Analyze and update location',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: brandCrimson,
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
      ],
    ),
  );

  void _useExample(String value) {
    description.text = value;
    _analyze();
  }

  Future<void> _analyze() async {
    if (description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Describe a nearby hallway, room, or landmark.'),
        ),
      );
      return;
    }
    setState(() => analyzing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) widget.onConfirm(widget.resolveLocation(description.text));
  }
}

class PlaceDetailSheet extends StatelessWidget {
  const PlaceDetailSheet({
    super.key,
    required this.place,
    required this.state,
    required this.onDirections,
  });
  final Place place;
  final MadMapsState state;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) => _SheetFrame(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: place.color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(place.icon, color: place.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.displayName(place),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${place.room} · Floor ${place.floor == 0 ? 'LL' : place.floor}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff68747b),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => state.toggleSaved(place),
              tooltip: state.savedPlaces.contains(place.name)
                  ? 'Remove from saved'
                  : 'Save place',
              icon: Icon(
                state.savedPlaces.contains(place.name)
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: brandCrimson,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              place.hours.status == Availability.closed
                  ? Icons.cancel_outlined
                  : place.hours.status == Availability.closingSoon
                  ? Icons.schedule_rounded
                  : Icons.check_circle_outline,
              size: 17,
              color: place.hours.status == Availability.open
                  ? routeCobalt
                  : const Color(0xffbd6500),
            ),
            const SizedBox(width: 6),
            Text(
              place.hours.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(place.subtitle, style: const TextStyle(color: Color(0xff59676e))),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_walk_rounded),
            label: const Text('Set as destination'),
            style: FilledButton.styleFrom(
              backgroundColor: brandCrimson,
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
      ],
    ),
  );
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    super.key,
    required this.state,
    required this.onScan,
    required this.onDescribe,
    required this.onReport,
    required this.onResetMap,
  });
  final MadMapsState state;
  final VoidCallback onScan;
  final VoidCallback onDescribe;
  final VoidCallback onReport;
  final VoidCallback onResetMap;

  @override
  Widget build(BuildContext context) {
    final route = state.activeRoute!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.destination?.hours.status == Availability.closed)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xfffff0dc),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'This room is currently closed. You can still view directions to it.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xff774000),
              ),
            ),
          )
        else if (state.destination?.hours.status == Availability.closingSoon)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xfffff0dc),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${state.displayName(state.destination!)} ${state.destination!.hours.label.toLowerCase()}.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xff774000),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffe3e7e3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: routeCobalt.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.turn_right_rounded, color: routeCobalt),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isWalking
                          ? 'NEXT DIRECTION · ${state.stepIndex + 1}/${route.steps.length}'
                          : state.arrived
                          ? 'ARRIVED'
                          : state.walkStarted
                          ? 'WALK PAUSED'
                          : 'ROUTE READY',
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.1,
                        color: Color(0xff68747b),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      state.nextInstruction ?? 'You have arrived',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: state.voiceGuidance && state.nextInstruction != null
                    ? () => state.speak(state.nextInstruction!)
                    : null,
                tooltip: 'Speak direction',
                icon: Icon(
                  Icons.volume_up_rounded,
                  color: state.voiceGuidance
                      ? routeCobalt
                      : const Color(0xffa8b0b1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatPill(
              icon: Icons.schedule_rounded,
              text: '${route.minutes} min',
            ),
            const SizedBox(width: 7),
            _StatPill(
              icon: Icons.straighten_rounded,
              text: state.distanceLabel(route.distanceFeet),
            ),
            const SizedBox(width: 7),
            if (route.stepFree)
              const _StatPill(
                icon: Icons.accessible_forward_rounded,
                text: 'Step-free',
              ),
          ],
        ),
        if (!state.walkStarted) ...[
          const SizedBox(height: 12),
          const Text(
            'ROUTE OPTIONS · QUICKEST FIRST',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1,
              color: Color(0xff68747b),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < state.routes.length; index++)
            _RouteOptionRow(
              option: state.routes[index],
              distanceLabel: state.distanceLabel,
              selected: index == state.routeIndex,
              onTap: () => state.selectRoute(index),
            ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: state.isWalking
                    ? state.stopWalking
                    : state.startWalking,
                icon: Icon(
                  state.isWalking
                      ? Icons.pause_rounded
                      : Icons.directions_walk_rounded,
                ),
                label: Text(
                  state.isWalking
                      ? 'Pause walk'
                      : state.walkStarted
                      ? 'Resume walk'
                      : 'Simulate walk',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: brandCrimson,
                  minimumSize: const Size(0, 46),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onScan,
              tooltip: 'Camera check-in',
              icon: const Icon(Icons.camera_alt_outlined),
            ),
          ],
        ),
        if (!state.walkStarted)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onDescribe,
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: const Text('Describe where you are'),
            ),
          ),
        if (state.walkStarted) const SizedBox(height: 14),
        if (state.walkStarted)
          OutlinedButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Report an issue'),
          ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () {
                  if (state.walkStarted) {
                    state.endNavigation();
                  } else {
                    state.clearDestination();
                  }
                  onResetMap();
                },
                child: Text(state.walkStarted ? 'End route' : 'Clear choice'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteOptionRow extends StatelessWidget {
  const _RouteOptionRow({
    required this.option,
    required this.distanceLabel,
    required this.selected,
    required this.onTap,
  });
  final RouteOption option;
  final String Function(int) distanceLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: selected ? routeCobalt.withValues(alpha: .08) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? routeCobalt.withValues(alpha: .45)
                  : const Color(0xffe3e7e3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: selected ? routeCobalt : const Color(0xff879397),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (selected)
                      const Text(
                        'Selected route',
                        style: TextStyle(fontSize: 10, color: routeCobalt),
                      ),
                  ],
                ),
              ),
              Text(
                '${option.minutes} min',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                distanceLabel(option.distanceFeet),
                style: const TextStyle(fontSize: 10, color: Color(0xff68747b)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MapBrowsePanel extends StatelessWidget {
  const _MapBrowsePanel({
    super.key,
    required this.state,
    required this.onCheckIn,
  });
  final MadMapsState state;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Explore a floor',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(
        state.currentLocation == null
            ? 'Tap any room to see details. No route is shown while browsing.'
            : 'Current location: ${state.currentLocation!.label}',
        style: const TextStyle(fontSize: 12, color: Color(0xff68747b)),
      ),
      const SizedBox(height: 12),
      if (state.currentLocation == null)
        OutlinedButton.icon(
          onPressed: onCheckIn,
          icon: const Icon(Icons.my_location_rounded),
          label: const Text('Set current location'),
          style: OutlinedButton.styleFrom(foregroundColor: deepInk),
        ),
    ],
  );
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.highContrast, required this.onTap});
  final bool highContrast;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .94),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: routeCobalt,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              highContrast ? 'High contrast' : 'Tap a room',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileToggle extends StatelessWidget {
  const _ProfileToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xffe4e8e5)),
    ),
    child: SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: brandCrimson,
      secondary: Icon(
        icon,
        color: value ? brandCrimson : const Color(0xff68747b),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Color(0xff68747b)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    ),
  );
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xffe4e8e5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xff68747b)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SearchResult extends StatelessWidget {
  const _SearchResult({
    required this.place,
    required this.displayName,
    required this.onTap,
  });
  final Place place;
  final String displayName;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
    leading: CircleAvatar(
      backgroundColor: place.color.withValues(alpha: .13),
      child: Icon(place.icon, color: place.color, size: 18),
    ),
    title: Text(
      displayName,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      '${place.room} · ${place.subtitle} · ${place.hours.label}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10),
    ),
    trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
    onTap: onTap,
  );
}

class _SavedMiniCard extends StatelessWidget {
  const _SavedMiniCard({
    required this.place,
    required this.displayName,
    required this.onTap,
  });
  final Place place;
  final String displayName;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 168,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe4e8e5)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: place.color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(place.icon, color: place.color, size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${place.room} · ${place.hours.label}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xff68747b),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.place,
    required this.displayName,
    required this.onTap,
  });
  final Place place;
  final String displayName;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: place.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(place.icon, color: place.color, size: 19),
    ),
    title: Text(
      displayName,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      '${place.room} · ${place.subtitle} · ${place.hours.label}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _SavedPlaceCard extends StatelessWidget {
  const _SavedPlaceCard({
    required this.place,
    required this.displayName,
    required this.onChoose,
    required this.onRemove,
    required this.onRename,
    this.onTap,
    this.suggested = false,
  });
  final Place place;
  final String displayName;
  final VoidCallback onChoose;
  final VoidCallback onRemove;
  final ValueChanged<String> onRename;
  final VoidCallback? onTap;
  final bool suggested;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: Color(0xffe4e8e5)),
    ),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(13, 7, 4, 7),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: place.color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(place.icon, color: place.color),
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${place.room} · ${place.subtitle} · ${place.hours.label}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!suggested) PopupMenuButton<String>(
            tooltip: 'Saved location options',
            onSelected: (value) {
              if (value == 'rename') {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _rename(context),
                );
              }
              if (value == 'remove') onRemove();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
            icon: const Icon(Icons.more_vert_rounded),
          ),
          IconButton(
            onPressed: onChoose,
            tooltip: 'Get directions',
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    ),
  );

  Future<void> _rename(BuildContext context) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _RenameSavedLocationDialog(
        initialName: displayName,
        canonicalName: place.name,
      ),
    );
    if (value != null && value.trim().isNotEmpty) onRename(value);
  }
}

class _RenameSavedLocationDialog extends StatefulWidget {
  const _RenameSavedLocationDialog({
    required this.initialName,
    required this.canonicalName,
  });
  final String initialName;
  final String canonicalName;
  @override
  State<_RenameSavedLocationDialog> createState() =>
      _RenameSavedLocationDialogState();
}

class _RenameSavedLocationDialogState
    extends State<_RenameSavedLocationDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialName,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Rename saved location'),
    content: TextField(
      controller: controller,
      autofocus: true,
      maxLength: 40,
      decoration: InputDecoration(
        labelText: 'Name',
        hintText: widget.canonicalName,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text),
        child: const Text('Save'),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      TextButton(
        onPressed: onAction,
        style: TextButton.styleFrom(
          foregroundColor: brandCrimson,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(action),
      ),
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xffe4e8e5)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xff879397)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xff68747b)),
          ),
        ),
      ],
    ),
  );
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffe4e8e5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: routeCobalt),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _DemoLocationChip extends StatelessWidget {
  const _DemoLocationChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(
      label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
    ),
    onPressed: onTap,
    visualDensity: VisualDensity.compact,
    backgroundColor: alabaster,
    side: BorderSide.none,
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffd8ddda),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    ),
  );
}

LocationFix resolveFallbackDescription(String description) {
  final text = description.toLowerCase();
  final selectedFloor =
      text.contains('floor 1') ||
          text.contains('first floor') ||
          text.contains('1f')
      ? 1
      : 2;
  if (text.contains('entrance') || text.contains('johnson')) {
    return const LocationFix(
      label: 'Main entrance',
      floor: 1,
      point: Offset(.25, .88),
    );
  }
  if (text.contains('elevator') || text.contains('lift')) {
    return LocationFix(
      label: 'By the elevator · Floor $selectedFloor',
      floor: selectedFloor,
      point: selectedFloor == 1
          ? const Offset(.48, .63)
          : const Offset(.55, .53),
    );
  }
  if (text.contains('restroom') ||
      text.contains('bathroom') ||
      text.contains('toilet')) {
    return const LocationFix(
      label: 'Near restrooms · Floor 2',
      floor: 2,
      point: Offset(.69, .53),
    );
  }
  if (text.contains('learning') ||
      text.contains('study') ||
      text.contains('2580')) {
    return const LocationFix(
      label: 'Outside the Learning Center',
      floor: 2,
      point: Offset(.47, .24),
    );
  }
  if (text.contains('first') ||
      text.contains('1f') ||
      text.contains('floor 1')) {
    return const LocationFix(
      label: 'Main corridor · Floor 1',
      floor: 1,
      point: Offset(.48, .63),
    );
  }
  if (selectedFloor == 1) {
    return const LocationFix(
      label: 'Main corridor · Floor 1',
      floor: 1,
      point: Offset(.48, .63),
    );
  }
  return const LocationFix(
    label: 'Main hall junction · Floor 2',
    floor: 2,
    point: Offset(.43, .53),
  );
}
