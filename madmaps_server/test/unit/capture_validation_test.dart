import 'dart:convert';
import 'package:test/test.dart';
import 'package:madmaps_server/src/mapping/capture_validation.dart';

Map<String, dynamic> captureFixture(DateTime now) => {
  'id': 'scan-1',
  'name': 'Test scan',
  'anchors': [
    for (var i = 0; i < 2; i++)
      {
        'id': 'a$i',
        'name': 'Point $i',
        'cloudId': 'cloud-$i',
        'expiresAt': now.add(const Duration(days: 1)).toIso8601String(),
        'pose': [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i * 3, 0, 0, 1],
      },
  ],
  'floor': {
    'enabled': true,
    'floorNumber': 2,
    'anchors': {
      'a0': [100, 100],
      'a1': [160, 100],
    },
    'calibration': ['a0', 'a1'],
    'nodes': {},
    'locations': {},
    'anchorNodes': {},
  },
};
void main() {
  final now = DateTime.utc(2026, 11, 15);
  test('portable two-point capture validates and returns earliest expiry', () {
    expect(
      validateCapture(jsonEncode(captureFixture(now)), 'scan-1', 2, now),
      now.add(const Duration(days: 1)),
    );
  });
  test(
    'reject floor mismatch, graph overrides, expiry, and degenerate transforms',
    () {
      for (final edit in <void Function(Map<String, dynamic>)>[
        (m) => m['floor']['floorNumber'] = 1,
        (m) => m['floor']['nodes'] = {
          'hall': [1, 2],
        },
        (m) => m['anchors'][0]['expiresAt'] = now.toIso8601String(),
        (m) => m['anchors'][0]['pose'][0] = 0,
        (m) => m['floor']['calibration'] = ['a0', 'a0'],
        (m) => m['anchors'][1]['pose'][12] = 1,
      ]) {
        final data = captureFixture(now);
        edit(data);
        expect(
          () => validateCapture(jsonEncode(data), 'scan-1', 2, now),
          throwsFormatException,
        );
      }
    },
  );
}
