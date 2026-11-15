import 'package:flutter/material.dart';
import 'features/localization/capture_screen.dart';

/// flutter run -t lib/mapper.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'MadMaps Mapper',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xffc5050c),
      ),
      home: const CaptureHome(),
    ),
  );
}
