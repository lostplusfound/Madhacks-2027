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
  });
  final List<FloorLocation> places;
  final AppState state;
  final ValueChanged<FloorLocation> onChoose;
  @override
  Widget build(BuildContext context) {
    final saved = places.where((p) => state.saved.contains(p.id)).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeading('Saved places'),
        const Text(
          'Your shortcuts around Morgridge Hall. Hold a place to rename it.',
        ),
        if (saved.isEmpty)
          const EmptyCard('Save a destination using its bookmark button.'),
        for (final place in saved)
          PlaceTile(
            place: place,
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
