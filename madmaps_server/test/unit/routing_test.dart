import 'package:madmaps_server/src/routing/a_star.dart';
import 'package:madmaps_server/src/routing/heuristics.dart';
import 'package:madmaps_server/src/routing/indoor_graph.dart';
import 'package:madmaps_server/src/routing/ml_heuristic_trainer.dart';
import 'package:madmaps_server/src/routing/mock_indoor_map.dart';
import 'package:madmaps_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('AStarRouter', () {
    final fixture = buildMockIndoorMap();
    final graph = fixture.graph;
    const router = AStarRouter();
    final pairs = <(String, String)>[
      ('f1_room_0_0', 'f1_room_8_3'),
      ('f1_room_0_0', 'f4_room_8_3'),
      ('f3_room_4_0', 'f3_room_6_3'),
      ('f4_room_8_0', 'f2_room_0_3'),
    ];

    test('builds a bidirectional pixel-cost graph from persisted models', () {
      final persistedGraph = IndoorGraph.fromModels(
        nodes: [
          Nodes(
            nodeId: 'a',
            floor: 1,
            x: 0,
            y: 0,
            kind: Kind.junction,
            status: MapEntityStatus.active,
          ),
          Nodes(
            nodeId: 'b',
            floor: 1,
            x: 3,
            y: 4,
            kind: Kind.approach,
            status: MapEntityStatus.active,
          ),
        ],
        edges: [
          Edge(
            fromNodeId: 'a',
            toNodeId: 'b',
            type: EdgeType.walk,
            costPx: 5,
            bidirectional: true,
            status: MapEntityStatus.active,
          ),
        ],
      );

      expect(persistedGraph.edges, hasLength(2));
      final reverse = router.findRoute(
        graph: persistedGraph,
        startNodeId: 'b',
        goalNodeId: 'a',
        heuristic: const ZeroHeuristic(),
      );
      expect(reverse.pathNodeIds, ['b', 'a']);
      expect(reverse.totalCost, 5);
    });

    test('all analytical heuristics preserve optimal route cost', () {
      final heuristics = <RoutingHeuristic>[
        const EuclideanTimeHeuristic(),
        const ManhattanTimeHeuristic(),
        const FloorAwareHeuristic(),
        LandmarkHeuristic(
          graph,
          landmarkNodeIds: const [
            'f1_h_0_0',
            'f1_h_8_3',
            'f4_h_0_3',
            'f4_h_8_0',
          ],
        ),
      ];
      for (final (from, goal) in pairs) {
        final baseline = router.findRoute(
          graph: graph,
          startNodeId: from,
          goalNodeId: goal,
          heuristic: const ZeroHeuristic(),
        );
        for (final heuristic in heuristics) {
          final route = router.findRoute(
            graph: graph,
            startNodeId: from,
            goalNodeId: goal,
            heuristic: heuristic,
          );
          expect(route.found, isTrue, reason: heuristic.name);
          expect(
            route.travelTimeSeconds,
            closeTo(baseline.travelTimeSeconds, 1e-9),
            reason: heuristic.name,
          );
        }
      }
    });

    test(
      'floor-aware, landmark, and hybrid are optimal for every classroom pair',
      () {
        const floorAware = FloorAwareHeuristic();
        final landmark = LandmarkHeuristic(
          graph,
          landmarkNodeIds: const [
            'f1_h_0_0',
            'f1_h_8_3',
            'f4_h_0_3',
            'f4_h_8_0',
          ],
        );
        final hybrid = MaxHeuristic([floorAware, landmark]);
        for (final from in fixture.classroomNodeIds) {
          for (final goal in fixture.classroomNodeIds) {
            if (from == goal) continue;
            final baseline = router.findRoute(
              graph: graph,
              startNodeId: from,
              goalNodeId: goal,
              heuristic: const ZeroHeuristic(),
            );
            final floorRoute = router.findRoute(
              graph: graph,
              startNodeId: from,
              goalNodeId: goal,
              heuristic: floorAware,
            );
            final landmarkRoute = router.findRoute(
              graph: graph,
              startNodeId: from,
              goalNodeId: goal,
              heuristic: landmark,
            );
            final hybridRoute = router.findRoute(
              graph: graph,
              startNodeId: from,
              goalNodeId: goal,
              heuristic: hybrid,
            );
            expect(
              floorRoute.travelTimeSeconds,
              closeTo(baseline.travelTimeSeconds, 1e-9),
              reason: 'floor-aware $from -> $goal',
            );
            expect(
              landmarkRoute.travelTimeSeconds,
              closeTo(baseline.travelTimeSeconds, 1e-9),
              reason: 'landmark $from -> $goal',
            );
            expect(
              hybridRoute.travelTimeSeconds,
              closeTo(baseline.travelTimeSeconds, 1e-9),
              reason: 'hybrid $from -> $goal',
            );
          }
        }
      },
    );

    test(
      'floor-aware, landmark, and hybrid are admissible from every map node',
      () {
        const floorAware = FloorAwareHeuristic();
        final landmark = LandmarkHeuristic(
          graph,
          landmarkNodeIds: const [
            'f1_h_0_0',
            'f1_h_8_3',
            'f4_h_0_3',
            'f4_h_8_0',
          ],
        );
        final hybrid = MaxHeuristic([floorAware, landmark]);
        for (final goal in fixture.classroomNodeIds) {
          for (final from in graph.nodes.keys) {
            if (from == goal) continue;
            final exact = router
                .findRoute(
                  graph: graph,
                  startNodeId: from,
                  goalNodeId: goal,
                  heuristic: const ZeroHeuristic(),
                )
                .travelTimeSeconds;
            expect(
              floorAware.estimate(graph, from, goal),
              lessThanOrEqualTo(exact + 1e-9),
              reason: 'floor-aware $from -> $goal',
            );
            expect(
              landmark.estimate(graph, from, goal),
              lessThanOrEqualTo(exact + 1e-9),
              reason: 'landmark $from -> $goal',
            );
            expect(
              hybrid.estimate(graph, from, goal),
              lessThanOrEqualTo(exact + 1e-9),
              reason: 'hybrid $from -> $goal',
            );
          }
        }
      },
    );

    test('respects directionality and reports unreachable destinations', () {
      final oneWay = IndoorGraph(
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
            xMeters: 1,
            zMeters: 0,
            kind: IndoorNodeKind.hallway,
          ),
        ],
        edges: const [
          DirectedEdge(id: 'a-b', from: 'a', to: 'b', travelTimeSeconds: 1),
        ],
      );
      expect(
        router
            .findRoute(
              graph: oneWay,
              startNodeId: 'a',
              goalNodeId: 'b',
              heuristic: const ZeroHeuristic(),
            )
            .found,
        isTrue,
      );
      expect(
        router
            .findRoute(
              graph: oneWay,
              startNodeId: 'b',
              goalNodeId: 'a',
              heuristic: const ZeroHeuristic(),
            )
            .found,
        isFalse,
      );
    });

    test('calibrated ML heuristic is optimal on held-out routes', () {
      const trainer = MlHeuristicTrainer();
      final candidates = fixture.classroomNodeIds;
      final allPairs = <(String, String)>[
        for (var index = 0; index < 60; index++)
          (
            candidates[index % candidates.length],
            candidates[(index * 7 + 11) % candidates.length],
          ),
      ].where((pair) => pair.$1 != pair.$2).toList();
      final examples = trainer.exactExamples(graph, allPairs);
      final weights = trainer.train(
        graph,
        examples.take(30).toList(),
        calibrationExamples: examples.skip(30).take(20).toList(),
      );
      final heuristic = MlBasedHeuristic(weights: weights);
      for (final example in examples.skip(50)) {
        final baseline = router.findRoute(
          graph: graph,
          startNodeId: example.fromNodeId,
          goalNodeId: example.goalNodeId,
          heuristic: const ZeroHeuristic(),
        );
        final route = router.findRoute(
          graph: graph,
          startNodeId: example.fromNodeId,
          goalNodeId: example.goalNodeId,
          heuristic: heuristic,
        );
        expect(
          route.travelTimeSeconds,
          closeTo(baseline.travelTimeSeconds, 1e-9),
        );
      }
    });

    test('crowd-safe floor and landmark remain optimal on irregular data', () {
      final irregular = buildIrregularCrowdsourcedMock(
        floors: 3,
        width: 8,
        height: 5,
        maximumSamplesPerSegment: 4,
      );
      final irregularGraph = irregular.graph;
      const safeFloor = UncertainCoordinateFloorHeuristic();
      final landmark = LandmarkHeuristic(
        irregularGraph,
        landmarkNodeIds: const [
          'cs_f1_h_0_0',
          'cs_f1_h_7_4',
          'cs_f3_h_0_4',
          'cs_f3_h_7_0',
        ],
      );
      for (var index = 0; index < 30; index++) {
        final from = irregular
            .classroomNodeIds[index % irregular.classroomNodeIds.length];
        final goal =
            irregular.classroomNodeIds[(index * 7 + 9) %
                irregular.classroomNodeIds.length];
        if (from == goal) continue;
        final exact = router.findRoute(
          graph: irregularGraph,
          startNodeId: from,
          goalNodeId: goal,
          heuristic: const ZeroHeuristic(),
        );
        for (final heuristic in <RoutingHeuristic>[safeFloor, landmark]) {
          final route = router.findRoute(
            graph: irregularGraph,
            startNodeId: from,
            goalNodeId: goal,
            heuristic: heuristic,
          );
          expect(
            route.travelTimeSeconds,
            closeTo(exact.travelTimeSeconds, 1e-9),
            reason: '${heuristic.name} $from -> $goal',
          );
        }
      }
    });
  });
}
