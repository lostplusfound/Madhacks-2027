import 'package:material_ui/material_ui.dart';

import 'data/morgridge_mock_data.dart';
import 'screens/madmaps_screens.dart';
import 'state/madmaps_state.dart';

void main() => runApp(const MadMapsApp());

class MadMapsApp extends StatefulWidget {
  const MadMapsApp({super.key});

  @override
  State<MadMapsApp> createState() => _MadMapsAppState();
}

class _MadMapsAppState extends State<MadMapsApp> {
  late final MadMapsState state = MadMapsState();

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MadMaps',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: alabaster,
        colorScheme: ColorScheme.fromSeed(
          seedColor: state.highContrast
              ? const Color(0xff005f73)
              : brandCrimson,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Arial'),
          displayMedium: TextStyle(
            fontFamily: 'Arial',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: state.highContrast
              ? media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 1.18,
                    maxScaleFactor: 2.0,
                  ),
                )
              : media,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: MadMapsShell(state: state),
    ),
  );
}
