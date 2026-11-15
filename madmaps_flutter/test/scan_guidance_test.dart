import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:madmaps/features/localization/scan_guidance.dart';

void main() {
  test(
    'stationary rotation or height changes do not imply movement coverage',
    () {
      final scan = ScanGuidance()..reset(Vector3.zero());
      scan.sample(Vector3(1, 1, 0));
      scan.sample(Vector3(1, 9, 0));
      expect(scan.recommended, isFalse);
      expect(scan.progress, 0);
      scan.sample(Vector3(.5, 1, .866));
      scan.sample(Vector3(-.5, 1, .866));
      expect(scan.recommended, isTrue);
      scan.reset(Vector3.zero());
      expect(scan.recommended, isFalse);
    },
  );
  testWidgets('Save is available with low coverage; only tap invokes save', (
    tester,
  ) async {
    final scan = ScanGuidance()..reset(Vector3.zero());
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanPanel(
            scan: scan,
            tracking: true,
            busy: false,
            onSave: () => saves++,
            onCancel: () {},
          ),
        ),
      ),
    );
    expect(saves, 0);
    expect(find.textContaining('Scan more'), findsOneWidget);
    await tester.tap(find.text('Save anchor'));
    expect(saves, 1);
  });
}
