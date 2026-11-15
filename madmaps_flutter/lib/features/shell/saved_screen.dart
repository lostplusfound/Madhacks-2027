import 'package:flutter/material.dart';
import 'name_dialog.dart';
import '../navigation/floor_data.dart';
import 'app_state.dart';
import 'shared_widgets.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({
    super.key,
    required this.places,
    required this.state,
    required this.onChoose,
    this.displayedFloor = 1,
  });
  final List<FloorLocation> places;
  final AppState state;
  final int displayedFloor;
  final ValueChanged<FloorLocation> onChoose;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => contents(context),
  );

  Widget contents(BuildContext context) {
    final saved = places.where((p) => state.saved.contains(p.id)).toList();
    final suggested =
        places
            .where(
              (p) => p.floor == displayedFloor && !state.saved.contains(p.id),
            )
            .toList()
          ..sort((a, b) => state.label(a).compareTo(state.label(b)));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeading('Saved places'),
        const Text(
          'Your shortcuts across buildings. Hold a place to rename it.',
        ),
        if (saved.isEmpty)
          const EmptyCard('Save a destination using its bookmark button.'),
        for (final place in saved)
          PlaceTile(
            place: place,
            showDetails: true,
            state: state,
            onChoose: () => onChoose(place),
            onRename: () async {
              final name = await askName(
                context,
                'Rename saved place',
                state.label(place),
              );
              if (name != null) state.rename(place.id, name);
            },
          ),
        if (suggested.isNotEmpty) const SectionHeading('Suggested'),
        for (final place in suggested.take(3))
          PlaceTile(
            place: place,
            showDetails: true,
            state: state,
            onChoose: () => onChoose(place),
          ),
        for (final id in state.saved.where(
          (id) => !places.any((p) => p.id == id),
        ))
          ListTile(
            title: Text(state.aliases[id] ?? id),
            subtitle: const Text('Destination no longer available'),
            trailing: IconButton(
              tooltip: 'Remove saved place',
              onPressed: () => state.toggleSaved(id),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
      ],
    );
  }
}
