import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/shell/app_state.dart';
import 'features/navigation/map_repository.dart';
import 'features/shell/madmaps_shell.dart';
import 'features/shell/shared_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences? preferences;
  try {
    preferences = await SharedPreferences.getInstance();
  } catch (_) {
    // Browsing and in-memory preferences remain available if storage fails.
  }
  runApp(MyApp(state: AppState(preferences)));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.state, this.repository});
  final AppState state;
  final MapRepository? repository;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.state,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MadMaps',
      theme: madMapsTheme(highContrast: widget.state.contrast),
      home: MadMapsShell(state: widget.state, repository: widget.repository),
    ),
  );
  @override
  void dispose() {
    widget.state.dispose();
    super.dispose();
  }
}
