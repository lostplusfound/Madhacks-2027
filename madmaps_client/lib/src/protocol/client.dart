/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:madmaps_client/src/protocol/building.dart' as _ixxicett;
import 'package:madmaps_client/src/protocol/create_graph_request.dart'
    as _ik7sj57u;
import 'package:madmaps_client/src/protocol/edge.dart' as _i71va5xw;
import 'package:madmaps_client/src/protocol/graph_patch_request.dart'
    as _iq2332iw;
import 'package:madmaps_client/src/protocol/graph_read_result.dart'
    as _ijpyrqq0;
import 'package:madmaps_client/src/protocol/greetings/greeting.dart'
    as _igi1f61t;
import 'package:madmaps_client/src/protocol/location_category.dart'
    as _iosiyc7r;
import 'package:madmaps_client/src/protocol/location_input.dart' as _i9u1r3i1;
import 'package:madmaps_client/src/protocol/locations.dart' as _iwfkkrvw;
import 'package:madmaps_client/src/protocol/map_edge_input.dart' as _i63byxc2;
import 'package:madmaps_client/src/protocol/map_graph.dart' as _i5ydwcda;
import 'package:madmaps_client/src/protocol/map_graph_snapshot.dart'
    as _igef8xkz;
import 'package:madmaps_client/src/protocol/map_node_input.dart' as _iknlbgoc;
import 'package:madmaps_client/src/protocol/map_report.dart' as _i5b93lv5;
import 'package:madmaps_client/src/protocol/node.dart' as _i6rsjj6d;
import 'package:madmaps_client/src/protocol/replace_graph_request.dart'
    as _iwd56web;
import 'package:madmaps_client/src/protocol/report_reason.dart' as _i6ynwlr2;
import 'package:madmaps_client/src/protocol/report_target_type.dart'
    as _iws3unv8;
import 'package:madmaps_client/src/protocol/search_result.dart' as _i56rwuj1;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// {@category Endpoint}
class EndpointBuilding extends _isc.EndpointRef {
  EndpointBuilding(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'building';

  _ida.Future<_ixxicett.Building> createBuilding(
    String buildingId,
    String name,
    String? address,
  ) => caller.callServerEndpoint<_ixxicett.Building>(
    'building',
    'createBuilding',
    {
      'buildingId': buildingId,
      'name': name,
      'address': address,
    },
  );

  _ida.Future<_ixxicett.Building?> getBuilding(String buildingId) =>
      caller.callServerEndpoint<_ixxicett.Building?>(
        'building',
        'getBuilding',
        {'buildingId': buildingId},
      );

  _ida.Future<List<_ixxicett.Building>> listBuildings(
    int limit,
    int offset,
  ) => caller.callServerEndpoint<List<_ixxicett.Building>>(
    'building',
    'listBuildings',
    {
      'limit': limit,
      'offset': offset,
    },
  );
}

/// {@category Endpoint}
class EndpointLocation extends _isc.EndpointRef {
  EndpointLocation(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'location';

  _ida.Future<_iwfkkrvw.Locations> createLocation(
    String graphId,
    int expectedGraphVersion,
    _i9u1r3i1.LocationInput location,
  ) => caller.callServerEndpoint<_iwfkkrvw.Locations>(
    'location',
    'createLocation',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'location': location,
    },
  );

  _ida.Future<_iwfkkrvw.Locations?> getLocation(
    String graphId,
    String locationId,
  ) => caller.callServerEndpoint<_iwfkkrvw.Locations?>(
    'location',
    'getLocation',
    {
      'graphId': graphId,
      'locationId': locationId,
    },
  );

  _ida.Future<List<_iwfkkrvw.Locations>> listLocations(
    String graphId,
    int? floorNumber,
    _iosiyc7r.LocationCategory? category,
  ) => caller.callServerEndpoint<List<_iwfkkrvw.Locations>>(
    'location',
    'listLocations',
    {
      'graphId': graphId,
      'floorNumber': floorNumber,
      'category': category,
    },
  );

  _ida.Future<_iwfkkrvw.Locations> updateLocation(
    String graphId,
    int expectedGraphVersion,
    _i9u1r3i1.LocationInput location,
  ) => caller.callServerEndpoint<_iwfkkrvw.Locations>(
    'location',
    'updateLocation',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'location': location,
    },
  );

  _ida.Future<void> deleteLocation(
    String graphId,
    int expectedGraphVersion,
    String locationId,
  ) => caller.callServerEndpoint<void>(
    'location',
    'deleteLocation',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'locationId': locationId,
    },
  );
}

