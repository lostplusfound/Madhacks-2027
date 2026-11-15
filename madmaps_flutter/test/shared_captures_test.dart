import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:madmaps_client/madmaps_client.dart' as api;
import 'package:madmaps/features/localization/shared_captures.dart';
import 'package:madmaps/features/localization/map_data.dart';
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
}
