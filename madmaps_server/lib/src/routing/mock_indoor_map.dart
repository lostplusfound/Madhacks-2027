import 'dart:math' as math;

import 'indoor_graph.dart';

/// A deterministic, fictional four-floor academic building benchmark.
/// It is not a surveyed model of Morgridge Hall.
class MockIndoorMap {
  const MockIndoorMap({required this.graph, required this.classroomNodeIds});

  final IndoorGraph graph;
  final List<String> classroomNodeIds;
}

MockIndoorMap buildMockIndoorMap() {
  final nodes = <IndoorNode>[];
  final edges = <DirectedEdge>[];
  final classrooms = <String>[];
  const xCoordinates = <double>[0, 6, 12, 18, 24, 30, 36, 42, 48];
  const zCoordinates = <double>[0, 8, 16, 24];
  var edgeNumber = 0;

  String hallId(int floor, int x, int z) => 'f${floor}_h_${x}_$z';

  void connect(
    String from,
    String to,
    double seconds, {
    String? description,
  }) {
    edges.add(
      DirectedEdge(
        id: 'edge_${edgeNumber++}',
        from: from,
        to: to,
        travelTimeSeconds: seconds,
        description: description,
      ),
    );
  }

  for (var floor = 1; floor <= 4; floor++) {
    for (var xi = 0; xi < xCoordinates.length; xi++) {
      for (var zi = 0; zi < zCoordinates.length; zi++) {
        final isStairs = (xi == 1 || xi == 7) && zi == 1;
        final isElevator = xi == 4 && zi == 2;
        final isLandmark = xi == 4 && zi == 0;
        nodes.add(
          IndoorNode(
            id: hallId(floor, xi, zi),
            floor: floor,
            xMeters: xCoordinates[xi],
            zMeters: zCoordinates[zi],
            kind: isStairs
                ? IndoorNodeKind.stairs
                : isElevator
                ? IndoorNodeKind.elevator
                : isLandmark
                ? IndoorNodeKind.landmark
                : IndoorNodeKind.hallway,
            label: isLandmark ? 'Floor $floor information display' : null,
          ),
        );
      }
    }

    for (var zi = 0; zi < zCoordinates.length; zi++) {
      for (var xi = 0; xi < xCoordinates.length - 1; xi++) {
        final left = hallId(floor, xi, zi);
        final right = hallId(floor, xi + 1, zi);
        final congestion = 1 + ((floor * 7 + zi * 3 + xi) % 4) * 0.08;
        connect(left, right, 6 / 1.25 * congestion);
        connect(right, left, 6 / 1.25 * (congestion + 0.04));
      }
    }

    for (var xi = 0; xi < xCoordinates.length; xi++) {
      for (var zi = 0; zi < zCoordinates.length - 1; zi++) {
        // One blocked segment on floor 3 forces a realistic directed detour.
        if (!(floor == 3 && xi == 5 && zi == 1)) {
          connect(
            hallId(floor, xi, zi),
            hallId(floor, xi, zi + 1),
            8 / 1.25 * (1 + ((xi + zi) % 3) * 0.07),
          );
        }
        if (!(floor == 3 && xi == 5 && zi == 2)) {
          connect(
            hallId(floor, xi, zi + 1),
            hallId(floor, xi, zi),
            8 / 1.25 * (1.04 + ((xi + zi) % 3) * 0.07),
          );
        }
      }
    }

    for (var xi = 0; xi < xCoordinates.length; xi += 2) {
      for (final zi in [0, zCoordinates.length - 1]) {
        final roomId = 'f${floor}_room_${xi}_$zi';
        classrooms.add(roomId);
        final roomZ = zCoordinates[zi] + (zi == 0 ? -2 : 2);
        nodes.add(
          IndoorNode(
            id: roomId,
            floor: floor,
            xMeters: xCoordinates[xi],
            zMeters: roomZ,
            kind: IndoorNodeKind.classroomDoor,
            label: '$floor${100 + xi * 2 + zi}',
          ),
        );
        connect(hallId(floor, xi, zi), roomId, 2.2, description: 'Enter room');
        connect(roomId, hallId(floor, xi, zi), 2.0, description: 'Exit room');
      }
    }
  }

  for (var floor = 1; floor < 4; floor++) {
    for (final xi in [1, 7]) {
      final lower = hallId(floor, xi, 1);
      final upper = hallId(floor + 1, xi, 1);
      connect(lower, upper, 18, description: 'Climb stairs');
      connect(upper, lower, 15, description: 'Descend stairs');
    }
    final lowerElevator = hallId(floor, 4, 2);
    final upperElevator = hallId(floor + 1, 4, 2);
    connect(lowerElevator, upperElevator, 12, description: 'Elevator up');
    connect(upperElevator, lowerElevator, 12, description: 'Elevator down');
  }

  return MockIndoorMap(
    graph: IndoorGraph(nodes: nodes, edges: edges),
    classroomNodeIds: List.unmodifiable(classrooms),
  );
}

