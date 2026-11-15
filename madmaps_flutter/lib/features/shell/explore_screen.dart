import 'dart:async';
import 'package:flutter/material.dart';
import '../navigation/map_repository.dart';
import '../navigation/floor_data.dart';
import 'app_state.dart';
import '../navigation/interactive_floor_map.dart';
import 'shared_widgets.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.places,
    required this.repository,
    required this.state,
    required this.onChoose,
    required this.floors,
    required this.displayedFloor,
    required this.selectedPlace,
    required this.viewport,
    required this.onFloor,
    required this.onLocate,
    this.directionsHeader,
    this.panelTitle,
    this.onDismissPlace,
    this.previewPath = const [],
    this.previewPosition,
    this.tripControls,
    this.connectorError,
    this.selectedBuilding,
    this.onBuildingChanged,
    this.catalogError,
    this.onReloadMaps,
    this.mapContent,
  });
  final String? selectedBuilding, catalogError;
  final ValueChanged<String?>? onBuildingChanged;
  final VoidCallback? onReloadMaps;
  final Widget? mapContent;
  final List<FloorLocation> places;
  final MapRepository repository;
  final AppState state;
  final ValueChanged<FloorLocation> onChoose;
  final Map<int, FloorGraph> floors;
  final int displayedFloor;
  final String? selectedPlace, connectorError;
  final FloorViewportController viewport;
  final ValueChanged<int> onFloor;
  final VoidCallback? onLocate;
  final Widget? directionsHeader;
  final String? panelTitle;
  final VoidCallback? onDismissPlace;
  final List<Offset> previewPath;
  final Offset? previewPosition;
  final Widget? tripControls;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final search = TextEditingController();
  final sheet = DraggableScrollableController();
  double sheetSize = .22;
  void expandSheet(double size) {
    if (!sheet.isAttached) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      sheet.jumpTo(size);
    } else {
      sheet.animateTo(
        size,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String query = '';
  String? category, searchError;
  List<String>? resultIds;
  Timer? debounce;
  int generation = 0;
  bool searching = false;
  void searchFor(String value, {String? filter}) {
    search.text = value;
    updateSearch(value, filter: filter);
  }

  void updateSearch(String value, {String? filter}) {
    debounce?.cancel();
    final current = ++generation;
    setState(() {
      query = value.trim();
      category = filter;
      searchError = null;
      resultIds = null;
      searching = query.isNotEmpty || category != null;
    });
    if (!searching) return;
    expandSheet(.22);
    debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final ids = await widget.repository.search(query, category: category);
        if (mounted && current == generation)
          setState(() {
            resultIds = ids;
            searching = false;
          });
      } catch (_) {
        if (mounted && current == generation)
          setState(() {
            searching = false;
            searchError =
                'Could not reach the server. Check your connection and retry. Loaded destinations remain available.';
          });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    String signature(List<FloorLocation> places) => places
        .map((p) => '${p.id}:${p.label}:${p.buildingName}:${p.floorLabel}')
        .join('|');
    if (signature(oldWidget.places) != signature(widget.places) &&
        (query.isNotEmpty || category != null)) {
      updateSearch(query, filter: category);
    }

    if (widget.panelTitle != oldWidget.panelTitle && widget.panelTitle != null)
      searchFor('');
    if (widget.tripControls != null && oldWidget.tripControls == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) expandSheet(.5);
      });
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    generation++;
    search.dispose();
    sheet.dispose();
    super.dispose();
  }

  void selectPlace(FloorLocation place) {
    FocusManager.instance.primaryFocus?.unfocus();
    searchFor('');
    widget.onChoose(place);
    expandSheet(place.placeMapId == null ? .5 : .22);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final buildings = widget.places.map((p) => p.buildingName).toSet().toList()
      ..sort();
    final visiblePlaces = widget.places
        .where(
          (p) =>
              widget.selectedBuilding == null ||
              p.buildingName == widget.selectedBuilding,
        )
        .toList();
    final byId = {for (final p in visiblePlaces) p.id: p};
    final ids = <String>{...?resultIds};
    if (query.isNotEmpty)
      ids.addAll(
        widget.places
            .where(
              (p) =>
                  state.aliases[p.id]?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ==
                      true &&
                  (category == null ||
                      widget.repository.categoryOf(p.id) == category),
            )
            .map((p) => p.id),
      );
    final results = ids.where(byId.containsKey).map((id) => byId[id]!).toList();
    Widget tile(FloorLocation p) =>
        PlaceTile(place: p, state: state, onChoose: () => selectPlace(p));
    List<Widget> group(List<String> ids) => [
      for (final id in ids.take(4))
        for (final p in visiblePlaces.where((p) => p.id == id)) tile(p),
    ];
    final active = query.isNotEmpty || category != null;
    final floor = widget.floors[widget.displayedFloor]!;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final headerHeight =
        (keyboard > 0 ? 112.0 : 164.0) +
        (MediaQuery.textScalerOf(context).scale(16) - 16) * 4;
    return PopScope(
      canPop: sheetSize <= .23 && !active && widget.onDismissPlace == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        FocusManager.instance.primaryFocus?.unfocus();
        searchFor('');
        widget.onDismissPlace?.call();
        expandSheet(.22);
      },
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(
              top: headerHeight,
              bottom: constraints.maxHeight * sheetSize.clamp(.22, .5),
              child:
                  (widget.mapContent == null
                      ? null
                      : LayoutBuilder(
                          builder: (context, bounds) => SingleChildScrollView(
                            child: SizedBox(
                              height: bounds.maxHeight.clamp(
                                420.0,
                                double.infinity,
                              ),
                              child: widget.mapContent,
                            ),
                          ),
                        )) ??
                  InteractiveFloorMap(
                    key: ValueKey(floor.floor),
                    graph: floor,
                    setup: FloorSetup(),
                    controller: widget.viewport,
                    selectedLocation: widget.selectedPlace,
                    highContrast: state.contrast,
                    position: widget.previewPosition,
                    heading: null,
                    route: widget.previewPath,
                    fullRoute: widget.previewPath,
                    onLocation: selectPlace,
                  ),
            ),
            if (widget.mapContent == null)
              Positioned(
                top: headerHeight + 10,
                right: 16,
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: widget.displayedFloor,
                            items: [
                              for (final f
                                  in (widget.floors.values.toList()..sort(
                                    (a, b) => a.floor.compareTo(b.floor),
                                  )))
                                DropdownMenuItem(
                                  value: f.floor,
                                  child: Text(f.floorLabel),
                                ),
                            ],
                            onChanged: (f) {
                              if (f != null) widget.onFloor(f);
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Show whole floor',
                          onPressed: widget.viewport.overview,
                          icon: const Icon(Icons.center_focus_strong),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.mapContent == null && sheetSize < .5 && keyboard == 0)
              Positioned(
                right: 16,
                bottom: constraints.maxHeight * sheetSize + 12,
                child: FloatingActionButton.small(
                  heroTag: 'locate',
                  tooltip: 'Find my location',
                  onPressed: widget.onLocate,
                  child: const Icon(Icons.my_location),
                ),
              ),
            Positioned.fill(
              key: const ValueKey('explore-sheet'),
              top: keyboard > 0 ? headerHeight : 0,
              bottom: keyboard,
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (n) {
                  setState(() => sheetSize = n.extent);
                  return false;
                },
                child: DraggableScrollableSheet(
                  controller: sheet,
                  initialChildSize: .22,
                  minChildSize: .22,
                  maxChildSize: keyboard > 0
                      ? .85
                      : (1 - headerHeight / constraints.maxHeight).clamp(
                          .5,
                          .85,
                        ),
                  snap: true,
                  snapSizes: const [.22, .5],
                  builder: (context, scroll) => Material(
                    elevation: 12,
                    shadowColor: Colors.black26,
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView(
                      controller: scroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        Center(
                          child: IconButton(
                            tooltip: sheetSize < .5
                                ? 'Expand explore'
                                : 'Collapse explore',
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              expandSheet(sheetSize < .5 ? .85 : .22);
                            },
                            icon: Icon(
                              sheetSize < .5
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                          ),
                        ),
                        if (widget.panelTitle != null)
                          Text(
                            widget.panelTitle!,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        if (widget.panelTitle != null ||
                            widget.tripControls != null)
                          const SizedBox(height: 12),
                        if (buildings.length > 1)
                          DropdownButton<String>(
                            key: const Key('destination-building-filter'),
                            isExpanded: true,
                            value: widget.selectedBuilding,
                            hint: const Text('All buildings'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All buildings'),
                              ),
                              for (final name in buildings)
                                DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                ),
                            ],
                            onChanged: widget.onBuildingChanged,
                          ),
                        if (widget.tripControls != null && !active)
                          widget.tripControls!
                        else ...[
                          if (widget.catalogError != null) ...[
                            Text(widget.catalogError!),
                            TextButton(
                              onPressed: widget.onReloadMaps,
                              child: const Text('Retry uploaded maps'),
                            ),
                          ],
                          if (widget.connectorError != null)
                            Text(widget.connectorError!),
                          if (!active) ...[
                            if (state.saved.isNotEmpty) ...[
                              const SectionHeading(
                                'Saved places',
                                topPadding: 8,
                              ),
                              ...group(state.saved.toList()),
                            ],
                            if (state.recent.isNotEmpty) ...[
                              SectionHeading(
                                'Recently visited',
                                topPadding: state.saved.isEmpty ? 8 : 24,
                              ),
                              ...group(state.recent),
                            ],
                            if (state.saved.isEmpty && state.recent.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'Your saved places and recently visited destinations will appear here.',
                                ),
                              ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (keyboard == 0)
                    Row(
                      children: [
                        const Icon(
                          Icons.explore,
                          color: brandCrimson,
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'MadMaps',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: brandCrimson,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  if (widget.directionsHeader != null)
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(24),
                      child: widget.directionsHeader,
                    )
                  else
                    Material(
                      elevation: 4,
                      shadowColor: Colors.black26,
                      borderRadius: BorderRadius.circular(28),
                      clipBehavior: Clip.antiAlias,
                      child: TextField(
                        controller: search,
                        onChanged: (v) => updateSearch(v, filter: category),
                        onSubmitted: (_) {
                          if (!searching && results.isNotEmpty)
                            selectPlace(results.first);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search buildings and destinations',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: !active
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () => searchFor(''),
                                  icon: const Icon(Icons.close),
                                ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                        ),
                      ),
                    ),
                  if (active && widget.directionsHeader == null)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            (constraints.maxHeight - keyboard - headerHeight)
                                .clamp(100.0, 360.0),
                      ),
                      child: Material(
                        elevation: 6,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        clipBehavior: Clip.antiAlias,
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          children: [
                            if (searching) const LinearProgressIndicator(),
                            if (searchError != null) ...[
                              Text(searchError!),
                              TextButton(
                                onPressed: () =>
                                    updateSearch(query, filter: category),
                                child: const Text('Retry'),
                              ),
                            ],
                            if (!searching &&
                                searchError == null &&
                                results.isEmpty)
                              const EmptyCard('No matching destinations.'),
                            ...results.map(tile),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (widget.directionsHeader == null)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final c in const [
                            'bathroom',
                            'studySpace',
                            'exit',
                            'elevator',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: category == c,
                                avatar: Icon(switch (c) {
                                  'bathroom' => Icons.wc_outlined,
                                  'exit' => Icons.exit_to_app,
                                  'elevator' => Icons.elevator_outlined,
                                  _ => Icons.menu_book_outlined,
                                }, size: 18),
                                label: Text(switch (c) {
                                  'bathroom' => 'Bathrooms',
                                  'exit' => 'Exits',
                                  'elevator' => 'Elevators',
                                  _ => 'Study spaces',
                                }),
                                onSelected: (_) => updateSearch(
                                  search.text,
                                  filter: category == c ? null : c,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
