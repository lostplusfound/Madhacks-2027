import 'dart:convert';
import 'package:test/test.dart';
import 'package:madmaps_server/src/generated/protocol.dart';
import '../unit/place_map_validation_test.dart' show placeMapFixture;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Saved point maps', (sessions, endpoints) {
    test('save, list without image payload, read and update pins', () async {
      final content = jsonEncode(placeMapFixture());
      final first = await endpoints.placeMap.saveMap(
        sessions,
        content,
        'Science Hall',
        'Level 2',
        null,
        null,
      );
      expect(first.version, 1);
      final listed = await endpoints.placeMap.listMaps(sessions);
      expect(listed.single.buildingName, 'Science Hall');
      expect(listed.single.placesJson, isNot(contains('image_base64')));
      final loaded = await endpoints.placeMap.getMap(sessions, first.mapId);
      expect(jsonDecode(loaded.mapJson), jsonDecode(content));
      final changed = placeMapFixture();
      (changed['places'] as List).first['x'] = 200;
      final updated = await endpoints.placeMap.saveMap(
        sessions,
        jsonEncode(changed),
        'Science Hall',
        'Level 2',
        first.mapId,
        1,
      );
      expect(updated.version, 2);
      expect(updated.id, first.id);
      expect((await endpoints.placeMap.listMaps(sessions)), hasLength(1));
      await expectLater(
        endpoints.placeMap.saveMap(
          sessions,
          content,
          'Science Hall',
          'Level 2',
          first.mapId,
          1,
        ),
        throwsA(
          isA<MapApiException>().having((e) => e.code, 'code', 'mapConflict'),
        ),
      );
      expect(
        jsonDecode(
          (await endpoints.placeMap.getMap(sessions, first.mapId)).mapJson,
        )['places'][0]['x'],
        200,
      );
    });
    test('different buildings can reuse pin IDs without mixing maps', () async {
      final a = await endpoints.placeMap.saveMap(
        sessions,
        jsonEncode(placeMapFixture()),
        'A',
        'Floor 1',
        null,
        null,
      );
      final b = await endpoints.placeMap.saveMap(
        sessions,
        jsonEncode(placeMapFixture()),
        'B',
        'Floor 1',
        null,
        null,
      );
      expect(a.mapId, isNot(b.mapId));
      expect(await endpoints.placeMap.listMaps(sessions), hasLength(2));
    });
    test('reject invalid maps before persisting', () async {
      final invalid = placeMapFixture();
      (invalid['places'] as List).first['category'] = 'made-up';
      await expectLater(
        endpoints.placeMap.saveMap(
          sessions,
          jsonEncode(invalid),
          'A',
          'F1',
          null,
          null,
        ),
        throwsA(anything),
      );
      expect(await endpoints.placeMap.listMaps(sessions), isEmpty);
    });
  });
}
