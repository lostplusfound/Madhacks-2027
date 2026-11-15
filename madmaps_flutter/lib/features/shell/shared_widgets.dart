import 'package:flutter/material.dart';
import '../navigation/floor_data.dart';
import 'app_state.dart';

const brandCrimson = Color(0xffc5050c);
const alabaster = Color(0xfff6f4f0);
const routeCobalt = Color(0xff1769aa);

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class PlaceTile extends StatelessWidget {
  const PlaceTile({
    super.key,
    required this.place,
    required this.state,
    required this.onChoose,
    this.onRename,
    this.showDetails = false,
  });
  final bool showDetails;
  final FloorLocation place;
  final AppState state;
  final VoidCallback onChoose;
  final VoidCallback? onRename;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xfff8e7e9),
        child: Icon(Icons.place_outlined, color: brandCrimson),
      ),
      title: Text(state.label(place)),
      subtitle: Text(
        place.node == null
            ? '${place.floorLabel} - Not mapped yet'
            : place.floor != 1
            ? '${place.floorLabel} - View on map'
            : 'Floor 1 - Navigate to entrance',
      ),
      onTap: showDetails
          ? () => showPlaceDetails(context, place, state, onChoose)
          : onChoose,
      onLongPress: onRename,
      trailing: IconButton(
        tooltip: state.saved.contains(place.id)
            ? 'Remove saved place'
            : 'Save place',
        icon: Icon(
          state.saved.contains(place.id)
              ? Icons.bookmark
              : Icons.bookmark_border,
        ),
        onPressed: () => state.toggleSaved(place.id),
      ),
    ),
  );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}

Future<void> showPlaceDetails(
  BuildContext context,
  FloorLocation place,
  AppState state,
  VoidCallback navigate,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.label(place),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('${place.floorLabel} - Draft floor plan'),
            if (place.floor != 1)
              const Text('Navigation available on Floor 1 only'),
            StatefulBuilder(
              builder: (context, refresh) => TextButton.icon(
                onPressed: () {
                  state.toggleSaved(place.id);
                  refresh(() {});
                },
                icon: Icon(
                  state.saved.contains(place.id)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                label: Text(
                  state.saved.contains(place.id)
                      ? 'Remove saved place'
                      : 'Save place',
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: place.floor == 1 && place.node == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      navigate();
                    },
              icon: Icon(
                place.floor == 1 ? Icons.directions_walk : Icons.map_outlined,
              ),
              label: Text(place.floor == 1 ? 'Navigate' : 'View on map'),
            ),
            if (place.node == null)
              const Text('This destination has no mapped entrance yet.'),
          ],
        ),
      ),
    ),
  ),
);

class QuickAccessCard extends StatelessWidget {
  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}
