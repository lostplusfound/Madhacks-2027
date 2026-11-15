import 'package:flutter/material.dart';
import '../navigation/floor_data.dart';
import 'app_state.dart';
import 'shared_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.places,
    required this.state,
    required this.onChoose,
    required this.onMap,
    required this.onProfile,
  });
  final List<FloorLocation> places;
  final AppState state;
  final ValueChanged<FloorLocation> onChoose;
  final VoidCallback onMap, onProfile;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final search = TextEditingController();
  String query = '';
  void searchFor(String value) {
    search.text = value;
    setState(() => query = value);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final results = widget.places
        .where(
          (p) => '${p.label} ${p.aliases} ${p.id} ${state.label(p)}'
              .toLowerCase()
              .contains(query.toLowerCase()),
        )
        .toList();
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
            if (results.isNotEmpty) widget.onChoose(results.first);
          },
          onChanged: (v) => setState(() => query = v.trim()),
          decoration: InputDecoration(
            hintText: 'Search room or destination',
            prefixIcon: const Icon(Icons.search, color: brandCrimson),
            suffixIcon: query.isEmpty
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
        if (query.isNotEmpty) ...[
          const SectionHeading('Search results'),
          if (results.isEmpty) const EmptyCard('No matching destinations.'),
          ...results.map(tile),
        ] else ...[
          const SectionHeading('Quick access'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: QuickAccessCard(
                  icon: Icons.wc_rounded,
                  title: 'Bathrooms',
                  subtitle: 'Find a restroom',
                  onTap: () => searchFor('restroom'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: QuickAccessCard(
                  icon: Icons.exit_to_app_rounded,
                  title: 'Exits',
                  subtitle: 'Find a way out',
                  onTap: () => searchFor('exit'),
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
