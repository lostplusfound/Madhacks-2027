import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'map_graph_service.dart';

class LocationSearchEndpoint extends Endpoint {
  static const _service = MapGraphService();

  Future<List<SearchResult>> searchLocations(
    Session session,
    String graphId,
    String? query,
    LocationCategory? category,
    int? floorNumber,
    int limit,
  ) => _service.searchLocations(
    session,
    graphId: graphId,
    query: query,
    category: category,
    floorNumber: floorNumber,
    limit: limit,
  );

  Future<List<SearchResult>> listLocationsByCategory(
    Session session,
    String graphId,
    LocationCategory category,
    int? floorNumber,
    int limit,
  ) => _service.searchLocations(
    session,
    graphId: graphId,
    category: category,
    floorNumber: floorNumber,
    limit: limit,
  );

  Future<List<LocationCategory>> listQuickAccessCategories(
    Session session,
    String graphId,
  ) async {
    final graph = await _service.getGraph(session, graphId);
    if (graph == null) {
      throw MapApiException(code: 'not_found', message: 'Graph was not found.');
    }
    return const [
      LocationCategory.bathroom,
      LocationCategory.studySpace,
      LocationCategory.exit,
      LocationCategory.elevator,
    ];
  }
}
