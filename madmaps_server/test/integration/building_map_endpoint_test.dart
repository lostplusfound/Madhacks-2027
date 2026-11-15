import 'dart:convert';
import 'package:test/test.dart';
import 'package:madmaps_server/src/generated/protocol.dart';
import '../unit/capture_validation_test.dart' show captureFixture;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Shared mapping', (sessions, endpoints) {
    Future<MapGraphSnapshot> graph() async {
      final owner = sessions.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          'mapper-owner',
          const {},
        ),
      );
      await endpoints.building.createBuilding(
        owner,
        'capture-building',
        'Capture Building',
        null,
      );
      return endpoints.mapGraph.createGraph(
        owner,
        CreateGraphRequest(
          graphId: 'capture-floor',
          buildingId: 'capture-building',
          name: 'Floor 2',
          floors: [
            FloorInput(
              floorId: 'capture-floor',
              floorNumber: 2,
              width: 1632,
              height: 1056,
              metersPerUnit: .1,
            ),
          ],
          nodes: [
            MapNodeInput(
              nodeId: 'a',
              floorId: 'capture-floor',
              x: 100,
              y: 100,
              kind: Kind.junction,
            ),
            MapNodeInput(
              nodeId: 'b',
              floorId: 'capture-floor',
              x: 160,
              y: 100,
              kind: Kind.junction,
            ),
          ],
          edges: [
            MapEdgeInput(
              edgeId: 'a-b',
              fromNodeId: 'a',
              toNodeId: 'b',
              type: EdgeType.walk,
              bidirectional: true,
            ),
          ],
          locations: [],
        ),
      );
    }

    ArCapture input(int version) => ArCapture(
      captureId: 'scan-1',
      graphId: 'capture-floor',
      graphVersion: version,
      floorNumber: 2,
      anchorMapJson: jsonEncode(captureFixture(DateTime.now().toUtc())),
      expiresAt: DateTime.utc(2030),
    );
    test(
      'public capture upload is idempotent and another phone can read it',
      () async {
        final snapshot = await graph();
        final request = input(snapshot.graph.version);
        final first = await endpoints.buildingMap.publishCapture(
          sessions,
          request,
        );
        final retry = await endpoints.buildingMap.publishCapture(
          sessions,
          request,
        );
        expect(retry.id, first.id);
        expect(
          first.expiresAt.isBefore(DateTime.now().add(const Duration(days: 2))),
          isTrue,
        );
        final shared = await endpoints.buildingMap.listCaptures(
          sessions,
          'capture-floor',
          snapshot.graph.version,
        );
        expect(shared.map((c) => c.captureId), ['scan-1']);
        expect(
          await endpoints.buildingMap.listCaptures(
            sessions,
            'capture-floor',
            snapshot.graph.version + 1,
          ),
          isEmpty,
        );
      },
    );
    test(
      'routing patches retain calibrated capture data on the new revision',
      () async {
        final snapshot = await graph();
        final saved = await endpoints.buildingMap.publishCapture(
          sessions,
          input(snapshot.graph.version),
        );
        final owner = sessions.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'mapper-owner',
            const {},
          ),
        );
        final updated = await endpoints.mapGraph.patchGraph(
          owner,
          GraphPatchRequest(
            graphId: 'capture-floor',
            expectedVersion: snapshot.graph.version,
            nodesToCreate: [],
            nodesToUpdate: [],
            nodeIdsToDelete: [],
            edgesToCreate: [],
            edgesToUpdate: [
              MapEdgeInput(
                edgeId: 'a-b',
                fromNodeId: 'a',
                toNodeId: 'b',
                type: EdgeType.walk,
                cost: 75,
                bidirectional: true,
              ),
            ],
            edgeIdsToDelete: [],
            locationsToCreate: [],
            locationsToUpdate: [],
            locationIdsToDelete: [],
          ),
        );
        final restored = await endpoints.buildingMap.listCaptures(
          sessions,
          'capture-floor',
          updated.graph.version,
        );
        expect(restored.single.captureId, saved.captureId);
        expect(restored.single.anchorMapJson, saved.anchorMapJson);
        expect(restored.single.expiresAt, saved.expiresAt);
        expect(restored.single.graphVersion, snapshot.graph.version + 1);
      },
    );
    test('capture ID conflicts cannot replace another contribution', () async {
      final snapshot = await graph();
      final original = input(snapshot.graph.version);
      await endpoints.buildingMap.publishCapture(sessions, original);
      final altered =
          jsonDecode(original.anchorMapJson) as Map<String, dynamic>;
      altered['name'] = 'Different';
      await expectLater(
        endpoints.buildingMap.publishCapture(
          sessions,
          original.copyWith(anchorMapJson: jsonEncode(altered)),
        ),
        throwsA(
          isA<MapApiException>().having(
            (e) => e.code,
            'code',
            'captureConflict',
          ),
        ),
      );
    });
    test(
      'shared edits reject conflicts, retry safely, and deletion cannot be resurrected',
      () async {
        final snapshot = await graph();
        final original = await endpoints.buildingMap.publishCapture(
          sessions,
          input(snapshot.graph.version),
        );
        final changed =
            jsonDecode(original.anchorMapJson) as Map<String, dynamic>;
        changed['name'] = 'Updated shared scan';
        final edit = original.copyWith(anchorMapJson: jsonEncode(changed));
        final updated = await endpoints.buildingMap.updateCapture(
          sessions,
          edit,
          original.anchorMapJson,
        );
        expect(updated.id, original.id);
        expect(updated.anchorMapJson, edit.anchorMapJson);
        expect(
          (await endpoints.buildingMap.updateCapture(
            sessions,
            edit,
            original.anchorMapJson,
          )).id,
          original.id,
        );
        changed['name'] = 'Conflicting update';
        await expectLater(
          endpoints.buildingMap.updateCapture(
            sessions,
            original.copyWith(anchorMapJson: jsonEncode(changed)),
            original.anchorMapJson,
          ),
          throwsA(
            isA<MapApiException>().having(
              (e) => e.code,
              'code',
              'captureConflict',
            ),
          ),
        );
        await expectLater(
          endpoints.buildingMap.deleteCapture(
            sessions,
            original.captureId,
            original.anchorMapJson,
          ),
          throwsA(
            isA<MapApiException>().having(
              (e) => e.code,
              'code',
              'captureConflict',
            ),
          ),
        );
        await endpoints.buildingMap.deleteCapture(
          sessions,
          original.captureId,
          updated.anchorMapJson,
        );
        await endpoints.buildingMap.deleteCapture(
          sessions,
          original.captureId,
          updated.anchorMapJson,
        );
        expect(
          await endpoints.buildingMap.listCaptures(
            sessions,
            'capture-floor',
            snapshot.graph.version,
          ),
          isEmpty,
        );
        await expectLater(
          endpoints.buildingMap.publishCapture(sessions, original),
          throwsA(
            isA<MapApiException>().having(
              (e) => e.code,
              'code',
              'captureConflict',
            ),
          ),
        );
        await expectLater(
          endpoints.buildingMap.updateCapture(
            sessions,
            edit,
            updated.anchorMapJson,
          ),
          throwsA(
            isA<MapApiException>().having(
              (e) => e.code,
              'code',
              'captureConflict',
            ),
          ),
        );
      },
    );

    test('stale map revision and graph overrides are rejected', () async {
      final snapshot = await graph();
      await expectLater(
        endpoints.buildingMap.publishCapture(
          sessions,
          input(snapshot.graph.version + 1),
        ),
        throwsA(
          isA<MapApiException>().having(
            (e) => e.code,
            'code',
            'revisionMismatch',
          ),
        ),
      );
      final request = input(snapshot.graph.version);
      final altered = jsonDecode(request.anchorMapJson) as Map<String, dynamic>;
      altered['floor']['nodes'] = {
        'a': [1, 2],
      };
      await expectLater(
        endpoints.buildingMap.publishCapture(
          sessions,
          request.copyWith(anchorMapJson: jsonEncode(altered)),
        ),
        throwsA(
          isA<MapApiException>().having(
            (e) => e.code,
            'code',
            'invalidCapture',
          ),
        ),
      );
    });
  });
}
