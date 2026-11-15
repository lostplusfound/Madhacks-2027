import 'a_star.dart';
import 'heuristics.dart';
import 'indoor_graph.dart';

enum RoutingStrategy { landmarkAlt, dijkstra }

/// A validated, stable graph view used for one Landmark index lifecycle.
///
/// The snapshot may represent a draft, preview, or production map. It does not
/// need to be published, but it must not change while an index is attached.
class RoutingGraphSnapshot {
  const RoutingGraphSnapshot._({
    required this.graphId,
    required this.revision,
    required this.graph,
    required this.contentSignature,
  });

  final String graphId;
  final int revision;
  final IndoorGraph graph;
  final String contentSignature;
}

class GraphSnapshotValidator {
  const GraphSnapshotValidator();

  RoutingGraphSnapshot validate({
    required String graphId,
    required int revision,
    required IndoorGraph graph,
  }) {
    if (graphId.trim().isEmpty) throw ArgumentError('graphId cannot be empty.');
    if (revision < 1) throw ArgumentError('revision must be positive.');

    final verifiedEdges = graph.edges
        .where(
          (edge) => edge.verificationStatus == EdgeVerificationStatus.verified,
        )
        .toList(growable: false);
    final validatedGraph = IndoorGraph(
      nodes: graph.nodes.values,
      edges: verifiedEdges,
    );
    return RoutingGraphSnapshot._(
      graphId: graphId,
      revision: revision,
      graph: validatedGraph,
      contentSignature: _graphSignature(validatedGraph),
    );
  }
}

/// Precomputed Landmark ALT data bound to one validated graph snapshot.
class LandmarkRoutingIndex {
  LandmarkRoutingIndex._({
    required this.graphId,
    required this.revision,
    required this.nodeCount,
    required this.contentSignature,
    required this.landmarkNodeIds,
    required this.heuristic,
  });

  factory LandmarkRoutingIndex.build({
    required RoutingGraphSnapshot snapshot,
    required List<String> landmarkNodeIds,
  }) {
    if (landmarkNodeIds.isEmpty) {
      throw ArgumentError('At least one landmark is required.');
    }
    final uniqueIds = landmarkNodeIds.toSet();
    if (uniqueIds.length != landmarkNodeIds.length) {
      throw ArgumentError('Landmark IDs must be unique.');
    }
    final ids = List<String>.unmodifiable(landmarkNodeIds);
    return LandmarkRoutingIndex._(
      graphId: snapshot.graphId,
      revision: snapshot.revision,
      nodeCount: snapshot.graph.nodes.length,
      contentSignature: snapshot.contentSignature,
      landmarkNodeIds: ids,
      heuristic: LandmarkHeuristic(snapshot.graph, landmarkNodeIds: ids),
    );
  }

  final String graphId;
  final int revision;
  final int nodeCount;
  final String contentSignature;
  final List<String> landmarkNodeIds;
  final LandmarkHeuristic heuristic;

  bool matches(RoutingGraphSnapshot snapshot) =>
      graphId == snapshot.graphId &&
      revision == snapshot.revision &&
      nodeCount == snapshot.graph.nodes.length &&
      contentSignature == snapshot.contentSignature;
}

class PlannedRoute {
  const PlannedRoute({required this.strategy, required this.route});

  final RoutingStrategy strategy;
  final RouteResult route;
}

/// Routes with Landmark A* when a matching index exists, otherwise Dijkstra.
class SafeRoutePlanner {
  const SafeRoutePlanner({this.router = const AStarRouter()});

  final AStarRouter router;

  PlannedRoute findRoute({
    required RoutingGraphSnapshot snapshot,
    required String startNodeId,
    required String goalNodeId,
    LandmarkRoutingIndex? landmarkIndex,
  }) {
    final useLandmark =
        landmarkIndex != null && landmarkIndex.matches(snapshot);
    final heuristic = useLandmark
        ? landmarkIndex.heuristic
        : const ZeroHeuristic();
    return PlannedRoute(
      strategy: useLandmark
          ? RoutingStrategy.landmarkAlt
          : RoutingStrategy.dijkstra,
      route: router.findRoute(
        graph: snapshot.graph,
        startNodeId: startNodeId,
        goalNodeId: goalNodeId,
        heuristic: heuristic,
      ),
    );
  }
}

String _graphSignature(IndoorGraph graph) {
  final buffer = StringBuffer();
  final nodes = graph.nodes.values.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  for (final node in nodes) {
    buffer
      ..write(node.id)
      ..write('|')
      ..write(node.floor)
      ..write('|')
      ..write(node.xMeters)
      ..write('|')
      ..write(node.zMeters)
      ..write('|')
      ..write(node.kind.index)
      ..write(';');
  }
  final edges = graph.edges.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  for (final edge in edges) {
    buffer
      ..write(edge.id)
      ..write('|')
      ..write(edge.from)
      ..write('|')
      ..write(edge.to)
      ..write('|')
      ..write(edge.effectiveCost)
      ..write(';');
  }
  var hash = 0xcbf29ce484222325;
  for (final codeUnit in buffer.toString().codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
