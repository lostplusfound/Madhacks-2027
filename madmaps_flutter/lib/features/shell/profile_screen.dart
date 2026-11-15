import 'package:flutter/material.dart';
import 'app_state.dart';
import 'shared_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state, required this.onTools});
  final AppState state;
  final VoidCallback onTools;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SectionHeading('Your preferences'),
      const Text('Preferences and saved places stay on this phone.'),
      const SizedBox(height: 20),
      SwitchListTile(
        title: const Text('High contrast'),
        subtitle: const Text('Stronger controls and text contrast'),
        value: state.contrast,
        onChanged: state.setContrast,
      ),
      SwitchListTile(
        title: const Text('Spoken directions'),
        subtitle: const Text('Read live navigation instructions aloud'),
        value: state.voice,
        onChanged: state.setVoice,
      ),
      SwitchListTile(
        title: const Text('Use feet'),
        subtitle: const Text('Show distances in feet instead of meters'),
        value: state.feet,
        onChanged: state.setFeet,
      ),
      const SectionHeading('Mapping tools'),
      ListTile(
        leading: const Icon(Icons.edit_location_alt_outlined),
        title: const Text('Manage AR maps and calibration'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTools,
      ),
      const SectionHeading('About this prototype'),
      const EmptyCard(
        'Live navigation supports Floor 1. Hallway geometry and walking estimates are draft. Camera access and saved Cloud Anchors are required for localization. Accessibility of routes has not been verified.',
      ),
    ],
  );
}