/// Builds larger deterministic fixtures for routing scalability benchmarks.
MockIndoorMap buildScalableMockIndoorMap({
  required int floors,
  required int xCount,
  required int zCount,
  int classroomStride = 4,
}) {
  if (floors < 2 || xCount < 4 || zCount < 3 || classroomStride < 1) {
    throw ArgumentError('The scalable fixture dimensions are too small.');
  }
  final nodes = <IndoorNode>[];
  final edges = <DirectedEdge>[];
  final classrooms = <String>[];
  final stairZ = zCount ~/ 3;
  final elevatorX = xCount ~/ 2;
  final elevatorZ = zCount ~/ 2;
  var edgeNumber = 0;

  String hallId(int floor, int x, int z) => 'f${floor}_h_${x}_$z';
  void connect(String from, String to, double seconds, String description) {
    edges.add(
      DirectedEdge(
        id: 'scale_edge_${edgeNumber++}',
        from: from,
        to: to,
        travelTimeSeconds: seconds,
        description: description,
      ),
    );
  }

  for (var floor = 1; floor <= floors; floor++) {
    for (var x = 0; x < xCount; x++) {
      for (var z = 0; z < zCount; z++) {
        final stairs = (x == 1 || x == xCount - 2) && z == stairZ;
        final elevator = x == elevatorX && z == elevatorZ;
        nodes.add(
          IndoorNode(
            id: hallId(floor, x, z),
            floor: floor,
            xMeters: x * 6,
            zMeters: z * 8,
            kind: stairs
                ? IndoorNodeKind.stairs
                : elevator
                ? IndoorNodeKind.elevator
                : IndoorNodeKind.hallway,
          ),
        );
      }
    }

    for (var x = 0; x < xCount - 1; x++) {
      for (var z = 0; z < zCount; z++) {
        final congestion = 1 + ((floor * 11 + x * 3 + z) % 5) * 0.04;
        connect(
          hallId(floor, x, z),
          hallId(floor, x + 1, z),
          6 / 1.25 * congestion,
          'Walk east',
        );
        connect(
          hallId(floor, x + 1, z),
          hallId(floor, x, z),
          6 / 1.25 * (congestion + 0.03),
          'Walk west',
        );
      }
    }

    for (var x = 0; x < xCount; x++) {
      for (var z = 0; z < zCount - 1; z++) {
        final blocked = floor.isOdd && x % 11 == 5 && z == zCount ~/ 2;
        if (blocked) continue;
        final congestion = 1 + ((floor * 5 + x + z * 3) % 5) * 0.04;
        connect(
          hallId(floor, x, z),
          hallId(floor, x, z + 1),
          8 / 1.25 * congestion,
          'Walk south',
        );
        connect(
          hallId(floor, x, z + 1),
          hallId(floor, x, z),
          8 / 1.25 * (congestion + 0.03),
          'Walk north',
        );
      }
    }

    for (var x = 0; x < xCount; x += classroomStride) {
      for (final z in [0, zCount - 1]) {
        final id = 'f${floor}_room_${x}_$z';
        classrooms.add(id);
        nodes.add(
          IndoorNode(
            id: id,
            floor: floor,
            xMeters: x * 6,
            zMeters: z * 8 + (z == 0 ? -2 : 2),
            kind: IndoorNodeKind.classroomDoor,
            label: 'F$floor classroom $x-$z',
          ),
        );
        connect(hallId(floor, x, z), id, 2.2, 'Enter room');
        connect(id, hallId(floor, x, z), 2, 'Exit room');
      }
    }
  }

  for (var floor = 1; floor < floors; floor++) {
    for (final x in [1, xCount - 2]) {
      connect(
        hallId(floor, x, stairZ),
        hallId(floor + 1, x, stairZ),
        18,
        'Climb stairs',
      );
      connect(
        hallId(floor + 1, x, stairZ),
        hallId(floor, x, stairZ),
        15,
        'Descend stairs',
      );
    }
    connect(
      hallId(floor, elevatorX, elevatorZ),
      hallId(floor + 1, elevatorX, elevatorZ),
      12,
      'Elevator up',
    );
    connect(
      hallId(floor + 1, elevatorX, elevatorZ),
      hallId(floor, elevatorX, elevatorZ),
      12,
      'Elevator down',
    );
  }

  return MockIndoorMap(
    graph: IndoorGraph(nodes: nodes, edges: edges),
    classroomNodeIds: List.unmodifiable(classrooms),
  );
}

