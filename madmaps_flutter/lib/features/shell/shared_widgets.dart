import 'package:flutter/material.dart';
import '../navigation/floor_data.dart';
import 'app_state.dart';

const brandCrimson = Color(0xffc5050c);
const alabaster = Color(0xfff5f6f7);
const badgerDarkRed = Color(0xff9b0000);
const badgerInk = Color(0xff121212);
const badgerGray = Color(0xffe1e5e7);

ThemeData madMapsTheme({bool highContrast = false}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandCrimson,
    primary: highContrast ? badgerDarkRed : brandCrimson,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: badgerInk,
    contrastLevel: highContrast ? 1 : 0,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'RedHatText',
  );
  final text = base.textTheme;
  TextStyle? heading(TextStyle? style) =>
      style?.copyWith(fontFamily: 'RedHatDisplay', fontWeight: FontWeight.w800);
  return base.copyWith(
    scaffoldBackgroundColor: alabaster,
    textTheme: text.copyWith(
      headlineLarge: heading(text.headlineLarge),
      headlineMedium: heading(text.headlineMedium),
      headlineSmall: heading(text.headlineSmall),
      titleLarge: heading(text.titleLarge),
      titleMedium: heading(text.titleMedium),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: badgerInk,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: highContrast ? badgerInk : badgerGray),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: badgerGray),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xffffe9ea),
      side: BorderSide(color: highContrast ? badgerInk : badgerGray),
      shape: const StadiumBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

const routeCobalt = Color(0xff1769aa);

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.topPadding = 24});
  final String title;
  final double topPadding;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: topPadding, bottom: 10),
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
            : '${place.floorLabel} - Navigate to entrance',
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
              onPressed: place.node == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      navigate();
                    },
              icon: const Icon(Icons.directions_walk),
              label: const Text('Navigate'),
            ),
            if (place.node == null)
              const Text('This destination has no mapped entrance yet.'),
          ],
        ),
      ),
    ),
  ),
);