/// {@category Endpoint}
class EndpointLocationSearch extends _isc.EndpointRef {
  EndpointLocationSearch(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'locationSearch';

  _ida.Future<List<_i56rwuj1.SearchResult>> searchLocations(
    String graphId,
    String? query,
    _iosiyc7r.LocationCategory? category,
    int? floorNumber,
    int limit,
  ) => caller.callServerEndpoint<List<_i56rwuj1.SearchResult>>(
    'locationSearch',
    'searchLocations',
    {
      'graphId': graphId,
      'query': query,
      'category': category,
      'floorNumber': floorNumber,
      'limit': limit,
    },
  );

  _ida.Future<List<_i56rwuj1.SearchResult>> listLocationsByCategory(
    String graphId,
    _iosiyc7r.LocationCategory category,
    int? floorNumber,
    int limit,
  ) => caller.callServerEndpoint<List<_i56rwuj1.SearchResult>>(
    'locationSearch',
    'listLocationsByCategory',
    {
      'graphId': graphId,
      'category': category,
      'floorNumber': floorNumber,
      'limit': limit,
    },
  );

  _ida.Future<List<_iosiyc7r.LocationCategory>> listQuickAccessCategories(
    String graphId,
  ) => caller.callServerEndpoint<List<_iosiyc7r.LocationCategory>>(
    'locationSearch',
    'listQuickAccessCategories',
    {'graphId': graphId},
  );
}

/// {@category Endpoint}
class EndpointMapEdge extends _isc.EndpointRef {
  EndpointMapEdge(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mapEdge';

  _ida.Future<_i71va5xw.Edge> createEdge(
    String graphId,
    int expectedGraphVersion,
    _i63byxc2.MapEdgeInput edge,
  ) => caller.callServerEndpoint<_i71va5xw.Edge>(
    'mapEdge',
    'createEdge',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'edge': edge,
    },
  );

  _ida.Future<_i71va5xw.Edge?> getEdge(
    String graphId,
    String edgeId,
  ) => caller.callServerEndpoint<_i71va5xw.Edge?>(
    'mapEdge',
    'getEdge',
    {
      'graphId': graphId,
      'edgeId': edgeId,
    },
  );

  _ida.Future<List<_i71va5xw.Edge>> listEdges(String graphId) =>
      caller.callServerEndpoint<List<_i71va5xw.Edge>>(
        'mapEdge',
        'listEdges',
        {'graphId': graphId},
      );

  _ida.Future<_i71va5xw.Edge> updateEdge(
    String graphId,
    int expectedGraphVersion,
    _i63byxc2.MapEdgeInput edge,
  ) => caller.callServerEndpoint<_i71va5xw.Edge>(
    'mapEdge',
    'updateEdge',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'edge': edge,
    },
  );

  _ida.Future<void> deleteEdge(
    String graphId,
    int expectedGraphVersion,
    String edgeId,
  ) => caller.callServerEndpoint<void>(
    'mapEdge',
    'deleteEdge',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'edgeId': edgeId,
    },
  );
}

/// {@category Endpoint}
class EndpointMapGraph extends _isc.EndpointRef {
  EndpointMapGraph(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mapGraph';

  _ida.Future<_igef8xkz.MapGraphSnapshot> createGraph(
    _ik7sj57u.CreateGraphRequest request,
  ) => caller.callServerEndpoint<_igef8xkz.MapGraphSnapshot>(
    'mapGraph',
    'createGraph',
    {'request': request},
  );

  _ida.Future<_ijpyrqq0.GraphReadResult> getGraph(
    String graphId,
    int? ifVersion,
  ) => caller.callServerEndpoint<_ijpyrqq0.GraphReadResult>(
    'mapGraph',
    'getGraph',
    {
      'graphId': graphId,
      'ifVersion': ifVersion,
    },
  );

  _ida.Future<List<_i5ydwcda.MapGraph>> listGraphs(
    String? buildingId,
    int limit,
    int offset,
  ) => caller.callServerEndpoint<List<_i5ydwcda.MapGraph>>(
    'mapGraph',
    'listGraphs',
    {
      'buildingId': buildingId,
      'limit': limit,
      'offset': offset,
    },
  );

  _ida.Future<_igef8xkz.MapGraphSnapshot> patchGraph(
    _iq2332iw.GraphPatchRequest request,
  ) => caller.callServerEndpoint<_igef8xkz.MapGraphSnapshot>(
    'mapGraph',
    'patchGraph',
    {'request': request},
  );

  _ida.Future<_igef8xkz.MapGraphSnapshot> replaceGraph(
    _iwd56web.ReplaceGraphRequest request,
  ) => caller.callServerEndpoint<_igef8xkz.MapGraphSnapshot>(
    'mapGraph',
    'replaceGraph',
    {'request': request},
  );

  _ida.Future<void> deleteGraph(
    String graphId,
    int expectedVersion,
  ) => caller.callServerEndpoint<void>(
    'mapGraph',
    'deleteGraph',
    {
      'graphId': graphId,
      'expectedVersion': expectedVersion,
    },
  );
}

/// {@category Endpoint}
class EndpointMapNode extends _isc.EndpointRef {
  EndpointMapNode(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mapNode';

  _ida.Future<_i6rsjj6d.Nodes> createNode(
    String graphId,
    int expectedGraphVersion,
    _iknlbgoc.MapNodeInput node,
  ) => caller.callServerEndpoint<_i6rsjj6d.Nodes>(
    'mapNode',
    'createNode',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'node': node,
    },
  );

