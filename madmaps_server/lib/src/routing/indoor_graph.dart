import 'dart:math' as math;

enum IndoorNodeKind {
  hallway,
  classroomDoor,
  stairs,
  elevator,
  entrance,
  landmark,
}

enum EdgeVerificationStatus { verified, unverified, rejected }

class IndoorNode {
  const IndoorNode({
    required this.id,
    required this.floor,
    required this.xMeters,
    required this.zMeters,
    required this.kind,
    this.label,
  });

  final String id;
  final int floor;
  final double xMeters;
  final double zMeters;
  final IndoorNodeKind kind;
  final String? label;

  double planarDistanceTo(IndoorNode other) {
    final dx = xMeters - other.xMeters;
    final dz = zMeters - other.zMeters;
    return math.sqrt(dx * dx + dz * dz);
  }

  double manhattanDistanceTo(IndoorNode other) =>
      (xMeters - other.xMeters).abs() + (zMeters - other.zMeters).abs();
}

class DirectedEdge {
  const DirectedEdge({
    required this.id,
    required this.from,
    required this.to,
    required this.travelTimeSeconds,
    this.description,
    this.verificationStatus = EdgeVerificationStatus.verified,
  });

  final String id;
  final String from;
  final String to;
  final double travelTimeSeconds;
  final String? description;
  final EdgeVerificationStatus verificationStatus;
}

class IndoorGraph {
  IndoorGraph({
    required Iterable<IndoorNode> nodes,
    required Iterable<DirectedEdge> edges,
  }) : nodes = Map.unmodifiable({for (final node in nodes) node.id: node}),
       edges = List.unmodifiable(edges) {
    if (this.nodes.length != nodes.length) {
      throw ArgumentError('Node IDs must be unique.');
    }

    final outgoing = <String, List<DirectedEdge>>{
      for (final id in this.nodes.keys) id: <DirectedEdge>[],
    };
    final incoming = <String, List<DirectedEdge>>{
      for (final id in this.nodes.keys) id: <DirectedEdge>[],
    };
    final edgeIds = <String>{};
    for (final edge in this.edges) {
      if (!edgeIds.add(edge.id)) {
        throw ArgumentError('Duplicate edge ID: ${edge.id}');
      }
      if (!this.nodes.containsKey(edge.from) ||
          !this.nodes.containsKey(edge.to)) {
        throw ArgumentError('Edge ${edge.id} references an unknown node.');
      }
      if (!edge.travelTimeSeconds.isFinite || edge.travelTimeSeconds <= 0) {
        throw ArgumentError(
          'Edge ${edge.id} must have a positive finite weight.',
        );
      }
      outgoing[edge.from]!.add(edge);
      incoming[edge.to]!.add(edge);
    }
    _outgoing = Map.unmodifiable({
      for (final entry in outgoing.entries)
        entry.key: List<DirectedEdge>.unmodifiable(entry.value),
    });
    _incoming = Map.unmodifiable({
      for (final entry in incoming.entries)
        entry.key: List<DirectedEdge>.unmodifiable(entry.value),
    });
  }

  final Map<String, IndoorNode> nodes;
  final List<DirectedEdge> edges;
  late final Map<String, List<DirectedEdge>> _outgoing;
  late final Map<String, List<DirectedEdge>> _incoming;

  IndoorNode node(String id) {
    final result = nodes[id];
    if (result == null) throw ArgumentError.value(id, 'id', 'Unknown node');
    return result;
  }

  List<DirectedEdge> outgoing(String nodeId) => _outgoing[nodeId] ?? const [];

  List<DirectedEdge> incoming(String nodeId) => _incoming[nodeId] ?? const [];
}
