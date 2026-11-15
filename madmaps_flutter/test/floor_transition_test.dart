import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/features/navigation/floor_transition.dart';

void main() {
  final start = DateTime.utc(2026);
  test('approach triggers without exact arrival after stable proximity', () {
    for (final id in ['basement-up', 'floor1-down']) {
      final trigger = FloorTransitionTrigger();
      expect(trigger.update(id, 3.9, start), isFalse);
      expect(
        trigger.update(id, 3.5, start.add(const Duration(milliseconds: 499))),
        isFalse,
      );
      expect(
        trigger.update(id, 3, start.add(const Duration(milliseconds: 500))),
        isTrue,
      );
    }
  });
  test('tracking loss, leaving radius and connector changes reset dwell', () {
    for (final distance in [null, 4.1, double.nan, double.infinity]) {
      final trigger = FloorTransitionTrigger();
      trigger.update('up', 3, start);
      expect(
        trigger.update(
          'up',
          distance,
          start.add(const Duration(milliseconds: 400)),
        ),
        isFalse,
      );
      expect(
        trigger.update('up', 3, start.add(const Duration(milliseconds: 600))),
        isFalse,
      );
      expect(
        trigger.update('down', 3, start.add(const Duration(seconds: 2))),
        isFalse,
      );
      expect(
        trigger.update(
          'down',
          3,
          start.add(const Duration(milliseconds: 2500)),
        ),
        isTrue,
      );
      trigger.reset();
      expect(
        trigger.update('down', 3, start.add(const Duration(seconds: 3))),
        isFalse,
      );
    }
  });
}