  /// Creates a routable contribution atomically. This is the normal creation
  /// path after a graph has been seeded because active nodes must be connected.
  _ida.Future<_igef8xkz.MapGraphSnapshot> createNodeWithConnections(
    String graphId,
    int expectedGraphVersion,
    _iknlbgoc.MapNodeInput node,
    List<_i63byxc2.MapEdgeInput> edges,
    _i9u1r3i1.LocationInput? location,
  ) => caller.callServerEndpoint<_igef8xkz.MapGraphSnapshot>(
    'mapNode',
    'createNodeWithConnections',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'node': node,
      'edges': edges,
      'location': location,
    },
  );

  _ida.Future<_i6rsjj6d.Nodes?> getNode(
    String graphId,
    String nodeId,
  ) => caller.callServerEndpoint<_i6rsjj6d.Nodes?>(
    'mapNode',
    'getNode',
    {
      'graphId': graphId,
      'nodeId': nodeId,
    },
  );

  _ida.Future<List<_i6rsjj6d.Nodes>> listNodes(
    String graphId,
    int? floorNumber,
  ) => caller.callServerEndpoint<List<_i6rsjj6d.Nodes>>(
    'mapNode',
    'listNodes',
    {
      'graphId': graphId,
      'floorNumber': floorNumber,
    },
  );

  _ida.Future<_i6rsjj6d.Nodes> updateNode(
    String graphId,
    int expectedGraphVersion,
    _iknlbgoc.MapNodeInput node,
  ) => caller.callServerEndpoint<_i6rsjj6d.Nodes>(
    'mapNode',
    'updateNode',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'node': node,
    },
  );

  _ida.Future<void> deleteNode(
    String graphId,
    int expectedGraphVersion,
    String nodeId,
  ) => caller.callServerEndpoint<void>(
    'mapNode',
    'deleteNode',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'nodeId': nodeId,
    },
  );
}

/// {@category Endpoint}
class EndpointMapReport extends _isc.EndpointRef {
  EndpointMapReport(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mapReport';

  _ida.Future<_i5b93lv5.MapReport> reportEntity(
    _iws3unv8.ReportTargetType targetType,
    String targetId,
    _i6ynwlr2.ReportReason reason,
    String? notes,
  ) => caller.callServerEndpoint<_i5b93lv5.MapReport>(
    'mapReport',
    'reportEntity',
    {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'notes': notes,
    },
  );

  _ida.Future<List<_i5b93lv5.MapReport>> listMyReports(
    int limit,
    int offset,
  ) => caller.callServerEndpoint<List<_i5b93lv5.MapReport>>(
    'mapReport',
    'listMyReports',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  _ida.Future<_i5b93lv5.MapReport> withdrawReport(String reportId) =>
      caller.callServerEndpoint<_i5b93lv5.MapReport>(
        'mapReport',
        'withdrawReport',
        {'reportId': reportId},
      );
}

/// {@category Endpoint}
class EndpointGreeting extends _isc.EndpointRef {
  EndpointGreeting(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  _ida.Future<_igi1f61t.Greeting> hello(String name) =>
      caller.callServerEndpoint<_igi1f61t.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    building = EndpointBuilding(this);
    location = EndpointLocation(this);
    locationSearch = EndpointLocationSearch(this);
    mapEdge = EndpointMapEdge(this);
    mapGraph = EndpointMapGraph(this);
    mapNode = EndpointMapNode(this);
    mapReport = EndpointMapReport(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointBuilding building;

  late final EndpointLocation location;

  late final EndpointLocationSearch locationSearch;

  late final EndpointMapEdge mapEdge;

  late final EndpointMapGraph mapGraph;

  late final EndpointMapNode mapNode;

  late final EndpointMapReport mapReport;

  late final EndpointGreeting greeting;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'building': building,
    'location': location,
    'locationSearch': locationSearch,
    'mapEdge': mapEdge,
    'mapGraph': mapGraph,
    'mapNode': mapNode,
    'mapReport': mapReport,
    'greeting': greeting,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {};
}
