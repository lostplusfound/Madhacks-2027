import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/shell/app_state.dart';
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
  const MyApp({super.key, required this.state});
  final AppState state;
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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: alabaster,
        colorScheme: ColorScheme.fromSeed(
          seedColor: widget.state.contrast
              ? const Color(0xff005f73)
              : brandCrimson,
          contrastLevel: widget.state.contrast ? 1 : 0,
          surface: Colors.white,
        ),
        cardTheme: const CardThemeData(elevation: 0, color: Colors.white),
      ),
      home: MadMapsShell(state: widget.state),
    ),
  );
  @override
  void dispose() {
    widget.state.dispose();
    super.dispose();
  }
}
