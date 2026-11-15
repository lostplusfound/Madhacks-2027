import 'package:flutter/material.dart';
import 'app_state.dart';
import 'shared_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.state,
    required this.onTools,
    this.saved,
  });
  final AppState state;
  final VoidCallback onTools;
  final Widget? saved;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SectionHeading('Your preferences'),
      const Text('Preferences and saved places stay on this phone.'),
      const SizedBox(height: 20),
      if (saved != null)
        ListTile(
          leading: const Icon(Icons.bookmark_border),
          title: const Text('Saved places'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Saved places')),
                body: saved!,
              ),
            ),
          ),
        ),
      Card(
        child: SwitchListTile(
          title: const Text('High contrast'),
          subtitle: const Text('Stronger controls and text contrast'),
          value: state.contrast,
          onChanged: state.setContrast,
        ),
      ),
      Card(
        child: SwitchListTile(
          title: const Text('Spoken directions'),
          subtitle: const Text('Read live navigation instructions aloud'),
          value: state.voice,
          onChanged: state.setVoice,
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.straighten_rounded),
                title: Text('Distance units'),
                subtitle: Text('Choose how route distances are shown'),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Meters')),
                  ButtonSegment(value: true, label: Text('Feet')),
                ],
                selected: {state.feet},
                onSelectionChanged: (values) => state.setFeet(values.single),
              ),
            ],
          ),
        ),
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
        'Routes connect the Basement and Floors 1–3. Hallway geometry and walking estimates are draft. Current location requires camera access and shared or saved Cloud Anchors. Choose a named start for manual directions. Accessibility of routes has not been verified.',
      ),
    ],
  );
}
