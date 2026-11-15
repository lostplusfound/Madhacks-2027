import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:madmaps_client/madmaps_client.dart' as api;
import 'package:madmaps/features/localization/shared_captures.dart';
import 'package:madmaps/features/localization/map_data.dart';
import 'package:madmaps/features/localization/local_floor1_import.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:vector_math/vector_math_64.dart';

class CaptureClient extends api.Client {
  CaptureClient() : super('http://localhost:8080/');
  bool offline = false;
  final records = <String, api.ArCapture>{};
  @override
  Future<T> callServerEndpoint<T>(
    String endpoint,
    String method,
    Map<String, dynamic> args, {
    bool authenticated = true,
  }) async {
    if (offline) throw const SocketException('offline');
    if (method == 'publishCapture') {
      final capture = args['capture'] as api.ArCapture;
      return (records[capture.captureId] ??= capture) as T;
    }
    if (method == 'updateCapture') {
      final capture = args['capture'] as api.ArCapture;
      final existing = records[capture.captureId]!;
      if (existing.anchorMapJson != args['expectedAnchorMapJson'] &&
          existing.anchorMapJson != capture.anchorMapJson) {
        throw api.MapApiException(code: 'captureConflict', message: 'Refresh');
      }
      final updated = capture.copyWith(expiresAt: existing.expiresAt);
      records[capture.captureId] = updated;
      return updated as T;
    }
    if (method == 'deleteCapture') {
      records.remove(args['captureId']);
      return null as T;
    }
    return records.values.toList() as T;
  }
}

