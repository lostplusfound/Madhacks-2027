import 'package:madmaps_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Map graph CRUD and search', (sessionBuilder, endpoints) {
    late TestSessionBuilder owner;

    setUp(() {
      owner = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          'owner-user',
          const {},
        ),
      );
    });

    Future<MapGraphSnapshot> createFixture() async {
      await endpoints.building.createBuilding(
        owner,
        'engineering-hall',
        'Engineering Hall',
        null,
      );
      return endpoints.mapGraph.createGraph(
        owner,
        CreateGraphRequest(
          graphId: 'engineering-main',
          buildingId: 'engineering-hall',
          name: 'Engineering Hall map',
          floors: [
            FloorInput(
              floorId: 'floor-1',
              floorNumber: 1,
              width: 1000,
              height: 1000,
              metersPerUnit: 0.05,
            ),
          ],
          nodes: [
            MapNodeInput(
              nodeId: 'hall-a',
              floorId: 'floor-1',
              x: 100,
              y: 100,
              kind: Kind.junction,
            ),
            MapNodeInput(
              nodeId: 'room-1524-door',
              floorId: 'floor-1',
              x: 200,
              y: 100,
              locationId: 'room-1524',
              kind: Kind.approach,
            ),
          ],
          edges: [
            MapEdgeInput(
              edgeId: 'hall-a-room-1524',
              fromNodeId: 'hall-a',
              toNodeId: 'room-1524-door',
              type: EdgeType.walk,
              bidirectional: true,
            ),
          ],
          locations: [
            LocationInput(
              locationId: 'room-1524',
              floorId: 'floor-1',
              roomNumber: '1524',
              name: 'Collaboration Room',
              category: LocationCategory.studySpace,
              aliases: 'quiet study;group study',
              routeNodeId: 'room-1524-door',
            ),
          ],
        ),
      );
    }

    test('whole graph create and read returns a consistent snapshot', () async {
      final created = await createFixture();

      expect(created.nodes, hasLength(2));
      expect(created.edges.single.costPx, closeTo(5, 0.001));
      expect(created.locations.single.roomNumber, '1524');

      final unchanged = await endpoints.mapGraph.getGraph(
        sessionBuilder,
        created.graph.graphId,
        created.graph.version,
      );
      expect(unchanged.unchanged, isTrue);
      expect(unchanged.snapshot, isNull);
    });

    test('walls persist and reject unsafe graph changes', () async {
      final graph = await createFixture();
      WallInput wall(double left, double top, double right, double bottom) =>
          WallInput(
            wallId: 'wall',
            floorId: 'floor-1',
            vertices: [
              WallPoint(x: left, y: top),
              WallPoint(x: right, y: top),
              WallPoint(x: right, y: bottom),
              WallPoint(x: left, y: bottom),
            ],
          );
      GraphPatchRequest patch(int version, List<WallInput> walls) =>
          GraphPatchRequest(
            graphId: graph.graph.graphId,
            expectedVersion: version,
            nodesToCreate: [],
            nodesToUpdate: [],
            nodeIdsToDelete: [],
            edgesToCreate: [],
            edgesToUpdate: [],
            edgeIdsToDelete: [],
            locationsToCreate: [],
            locationsToUpdate: [],
            locationIdsToDelete: [],
            walls: walls,
          );
      await expectLater(
        endpoints.mapGraph.patchGraph(
          owner,
          patch(graph.graph.version, [wall(140, 90, 160, 110)]),
        ),
        throwsA(isA<MapApiException>()),
      );
      final saved = await endpoints.mapGraph.patchGraph(
        owner,
        patch(graph.graph.version, [wall(400, 400, 500, 500)]),
      );
      expect(saved.walls.single.vertices, hasLength(4));
      final read = await endpoints.mapGraph.getGraph(
        sessionBuilder,
        graph.graph.graphId,
        null,
      );
      expect(read.snapshot!.walls.single.wallId, 'wall');
      await expectLater(
        endpoints.mapNode.updateNode(
          owner,
          graph.graph.graphId,
          saved.graph.version,
          MapNodeInput(
            nodeId: 'hall-a',
            floorId: 'floor-1',
            x: 450,
            y: 450,
            kind: Kind.junction,
          ),
        ),
        throwsA(isA<MapApiException>()),
      );
    });

    test('search ranks exact room and supports quick categories', () async {
      await createFixture();

      final roomResults = await endpoints.locationSearch.searchLocations(
        sessionBuilder,
        'engineering-main',
        '1524',
        null,
        null,
        20,
      );
      expect(roomResults.single.location.locationId, 'room-1524');
      expect(roomResults.single.score, 100);

      final categoryResults = await endpoints.locationSearch
          .listLocationsByCategory(
            sessionBuilder,
            'engineering-main',
            LocationCategory.studySpace,
            null,
            20,
          );
      expect(categoryResults.single.location.roomNumber, '1524');

      final synonymResults = await endpoints.locationSearch.searchLocations(
        sessionBuilder,
        'engineering-main',
        'study spaces',
        null,
        null,
        20,
      );
      expect(synonymResults.single.location.roomNumber, '1524');
      expect(synonymResults.single.score, 40);
    });

    test('creates a node and its connection atomically', () async {
      final graph = await createFixture();

      final updated = await endpoints.mapNode.createNodeWithConnections(
        owner,
        graph.graph.graphId,
        graph.graph.version,
        MapNodeInput(
          nodeId: 'hall-b',
          floorId: 'floor-1',
          x: 300,
          y: 100,
          kind: Kind.junction,
        ),
        [
          MapEdgeInput(
            edgeId: 'hall-a-hall-b',
            fromNodeId: 'hall-a',
            toNodeId: 'hall-b',
            type: EdgeType.walk,
            bidirectional: true,
          ),
        ],
        null,
      );

      expect(updated.nodes.map((row) => row.nodeId), contains('hall-b'));
      expect(updated.edges.map((row) => row.edgeId), contains('hall-a-hall-b'));
      expect(updated.graph.version, graph.graph.version + 1);
    });

    test('stores and withdraws a report without hiding its target', () async {
      await createFixture();

      final report = await endpoints.mapReport.reportEntity(
        owner,
        ReportTargetType.node,
        'hall-a',
        ReportReason.wrongLabel,
        'The label should be checked.',
      );
      expect(report.status, ReportStatus.open);

      final withdrawn = await endpoints.mapReport.withdrawReport(
        owner,
        report.reportId,
      );
      expect(withdrawn.status, ReportStatus.withdrawn);

      final node = await endpoints.mapNode.getNode(
        sessionBuilder,
        'engineering-main',
        'hall-a',
      );
      expect(node, isNotNull);
    });

    test('writes require authentication', () async {
      expect(
        () => endpoints.building.createBuilding(
          sessionBuilder,
          'no-auth-building',
          'No Auth',
          null,
        ),
        throwsA(
          isA<MapApiException>().having(
            (error) => error.code,
            'code',
            'authentication_required',
          ),
        ),
      );
    });

    test('another contributor cannot update owned records', () async {
      final graph = await createFixture();
      final other = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          'other-user',
          const {},
        ),
      );

      expect(
        () => endpoints.mapNode.updateNode(
          other,
          graph.graph.graphId,
          graph.graph.version,
          MapNodeInput(
            nodeId: 'hall-a',
            floorId: 'floor-1',
            x: 110,
            y: 100,
            kind: Kind.junction,
          ),
        ),
        throwsA(
          isA<MapApiException>().having(
            (error) => error.code,
            'code',
            'forbidden',
          ),
        ),
      );
    });

    test(
      'whole graph replacement rolls back every change on failure',
      () async {
        final original = await createFixture();
        final other = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'other-user',
            const {},
          ),
        );
        final withForeignContribution = await endpoints.mapNode
            .createNodeWithConnections(
              other,
              original.graph.graphId,
              original.graph.version,
              MapNodeInput(
                nodeId: 'other-hall',
                floorId: 'floor-1',
                x: 350,
                y: 100,
                kind: Kind.junction,
              ),
              [
                MapEdgeInput(
                  edgeId: 'hall-a-other-hall',
                  fromNodeId: 'hall-a',
                  toNodeId: 'other-hall',
                  type: EdgeType.walk,
                  bidirectional: true,
                ),
              ],
              null,
            );

        final replacement = ReplaceGraphRequest(
          graphId: original.graph.graphId,
          expectedVersion: withForeignContribution.graph.version,
          name: 'Name that must roll back',
          floors: [
            FloorInput(
              floorId: 'floor-1',
              floorNumber: 1,
              width: 1000,
              height: 1000,
              metersPerUnit: 0.05,
            ),
            FloorInput(
              floorId: 'floor-2',
              floorNumber: 2,
              width: 800,
              height: 800,
              metersPerUnit: 0.05,
            ),
          ],
          nodes: [
            MapNodeInput(
              nodeId: 'hall-a',
              floorId: 'floor-1',
              x: 100,
              y: 100,
              kind: Kind.junction,
            ),
            MapNodeInput(
              nodeId: 'room-1524-door',
              floorId: 'floor-1',
              x: 200,
              y: 100,
              locationId: 'room-1524',
              kind: Kind.approach,
            ),
          ],
          edges: [
            MapEdgeInput(
              edgeId: 'hall-a-room-1524',
              fromNodeId: 'hall-a',
              toNodeId: 'room-1524-door',
              type: EdgeType.walk,
              bidirectional: true,
            ),
          ],
          locations: [
            LocationInput(
              locationId: 'room-1524',
              floorId: 'floor-1',
              roomNumber: '1524',
              name: 'Collaboration Room',
              category: LocationCategory.studySpace,
              aliases: 'quiet study;group study',
              routeNodeId: 'room-1524-door',
            ),
          ],
        );

        await expectLater(
          endpoints.mapGraph.replaceGraph(owner, replacement),
          throwsA(
            isA<MapApiException>().having(
              (error) => error.code,
              'code',
              'forbidden',
            ),
          ),
        );

        final afterFailure = await endpoints.mapGraph.getGraph(
          sessionBuilder,
          original.graph.graphId,
          null,
        );
        final snapshot = afterFailure.snapshot!;
        expect(snapshot.graph.name, original.graph.name);
        expect(snapshot.graph.version, withForeignContribution.graph.version);
        expect(
          snapshot.floors.map((floor) => floor.floorId),
          isNot(contains('floor-2')),
        );
        expect(
          snapshot.nodes.map((node) => node.nodeId),
          contains('other-hall'),
        );
        expect(
          snapshot.edges.map((edge) => edge.edgeId),
          contains('hall-a-other-hall'),
        );
      },
    );
  });
}
