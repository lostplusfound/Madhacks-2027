import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:madmaps_server/src/mapping/place_map_validation.dart';

Map<String, dynamic> placeMapFixture() => {
  'schema_version': 1,
  'profile': 'rooms-and-amenities-v1',
  'name': 'Test plan',
  'width': 400,
  'height': 240,
  'coordinate_origin': 'top-left',
  'coordinate_units': 'pixels',
  'image_mime_type': 'image/png',
  'image_base64': base64Encode(
    File('../madmaps_flutter/test/fixtures/lab_plan.png').readAsBytesSync(),
  ),
  'places': [
    {
      'id': 'place-1',
      'label': 'Office 101',
      'category': 'office',
      'x': 100,
      'y': 120,
    },
  ],
};
void main() {
  test('exported image and pins validate without routing geometry', () {
    expect(
      validatePlaceMap(jsonEncode(placeMapFixture()))['places'],
      hasLength(1),
    );
  });
  test(
    'reject out-of-bounds, duplicate IDs, wrong image dimensions and empty maps',
    () {
      final bad = placeMapFixture();
      (bad['places'] as List).first['x'] = 401;
      expect(() => validatePlaceMap(jsonEncode(bad)), throwsFormatException);
      final duplicate = placeMapFixture();
      (duplicate['places'] as List).add(
        Map<String, Object>.from((duplicate['places'] as List).first),
      );
      expect(
        () => validatePlaceMap(jsonEncode(duplicate)),
        throwsFormatException,
      );
      expect(
        () =>
            validatePlaceMap(jsonEncode({...placeMapFixture(), 'width': 401})),
        throwsFormatException,
      );
      expect(
        () =>
            validatePlaceMap(jsonEncode({...placeMapFixture(), 'places': []})),
        throwsFormatException,
      );
      expect(
        () => validatePlaceMap(
          jsonEncode({
            ...placeMapFixture(),
            'image_base64': base64Encode([1, 2, 3]),
          }),
        ),
        throwsFormatException,
      );
    },
  );
}
