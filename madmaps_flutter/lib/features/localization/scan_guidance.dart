import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'map_data.dart';

/// Movement coverage only: the pinned plugin does not expose ARCore feature quality.
class ScanGuidance {
  Vector3? _anchor;
  Vector3? _first;
  final Set<int> _sectors = {};
  double baseline = 0;
  void reset(Vector3 anchor) {
    _anchor = anchor.clone();
    _first = null;
    _sectors.clear();
    baseline = 0;
  }

  void sample(Vector3 camera) {
    if (_anchor == null) return;
    _first ??= camera.clone();
    baseline = math.max(baseline, horizontalDistance(_first!, camera));
    if (horizontalDistance(_anchor!, camera) > .2) {
      final angle = math.atan2(camera.z - _anchor!.z, camera.x - _anchor!.x);
      _sectors.add(((angle + math.pi) / (math.pi / 6)).floor() % 12);
    }
  }

  bool get recommended => _sectors.length >= 3 && baseline >= .5;
  double get progress =>
      math.min(1, math.min(_sectors.length / 3, baseline / .5));
}

class ScanPanel extends StatelessWidget {
  const ScanPanel({
    super.key,
    required this.scan,
    required this.tracking,
    required this.busy,
    required this.onSave,
    required this.onCancel,
  });
  final ScanGuidance scan;
  final bool tracking, busy;
  final VoidCallback? onSave, onCancel;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anchor placed • Scan before saving',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            !tracking
                ? 'Tracking paused: move slowly toward a textured area.'
                : scan.recommended
                ? 'Good movement coverage — ready to try saving.'
                : 'Scan more: move around the point while keeping the surrounding surfaces in view.',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: busy ? null : scan.progress),
          const SizedBox(height: 8),
          const Text(
            'Movement guidance only, not ARCore feature quality. You can save before the bar is full.',
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
              FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: Text(busy ? 'Saving…' : 'Save anchor'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
