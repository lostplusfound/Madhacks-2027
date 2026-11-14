import 'indoor_graph.dart';

abstract interface class RoutingHeuristic {
  String get name;

  double estimate(IndoorGraph graph, String fromNodeId, String goalNodeId);
}

class ZeroHeuristic implements RoutingHeuristic {
  const ZeroHeuristic();

  @override
  String get name => 'dijkstra';

  @override
  double estimate(IndoorGraph graph, String fromNodeId, String goalNodeId) => 0;
}

class RouteResult {
  const RouteResult({
    required this.heuristicName,
    required this.pathNodeIds,
    required this.travelTimeSeconds,
    required this.expandedNodes,
    required this.queuedNodes,
  });

  final String heuristicName;
  final List<String> pathNodeIds;
  final double travelTimeSeconds;
  final int expandedNodes;
  final int queuedNodes;

  bool get found => pathNodeIds.isNotEmpty;
}

class AStarRouter {
  const AStarRouter();

  RouteResult findRoute({
    required IndoorGraph graph,
    required String startNodeId,
    required String goalNodeId,
    required RoutingHeuristic heuristic,
  }) {
    graph.node(startNodeId);
    graph.node(goalNodeId);

    if (startNodeId == goalNodeId) {
      return RouteResult(
        heuristicName: heuristic.name,
        pathNodeIds: [startNodeId],
        travelTimeSeconds: 0,
        expandedNodes: 0,
        queuedNodes: 1,
      );
    }

    final frontier = _MinHeap();
    final cost = <String, double>{startNodeId: 0};
    final previous = <String, String>{};
    var sequence = 0;
    var expanded = 0;
    var queued = 1;
    frontier.add(
      _QueueEntry(
        nodeId: startNodeId,
        priority: heuristic.estimate(graph, startNodeId, goalNodeId),
        cost: 0,
        sequence: sequence++,
      ),
    );

    while (frontier.isNotEmpty) {
      final current = frontier.removeFirst();
      if (current.cost > (cost[current.nodeId] ?? double.infinity)) continue;
      if (current.nodeId == goalNodeId) {
        return RouteResult(
          heuristicName: heuristic.name,
          pathNodeIds: _reconstruct(previous, startNodeId, goalNodeId),
          travelTimeSeconds: current.cost,
          expandedNodes: expanded,
          queuedNodes: queued,
        );
      }

      expanded++;
      for (final edge in graph.outgoing(current.nodeId)) {
        final candidateCost = current.cost + edge.travelTimeSeconds;
        if (candidateCost >= (cost[edge.to] ?? double.infinity)) continue;
        cost[edge.to] = candidateCost;
        previous[edge.to] = current.nodeId;
        final estimate = heuristic.estimate(graph, edge.to, goalNodeId);
        if (!estimate.isFinite || estimate < 0) {
          throw StateError(
            '${heuristic.name} returned invalid estimate $estimate.',
          );
        }
        frontier.add(
          _QueueEntry(
            nodeId: edge.to,
            priority: candidateCost + estimate,
            cost: candidateCost,
            sequence: sequence++,
          ),
        );
        queued++;
      }
    }

    return RouteResult(
      heuristicName: heuristic.name,
      pathNodeIds: const [],
      travelTimeSeconds: double.infinity,
      expandedNodes: expanded,
      queuedNodes: queued,
    );
  }

  List<String> _reconstruct(
    Map<String, String> previous,
    String start,
    String goal,
  ) {
    final reversed = <String>[goal];
    var current = goal;
    while (current != start) {
      current = previous[current]!;
      reversed.add(current);
    }
    return reversed.reversed.toList(growable: false);
  }
}

class _QueueEntry {
  const _QueueEntry({
    required this.nodeId,
    required this.priority,
    required this.cost,
    required this.sequence,
  });

  final String nodeId;
  final double priority;
  final double cost;
  final int sequence;

  bool comesBefore(_QueueEntry other) =>
      priority < other.priority ||
      (priority == other.priority && sequence < other.sequence);
}

class _MinHeap {
  final List<_QueueEntry> _items = [];

  bool get isNotEmpty => _items.isNotEmpty;

  void add(_QueueEntry value) {
    _items.add(value);
    var index = _items.length - 1;
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_items[parent].comesBefore(_items[index])) break;
      final temporary = _items[parent];
      _items[parent] = _items[index];
      _items[index] = temporary;
      index = parent;
    }
  }

  _QueueEntry removeFirst() {
    final result = _items.first;
    final last = _items.removeLast();
    if (_items.isEmpty) return result;
    _items[0] = last;
    var index = 0;
    while (true) {
      final left = index * 2 + 1;
      final right = left + 1;
      if (left >= _items.length) break;
      var child = left;
      if (right < _items.length && _items[right].comesBefore(_items[left])) {
        child = right;
      }
      if (_items[index].comesBefore(_items[child])) break;
      final temporary = _items[index];
      _items[index] = _items[child];
      _items[child] = temporary;
      index = child;
    }
    return result;
  }
}
