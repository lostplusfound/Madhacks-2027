import 'package:madmaps_server/routing.dart';
import 'package:test/test.dart';

void main() {
  group('SafeRoutePlanner', () {
    const validator = GraphSnapshotValidator();
    const planner = SafeRoutePlanner();

    test('validated snapshots exclude unverified and rejected edges', () {
      final graph = IndoorGraph(
        nodes: const [
          IndoorNode(
            id: 'a',
            floor: 1,
            xMeters: 0,
            zMeters: 0,
            kind: IndoorNodeKind.hallway,
          ),
          IndoorNode(
            id: 'b',
            floor: 1,
            xMeters: 5,
            zMeters: 0,
            kind: IndoorNodeKind.hallway,
          ),
          IndoorNode(
            id: 'c',
            floor: 2,
            xMeters: 10,
            zMeters: 0,
            kind: IndoorNodeKind.classroomDoor,
          ),
        ],
        edges: const [
          DirectedEdge(id: 'a-b', from: 'a', to: 'b', travelTimeSeconds: 5),
          DirectedEdge(id: 'b-c', from: 'b', to: 'c', travelTimeSeconds: 12),
          DirectedEdge(
            id: 'unverified-shortcut',
            from: 'a',
            to: 'c',
            travelTimeSeconds: 0.1,
            verificationStatus: EdgeVerificationStatus.unverified,
          ),
          DirectedEdge(
            id: 'rejected-shortcut',
            from: 'c',
            to: 'a',
            travelTimeSeconds: 0.1,
            verificationStatus: EdgeVerificationStatus.rejected,
          ),
        ],
      );
      final snapshot = validator.validate(
        graphId: 'draft-building',
        revision: 1,
        graph: graph,
      );

      expect(snapshot.graph.edges.map((edge) => edge.id), ['a-b', 'b-c']);
      final result = planner.findRoute(
        snapshot: snapshot,
        startNodeId: 'a',
        goalNodeId: 'c',
      );
      expect(result.strategy, RoutingStrategy.dijkstra);
      expect(result.route.travelTimeSeconds, 17);
    });

    test('matching Landmark index enables A* on a draft snapshot', () {
      final fixture = buildIrregularCrowdsourcedMock(
        floors: 3,
        width: 8,
        height: 5,
        maximumSamplesPerSegment: 3,
      );
      final snapshot = validator.validate(
        graphId: 'draft-irregular-building',
        revision: 7,
        graph: fixture.graph,
      );
      final index = LandmarkRoutingIndex.build(
        snapshot: snapshot,
        landmarkNodeIds: const [
          'cs_f1_h_0_0',
          'cs_f1_h_7_4',
          'cs_f3_h_0_4',
          'cs_f3_h_7_0',
        ],
      );
      final start = fixture.classroomNodeIds.first;
      final goal = fixture.classroomNodeIds.last;
      final aStar = planner.findRoute(
        snapshot: snapshot,
        startNodeId: start,
        goalNodeId: goal,
        landmarkIndex: index,
      );
      final dijkstra = planner.findRoute(
        snapshot: snapshot,
        startNodeId: start,
        goalNodeId: goal,
      );

      expect(index.matches(snapshot), isTrue);
      expect(aStar.strategy, RoutingStrategy.landmarkAlt);
      expect(dijkstra.strategy, RoutingStrategy.dijkstra);
      expect(aStar.route.found, isTrue);
      expect(
        aStar.route.travelTimeSeconds,
        closeTo(dijkstra.route.travelTimeSeconds, 1e-9),
      );
    });

    test('stale Landmark index falls back to Dijkstra', () {
      final fixture = buildIrregularCrowdsourcedMock(
        floors: 2,
        width: 6,
        height: 4,
        maximumSamplesPerSegment: 2,
      );
      final revisionOne = validator.validate(
        graphId: 'changing-building',
        revision: 1,
        graph: fixture.graph,
      );
      final staleIndex = LandmarkRoutingIndex.build(
        snapshot: revisionOne,
        landmarkNodeIds: const ['cs_f1_h_0_0', 'cs_f2_h_5_3'],
      );
      final revisionTwo = validator.validate(
        graphId: 'changing-building',
        revision: 2,
        graph: fixture.graph,
      );
      final result = planner.findRoute(
        snapshot: revisionTwo,
        startNodeId: fixture.classroomNodeIds.first,
        goalNodeId: fixture.classroomNodeIds.last,
        landmarkIndex: staleIndex,
      );

      expect(staleIndex.matches(revisionTwo), isFalse);
      expect(result.strategy, RoutingStrategy.dijkstra);
      expect(result.route.found, isTrue);
    });
  });
}
