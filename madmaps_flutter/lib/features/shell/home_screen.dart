import 'dart:async';
import 'package:flutter/material.dart';
import '../navigation/map_repository.dart';
import '../navigation/floor_data.dart';
import 'app_state.dart';
import 'shared_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.places,
    required this.repository,
    required this.state,
    required this.onChoose,
    required this.onMap,
    required this.onProfile,
  });
  final List<FloorLocation> places;
  final MapRepository repository;
  final AppState state;
  final ValueChanged<FloorLocation> onChoose;
  final VoidCallback onMap, onProfile;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final search = TextEditingController();
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
  void dispose() {
    debounce?.cancel();
    generation++;
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final byId = {for (final p in widget.places) p.id: p};
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
        PlaceTile(place: p, state: state, onChoose: () => widget.onChoose(p));
    List<Widget> group(List<String> ids) => [
      for (final id in ids.take(4))
        for (final p in widget.places.where((p) => p.id == id)) tile(p),
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
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
                    ),
                  ),
                  Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: widget.onProfile,
              tooltip: 'Profile',
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Where are you headed?',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text('Find your way around Morgridge Hall.'),
        const SizedBox(height: 24),
        TextField(
          controller: search,
          onSubmitted: (_) {
            if (!searching && results.isNotEmpty)
              widget.onChoose(results.first);
          },
          onChanged: (v) => updateSearch(v),
          decoration: InputDecoration(
            hintText: 'Search room or destination',
            prefixIcon: const Icon(Icons.search, color: brandCrimson),
            suffixIcon: query.isEmpty && category == null
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () => searchFor(''),
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        if (query.isNotEmpty || category != null) ...[
          const SectionHeading('Search results'),
          if (searching) const LinearProgressIndicator(),
          if (searchError != null) ...[
            Text(searchError!),
            TextButton(
              onPressed: () => updateSearch(query, filter: category),
              child: const Text('Retry'),
            ),
          ],
          if (!searching && searchError == null && results.isEmpty)
            const EmptyCard('No matching destinations.'),
          ...results.map(tile),
        ] else ...[
          const SectionHeading('Quick access'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in widget.repository.categories)
                SizedBox(
                  width: 155,
                  child: QuickAccessCard(
                    icon: switch (c) {
                      'bathroom' => Icons.wc_rounded,
                      'exit' => Icons.exit_to_app_rounded,
                      'elevator' => Icons.elevator_outlined,
                      _ => Icons.menu_book_outlined,
                    },
                    title: switch (c) {
                      'bathroom' => 'Bathrooms',
                      'exit' => 'Exits',
                      'elevator' => 'Elevators',
                      _ => 'Study spaces',
                    },
                    subtitle: 'Floor 1 destinations',
                    onTap: () => searchFor('', filter: c),
                  ),
                ),
            ],
          ),
          FilledButton.tonalIcon(
            onPressed: widget.onMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Explore Floor 1'),
          ),
          if (state.saved.isNotEmpty) ...[
            const SectionHeading('Saved places'),
            ...group(state.saved.toList()),
          ],
          if (state.recent.isNotEmpty) ...[
            const SectionHeading('Recently visited'),
            ...group(state.recent),
          ],
          if (state.frequent.isNotEmpty) ...[
            const SectionHeading('Frequently visited'),
            ...group(state.frequent),
          ],
          const SectionHeading('Explore destinations'),
          ...widget.places.map(tile),
        ],
      ],
    );
  }
}