AnchorMap scan() =>
    AnchorMap('capture-1', 'Floor 2 capture', [
        SavedAnchor(
          'a',
          'A',
          'cloud-a',
          Matrix4.identity(),
          DateTime.now().add(const Duration(days: 1)),
        ),
        SavedAnchor(
          'b',
          'B',
          'cloud-b',
          Matrix4.translationValues(3, 0, 0),
          DateTime.now().add(const Duration(days: 1)),
        ),
      ])
      ..floor.enabled = true
      ..floor.floorNumber = 2
      ..floor.anchorPoints.addAll({
        'a': const Offset(100, 100),
        'b': const Offset(160, 100),
      })
      ..floor.calibrationIds.addAll(['a', 'b']);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final graph = FloorGraph({}, [], [], floor: 2, graphId: 'floor2', version: 3);
  test(
    'offline uploads persist for retry and download on another instance',
    () async {
      final client = CaptureClient()..offline = true;
      addTearDown(client.close);
      final captures = SharedCaptures(connect: () async => client);
      await expectLater(
        captures.publish(scan(), graph),
        throwsA(isA<SocketException>()),
      );
      final preferences = await SharedPreferences.getInstance();
      expect(
        (jsonDecode(preferences.getString(SharedCaptures.pendingKey)!) as Map)
            .length,
        1,
      );
      client.offline = false;
      await captures.retryPending();
      expect(client.records.length, 1);
      expect(
        jsonDecode(preferences.getString(SharedCaptures.pendingKey)!),
        isEmpty,
      );
      final secondPhone = SharedCaptures(connect: () async => client);
      final downloaded = await secondPhone.load({2: graph});
      expect(downloaded.single.floor.floorNumber, 2);
      expect(downloaded.single.floor.calibration(downloaded.single)!.scale, 20);
      client.offline = true;
      expect((await secondPhone.load({2: graph})).length, 1);
      expect(
        await secondPhone.load({
          2: FloorGraph({}, [], [], floor: 2, graphId: 'floor2', version: 4),
        }),
        isEmpty,
      );
    },
  );
  test('expired and malformed cached scans are ignored', () async {
    final client = CaptureClient();
    addTearDown(client.close);
    final captures = SharedCaptures(connect: () async => client);
    await captures.publish(scan(), graph);
    final record = client.records.values.single;
    client.records['expired'] = record.copyWith(
      captureId: 'expired',
      expiresAt: DateTime.utc(2000),
    );
    client.records['broken'] = record.copyWith(
      captureId: 'broken',
      anchorMapJson: '{}',
    );
    expect((await captures.load({2: graph})).map((m) => m.id), ['capture-1']);
  });
  test(
    'Floor 1 import retries one saved snapshot, preserves originals, and never imports Floor 2',
    () async {
      final client = CaptureClient()..offline = true;
      addTearDown(client.close);
      final captures = SharedCaptures(connect: () async => client);
      final floor1 = FloorGraph(
        {},
        [],
        [],
        floor: 1,
        graphId: 'floor1',
        version: 1,
      );
      final downstairs = scan()..floor.floorNumber = 1;
      downstairs.floor.nodePoints['local-override'] = const Offset(10, 10);
      final upstairs = AnchorMap('upstairs', 'Floor 2', scan().anchors)
        ..floor.floorNumber = 2;
      await MapStore().save([downstairs, upstairs]);
      final preferences = await SharedPreferences.getInstance();
      final before = preferences.getString(MapStore.key);
      final importer = LocalFloor1Import();
      await expectLater(
        importer.run([downstairs, upstairs], floor1, captures),
        throwsA(isA<SocketException>()),
      );
      expect(preferences.getString(LocalFloor1Import.key), isNotNull);
      client.offline = false;
      await importer.run([downstairs, upstairs], floor1, captures);
      expect(client.records.length, 1);
      final shared = client.records.values.single;
      expect(shared.floorNumber, 1);
      expect(shared.graphId, 'floor1');
      final imported = AnchorMap.fromJson(
        jsonDecode(shared.anchorMapJson) as Map<String, dynamic>,
      );
      expect(imported.anchors.length, downstairs.anchors.length);
      expect(imported.floor.nodePoints, isEmpty);
      expect(downstairs.floor.nodePoints, isNotEmpty);
      expect(preferences.getString(MapStore.key), before);
      // A subsequent local addition is not imported after the one-time seed.
      final later = AnchorMap('later', 'Later scan', scan().anchors)
        ..floor = downstairs.floor;
      await importer.run([downstairs, upstairs, later], floor1, captures);
      expect(client.records.length, 1);
      expect(
        jsonDecode(preferences.getString(LocalFloor1Import.key)!)['done'],
        true,
      );
    },
  );
  test(
    'local captures stay usable regardless of ID prefix; shared copies take precedence',
    () async {
      final client = CaptureClient();
      addTearDown(client.close);
      final captures = SharedCaptures(connect: () async => client);
      final local = scan();
      expect((await captures.navigationMaps([local], [])).single, same(local));
      await captures.publish(local, graph);
      final shared = await captures.load({2: graph});
      expect(
        (await captures.navigationMaps([local], shared)).single,
        same(shared.single),
      );
      await captures.edit(
        shared.single,
        graph,
        await captures.originalJson(local.id),
        delete: true,
      );
      expect(await captures.navigationMaps([local], []), isEmpty);
      // Suppressing a stale published duplicate never deletes its local record.
      await MapStore().save([local]);
      expect((await MapStore().load()).single.anchors.length, 2);
    },
  );
  test(
    'shared edits retry offline and refresh cached metadata, including removals',
    () async {
      final client = CaptureClient();
      addTearDown(client.close);
      final captures = SharedCaptures(connect: () async => client);
      final map = scan();
      await captures.publish(map, graph);
      await captures.load({2: graph});
      final expected = await captures.originalJson(map.id);
      map.name = 'Edited';
      client.offline = true;
      await expectLater(
        captures.edit(map, graph, expected),
        throwsA(isA<SocketException>()),
      );
      client.offline = false;
      await captures.retryPending();
      expect(client.records[map.id]!.anchorMapJson, contains('Edited'));
      expect(
        await captures.originalJson(map.id),
        client.records[map.id]!.anchorMapJson,
      );
      await captures.edit(
        map,
        graph,
        await captures.originalJson(map.id),
        delete: true,
      );
      client.offline = true;
      expect(await captures.load({2: graph}), isEmpty);
    },
  );
}