/// A valid but deliberately messy graph resembling crowdsourced observations.
///
/// Coordinates contain bounded jitter, floors use shifted local frames, and
/// logical corridor segments contain uneven numbers of degree-two samples.
MockIndoorMap buildIrregularCrowdsourcedMock({
  int floors = 4,
  int width = 14,
  int height = 9,
  int maximumSamplesPerSegment = 9,
  int seed = 2027,
}) {
  if (floors < 2 || width < 6 || height < 4 || maximumSamplesPerSegment < 1) {
    throw ArgumentError('The crowdsourced fixture dimensions are too small.');
  }
  final random = math.Random(seed);
  final nodes = <IndoorNode>[];
  final edges = <DirectedEdge>[];
  final classrooms = <String>[];
  final nodeById = <String, IndoorNode>{};
  var edgeNumber = 0;
  var sampleNumber = 0;

  String hubId(int floor, int x, int z) => 'cs_f${floor}_h_${x}_$z';
  void addNode(IndoorNode node) {
    nodes.add(node);
    nodeById[node.id] = node;
  }

  void addDirected(String from, String to, double seconds, String description) {
    edges.add(
      DirectedEdge(
        id: 'cs_edge_${edgeNumber++}',
        from: from,
        to: to,
        travelTimeSeconds: seconds,
        description: description,
      ),
    );
  }

  void addSampledConnection(String fromId, String toId) {
    final from = nodeById[fromId]!;
    final to = nodeById[toId]!;
    final sampleCount = 1 + random.nextInt(maximumSamplesPerSegment);
    final chain = <String>[fromId];
    for (var sample = 1; sample <= sampleCount; sample++) {
      final fraction = sample / (sampleCount + 1);
      final id = 'cs_sample_${sampleNumber++}';
      addNode(
        IndoorNode(
          id: id,
          floor: from.floor,
          xMeters:
              from.xMeters +
              (to.xMeters - from.xMeters) * fraction +
              (random.nextDouble() - 0.5) * 1.5,
          zMeters:
              from.zMeters +
              (to.zMeters - from.zMeters) * fraction +
              (random.nextDouble() - 0.5) * 1.5,
          kind: IndoorNodeKind.hallway,
        ),
      );
      chain.add(id);
    }
    chain.add(toId);
    for (var index = 0; index < chain.length - 1; index++) {
      final left = nodeById[chain[index]]!;
      final right = nodeById[chain[index + 1]]!;
      final distance = left.planarDistanceTo(right);
      final congestion = 1 + random.nextDouble() * 0.3;
      addDirected(
        left.id,
        right.id,
        distance / 1.2 * congestion + 0.15,
        'Crowdsourced corridor',
      );
      addDirected(
        right.id,
        left.id,
        distance / 1.2 * (congestion + 0.05) + 0.15,
        'Crowdsourced corridor',
      );
    }
  }

  for (var floor = 1; floor <= floors; floor++) {
    final floorXShift = floor.isEven ? 17.0 : -6.0;
    final floorZShift = (floor - 1) * 5.0;
    for (var x = 0; x < width; x++) {
      for (var z = 0; z < height; z++) {
        final stairs = (x == 1 || x == width - 2) && z == height ~/ 2;
        final elevator = x == width ~/ 2 && z == height ~/ 2;
        addNode(
          IndoorNode(
            id: hubId(floor, x, z),
            floor: floor,
            xMeters: floorXShift + x * 7 + (random.nextDouble() - 0.5) * 5,
            zMeters: floorZShift + z * 9 + (random.nextDouble() - 0.5) * 5,
            kind: stairs
                ? IndoorNodeKind.stairs
                : elevator
                ? IndoorNodeKind.elevator
                : IndoorNodeKind.hallway,
          ),
        );
      }
    }

    for (var z = 0; z < height; z++) {
      for (var x = 0; x < width - 1; x++) {
        final closure = z.isOdd && x == width ~/ 2 && floor != 1;
        if (!closure) {
          addSampledConnection(hubId(floor, x, z), hubId(floor, x + 1, z));
        }
      }
    }
    for (var z = 0; z < height - 1; z++) {
      final connectorXs = <int>{
        1,
        width ~/ 2,
        width - 2,
        (z * 3 + floor) % width,
      };
      for (final x in connectorXs) {
        addSampledConnection(hubId(floor, x, z), hubId(floor, x, z + 1));
      }
    }

    for (var z = 0; z < height; z++) {
      for (final x in [0, width - 1]) {
        final hub = nodeById[hubId(floor, x, z)]!;
        final roomId = 'cs_f${floor}_room_${x}_$z';
        classrooms.add(roomId);
        addNode(
          IndoorNode(
            id: roomId,
            floor: floor,
            xMeters: hub.xMeters + (x == 0 ? -3 : 3),
            zMeters: hub.zMeters + (random.nextDouble() - 0.5) * 2,
            kind: IndoorNodeKind.classroomDoor,
            label: 'Crowdsourced room F$floor-$x-$z',
          ),
        );
        addDirected(hub.id, roomId, 2.8, 'Enter room');
        addDirected(roomId, hub.id, 2.4, 'Exit room');
      }
    }
  }

  for (var floor = 1; floor < floors; floor++) {
    for (final x in [1, width - 2]) {
      final lower = hubId(floor, x, height ~/ 2);
      final upper = hubId(floor + 1, x, height ~/ 2);
      addDirected(lower, upper, 18, 'Climb stairs');
      addDirected(upper, lower, 15, 'Descend stairs');
    }
    final lower = hubId(floor, width ~/ 2, height ~/ 2);
    final upper = hubId(floor + 1, width ~/ 2, height ~/ 2);
    addDirected(lower, upper, 12, 'Elevator up');
    addDirected(upper, lower, 12, 'Elevator down');
  }

  return MockIndoorMap(
    graph: IndoorGraph(nodes: nodes, edges: edges),
    classroomNodeIds: List.unmodifiable(classrooms),
  );
}
