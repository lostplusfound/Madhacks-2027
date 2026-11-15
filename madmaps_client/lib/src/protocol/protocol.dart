/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:madmaps_client/src/protocol/ar_capture.dart' as _i1pvqriv;
import 'package:madmaps_client/src/protocol/building.dart' as _ixxicett;
import 'package:madmaps_client/src/protocol/edge.dart' as _i71va5xw;
import 'package:madmaps_client/src/protocol/floor_connector.dart' as _ik47qssa;
import 'package:madmaps_client/src/protocol/location_category.dart'
    as _iosiyc7r;
import 'package:madmaps_client/src/protocol/locations.dart' as _iwfkkrvw;
import 'package:madmaps_client/src/protocol/map_edge_input.dart' as _i63byxc2;
import 'package:madmaps_client/src/protocol/map_graph.dart' as _i5ydwcda;
import 'package:madmaps_client/src/protocol/map_report.dart' as _i5b93lv5;
import 'package:madmaps_client/src/protocol/node.dart' as _i6rsjj6d;
import 'package:madmaps_client/src/protocol/place_map_summary.dart'
    as _iv0t8d6t;
import 'package:madmaps_client/src/protocol/search_result.dart' as _i56rwuj1;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'ar_capture.dart' as _i16jxfx1;
import 'building.dart' as _icdi8t76;
import 'create_graph_request.dart' as _ihh4bgnv;
import 'edge.dart' as _ilmyslsx;
import 'edge_type.dart' as _iv43g6lk;
import 'floor.dart' as _ibt68ans;
import 'floor_connector.dart' as _it6qy5v4;
import 'floor_input.dart' as _i647gghf;
import 'graph_patch_request.dart' as _iv9rsso3;
import 'graph_read_result.dart' as _iu1utyem;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'kind.dart' as _iokugpqm;
import 'location_category.dart' as _ipivyxsl;
import 'location_input.dart' as _iaviofrw;
import 'locations.dart' as _iy2kpyso;
import 'map_api_exception.dart' as _igm7lgul;
import 'map_edge_input.dart' as _ipndifli;
import 'map_entity_status.dart' as _itjn1vsu;
import 'map_graph.dart' as _ikb2yia4;
import 'map_graph_snapshot.dart' as _iuswi8s2;
import 'map_node_input.dart' as _i3qve637;
import 'map_report.dart' as _iictijcz;
import 'map_wall.dart' as _i064s9h8;
import 'node.dart' as _i9tve71o;
import 'place_map.dart' as _ix1zgdio;
import 'place_map_summary.dart' as _ircy7gpu;
import 'replace_graph_request.dart' as _iz7e8f0p;
import 'report_reason.dart' as _ijgj7dn0;
import 'report_status.dart' as _i8pcsu0p;
import 'report_target_type.dart' as _iyydfyiu;
import 'search_result.dart' as _ifcih7a1;
import 'wall_input.dart' as _icks2m2l;
import 'wall_point.dart' as _inoptxl6;
export 'ar_capture.dart';
export 'building.dart';
export 'create_graph_request.dart';
export 'edge.dart';
export 'edge_type.dart';
export 'floor.dart';
export 'floor_connector.dart';
export 'floor_input.dart';
export 'graph_patch_request.dart';
export 'graph_read_result.dart';
export 'greetings/greeting.dart';
export 'kind.dart';
export 'location_category.dart';
export 'location_input.dart';
export 'locations.dart';
export 'map_api_exception.dart';
export 'map_edge_input.dart';
export 'map_entity_status.dart';
export 'map_graph.dart';
export 'map_graph_snapshot.dart';
export 'map_node_input.dart';
export 'map_report.dart';
export 'map_wall.dart';
export 'node.dart';
export 'place_map.dart';
export 'place_map_summary.dart';
export 'replace_graph_request.dart';
export 'report_reason.dart';
export 'report_status.dart';
export 'report_target_type.dart';
export 'search_result.dart';
export 'wall_input.dart';
export 'wall_point.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager
    implements _isc.ProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  @override
  _isc.ProtocolDeserialization get deserializationMetadata =>
      _isc.ProtocolDeserialization.cached(
        this,
        types: const [
          _isc.getType<_i16jxfx1.ArCapture>,
          _isc.getType<_icdi8t76.Building>,
          _isc.getType<_ihh4bgnv.CreateGraphRequest>,
          _isc.getType<_ilmyslsx.Edge>,
          _isc.getType<_iv43g6lk.EdgeType>,
          _isc.getType<_ibt68ans.Floor>,
          _isc.getType<_it6qy5v4.FloorConnector>,
          _isc.getType<_i647gghf.FloorInput>,
          _isc.getType<_iv9rsso3.GraphPatchRequest>,
          _isc.getType<_iu1utyem.GraphReadResult>,
          _isc.getType<_izw8z7ou.Greeting>,
          _isc.getType<_iokugpqm.Kind>,
          _isc.getType<_ipivyxsl.LocationCategory>,
          _isc.getType<_iaviofrw.LocationInput>,
          _isc.getType<_iy2kpyso.Locations>,
          _isc.getType<_igm7lgul.MapApiException>,
          _isc.getType<_ipndifli.MapEdgeInput>,
          _isc.getType<_itjn1vsu.MapEntityStatus>,
          _isc.getType<_ikb2yia4.MapGraph>,
          _isc.getType<_iuswi8s2.MapGraphSnapshot>,
          _isc.getType<_i3qve637.MapNodeInput>,
          _isc.getType<_iictijcz.MapReport>,
          _isc.getType<_i064s9h8.MapWall>,
          _isc.getType<_i9tve71o.Nodes>,
          _isc.getType<_ix1zgdio.PlaceMap>,
          _isc.getType<_ircy7gpu.PlaceMapSummary>,
          _isc.getType<_iz7e8f0p.ReplaceGraphRequest>,
          _isc.getType<_ijgj7dn0.ReportReason>,
          _isc.getType<_i8pcsu0p.ReportStatus>,
          _isc.getType<_iyydfyiu.ReportTargetType>,
          _isc.getType<_ifcih7a1.SearchResult>,
          _isc.getType<_icks2m2l.WallInput>,
          _isc.getType<_inoptxl6.WallPoint>,
          _isc.getType<_i16jxfx1.ArCapture?>,
          _isc.getType<_icdi8t76.Building?>,
          _isc.getType<_ihh4bgnv.CreateGraphRequest?>,
          _isc.getType<_ilmyslsx.Edge?>,
          _isc.getType<_iv43g6lk.EdgeType?>,
          _isc.getType<_ibt68ans.Floor?>,
          _isc.getType<_it6qy5v4.FloorConnector?>,
          _isc.getType<_i647gghf.FloorInput?>,
          _isc.getType<_iv9rsso3.GraphPatchRequest?>,
          _isc.getType<_iu1utyem.GraphReadResult?>,
          _isc.getType<_izw8z7ou.Greeting?>,
          _isc.getType<_iokugpqm.Kind?>,
          _isc.getType<_ipivyxsl.LocationCategory?>,
          _isc.getType<_iaviofrw.LocationInput?>,
          _isc.getType<_iy2kpyso.Locations?>,
          _isc.getType<_igm7lgul.MapApiException?>,
          _isc.getType<_ipndifli.MapEdgeInput?>,
          _isc.getType<_itjn1vsu.MapEntityStatus?>,
          _isc.getType<_ikb2yia4.MapGraph?>,
          _isc.getType<_iuswi8s2.MapGraphSnapshot?>,
          _isc.getType<_i3qve637.MapNodeInput?>,
          _isc.getType<_iictijcz.MapReport?>,
          _isc.getType<_i064s9h8.MapWall?>,
          _isc.getType<_i9tve71o.Nodes?>,
          _isc.getType<_ix1zgdio.PlaceMap?>,
          _isc.getType<_ircy7gpu.PlaceMapSummary?>,
          _isc.getType<_iz7e8f0p.ReplaceGraphRequest?>,
          _isc.getType<_ijgj7dn0.ReportReason?>,
          _isc.getType<_i8pcsu0p.ReportStatus?>,
          _isc.getType<_iyydfyiu.ReportTargetType?>,
          _isc.getType<_ifcih7a1.SearchResult?>,
          _isc.getType<_icks2m2l.WallInput?>,
          _isc.getType<_inoptxl6.WallPoint?>,
          _isc.getType<List<_i647gghf.FloorInput>>,
          _isc.getType<List<_i3qve637.MapNodeInput>>,
          _isc.getType<List<_ipndifli.MapEdgeInput>>,
          _isc.getType<List<_iaviofrw.LocationInput>>,
          _isc.getType<List<_icks2m2l.WallInput>>,
          _isc.getType<List<_icks2m2l.WallInput>?>,
          _isc.getType<List<String>>,
          _isc.getType<List<_ibt68ans.Floor>>,
          _isc.getType<List<_i9tve71o.Nodes>>,
          _isc.getType<List<_ilmyslsx.Edge>>,
          _isc.getType<List<_iy2kpyso.Locations>>,
          _isc.getType<List<_inoptxl6.WallPoint>>,
          _isc.getType<List<_ixxicett.Building>>,
          _isc.getType<List<_ik47qssa.FloorConnector>>,
          _isc.getType<List<_i1pvqriv.ArCapture>>,
          _isc.getType<List<_iwfkkrvw.Locations>>,
          _isc.getType<List<_i56rwuj1.SearchResult>>,
          _isc.getType<List<_iosiyc7r.LocationCategory>>,
          _isc.getType<List<_i71va5xw.Edge>>,
          _isc.getType<List<_i5ydwcda.MapGraph>>,
          _isc.getType<List<_i63byxc2.MapEdgeInput>>,
          _isc.getType<List<_i6rsjj6d.Nodes>>,
          _isc.getType<List<_i5b93lv5.MapReport>>,
          _isc.getType<List<_iv0t8d6t.PlaceMapSummary>>,
        ],
        modules: const [
          _iaic.Protocol.new,
          _iacc.Protocol.new,
        ],
        classNames: const [
          'ArCapture',
          'Building',
          'CreateGraphRequest',
          'Edge',
          'EdgeType',
          'Floor',
          'FloorConnector',
          'FloorInput',
          'GraphPatchRequest',
          'GraphReadResult',
          'Greeting',
          'Kind',
          'LocationCategory',
          'LocationInput',
          'Locations',
          'MapApiException',
          'MapEdgeInput',
          'MapEntityStatus',
          'MapGraph',
          'MapGraphSnapshot',
          'MapNodeInput',
          'MapReport',
          'MapWall',
          'Nodes',
          'PlaceMap',
          'PlaceMapSummary',
          'ReplaceGraphRequest',
          'ReportReason',
          'ReportStatus',
          'ReportTargetType',
          'SearchResult',
          'WallInput',
          'WallPoint',
        ],
      );

  static String? getClassNameFromObjectJson(dynamic data) =>
      _isc.ProtocolDeserialization.readClassName(data);

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    final rawDataClassName = _isc.ProtocolDeserialization.readClassName(data);
    final dataClassName = rawDataClassName;
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i16jxfx1.ArCapture) {
      return _i16jxfx1.ArCapture.fromJson(data) as T;
    }
    if (t == _icdi8t76.Building) {
      return _icdi8t76.Building.fromJson(data) as T;
    }
    if (t == _ihh4bgnv.CreateGraphRequest) {
      return _ihh4bgnv.CreateGraphRequest.fromJson(data) as T;
    }
    if (t == _ilmyslsx.Edge) {
      return _ilmyslsx.Edge.fromJson(data) as T;
    }
    if (t == _iv43g6lk.EdgeType) {
      return _iv43g6lk.EdgeType.fromJson(data) as T;
    }
    if (t == _ibt68ans.Floor) {
      return _ibt68ans.Floor.fromJson(data) as T;
    }
    if (t == _it6qy5v4.FloorConnector) {
      return _it6qy5v4.FloorConnector.fromJson(data) as T;
    }
    if (t == _i647gghf.FloorInput) {
      return _i647gghf.FloorInput.fromJson(data) as T;
    }
    if (t == _iv9rsso3.GraphPatchRequest) {
      return _iv9rsso3.GraphPatchRequest.fromJson(data) as T;
    }
    if (t == _iu1utyem.GraphReadResult) {
      return _iu1utyem.GraphReadResult.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _iokugpqm.Kind) {
      return _iokugpqm.Kind.fromJson(data) as T;
    }
    if (t == _ipivyxsl.LocationCategory) {
      return _ipivyxsl.LocationCategory.fromJson(data) as T;
    }
    if (t == _iaviofrw.LocationInput) {
      return _iaviofrw.LocationInput.fromJson(data) as T;
    }
    if (t == _iy2kpyso.Locations) {
      return _iy2kpyso.Locations.fromJson(data) as T;
    }
    if (t == _igm7lgul.MapApiException) {
      return _igm7lgul.MapApiException.fromJson(data) as T;
    }
    if (t == _ipndifli.MapEdgeInput) {
      return _ipndifli.MapEdgeInput.fromJson(data) as T;
    }
    if (t == _itjn1vsu.MapEntityStatus) {
      return _itjn1vsu.MapEntityStatus.fromJson(data) as T;
    }
    if (t == _ikb2yia4.MapGraph) {
      return _ikb2yia4.MapGraph.fromJson(data) as T;
    }
    if (t == _iuswi8s2.MapGraphSnapshot) {
      return _iuswi8s2.MapGraphSnapshot.fromJson(data) as T;
    }
    if (t == _i3qve637.MapNodeInput) {
      return _i3qve637.MapNodeInput.fromJson(data) as T;
    }
    if (t == _iictijcz.MapReport) {
      return _iictijcz.MapReport.fromJson(data) as T;
    }
    if (t == _i064s9h8.MapWall) {
      return _i064s9h8.MapWall.fromJson(data) as T;
    }
    if (t == _i9tve71o.Nodes) {
      return _i9tve71o.Nodes.fromJson(data) as T;
    }
    if (t == _ix1zgdio.PlaceMap) {
      return _ix1zgdio.PlaceMap.fromJson(data) as T;
    }
    if (t == _ircy7gpu.PlaceMapSummary) {
      return _ircy7gpu.PlaceMapSummary.fromJson(data) as T;
    }
    if (t == _iz7e8f0p.ReplaceGraphRequest) {
      return _iz7e8f0p.ReplaceGraphRequest.fromJson(data) as T;
    }
    if (t == _ijgj7dn0.ReportReason) {
      return _ijgj7dn0.ReportReason.fromJson(data) as T;
    }
    if (t == _i8pcsu0p.ReportStatus) {
      return _i8pcsu0p.ReportStatus.fromJson(data) as T;
    }
    if (t == _iyydfyiu.ReportTargetType) {
      return _iyydfyiu.ReportTargetType.fromJson(data) as T;
    }
    if (t == _ifcih7a1.SearchResult) {
      return _ifcih7a1.SearchResult.fromJson(data) as T;
    }
    if (t == _icks2m2l.WallInput) {
      return _icks2m2l.WallInput.fromJson(data) as T;
    }
    if (t == _inoptxl6.WallPoint) {
      return _inoptxl6.WallPoint.fromJson(data) as T;
    }
    if (t == _isc.getType<_i16jxfx1.ArCapture?>()) {
      return (data != null ? _i16jxfx1.ArCapture.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_icdi8t76.Building?>()) {
      return (data != null ? _icdi8t76.Building.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ihh4bgnv.CreateGraphRequest?>()) {
      return (data != null ? _ihh4bgnv.CreateGraphRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ilmyslsx.Edge?>()) {
      return (data != null ? _ilmyslsx.Edge.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iv43g6lk.EdgeType?>()) {
      return (data != null ? _iv43g6lk.EdgeType.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ibt68ans.Floor?>()) {
      return (data != null ? _ibt68ans.Floor.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_it6qy5v4.FloorConnector?>()) {
      return (data != null ? _it6qy5v4.FloorConnector.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i647gghf.FloorInput?>()) {
      return (data != null ? _i647gghf.FloorInput.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iv9rsso3.GraphPatchRequest?>()) {
      return (data != null ? _iv9rsso3.GraphPatchRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iu1utyem.GraphReadResult?>()) {
      return (data != null ? _iu1utyem.GraphReadResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iokugpqm.Kind?>()) {
      return (data != null ? _iokugpqm.Kind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ipivyxsl.LocationCategory?>()) {
      return (data != null ? _ipivyxsl.LocationCategory.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iaviofrw.LocationInput?>()) {
      return (data != null ? _iaviofrw.LocationInput.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iy2kpyso.Locations?>()) {
      return (data != null ? _iy2kpyso.Locations.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_igm7lgul.MapApiException?>()) {
      return (data != null ? _igm7lgul.MapApiException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ipndifli.MapEdgeInput?>()) {
      return (data != null ? _ipndifli.MapEdgeInput.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_itjn1vsu.MapEntityStatus?>()) {
      return (data != null ? _itjn1vsu.MapEntityStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ikb2yia4.MapGraph?>()) {
      return (data != null ? _ikb2yia4.MapGraph.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iuswi8s2.MapGraphSnapshot?>()) {
      return (data != null ? _iuswi8s2.MapGraphSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i3qve637.MapNodeInput?>()) {
      return (data != null ? _i3qve637.MapNodeInput.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iictijcz.MapReport?>()) {
      return (data != null ? _iictijcz.MapReport.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i064s9h8.MapWall?>()) {
      return (data != null ? _i064s9h8.MapWall.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i9tve71o.Nodes?>()) {
      return (data != null ? _i9tve71o.Nodes.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ix1zgdio.PlaceMap?>()) {
      return (data != null ? _ix1zgdio.PlaceMap.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ircy7gpu.PlaceMapSummary?>()) {
      return (data != null ? _ircy7gpu.PlaceMapSummary.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iz7e8f0p.ReplaceGraphRequest?>()) {
      return (data != null
              ? _iz7e8f0p.ReplaceGraphRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ijgj7dn0.ReportReason?>()) {
      return (data != null ? _ijgj7dn0.ReportReason.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i8pcsu0p.ReportStatus?>()) {
      return (data != null ? _i8pcsu0p.ReportStatus.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iyydfyiu.ReportTargetType?>()) {
      return (data != null ? _iyydfyiu.ReportTargetType.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ifcih7a1.SearchResult?>()) {
      return (data != null ? _ifcih7a1.SearchResult.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_icks2m2l.WallInput?>()) {
      return (data != null ? _icks2m2l.WallInput.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_inoptxl6.WallPoint?>()) {
      return (data != null ? _inoptxl6.WallPoint.fromJson(data) : null) as T;
    }
    if (t == List<_i647gghf.FloorInput>) {
      return (data as List)
              .map((e) => deserialize<_i647gghf.FloorInput>(e))
              .toList()
          as T;
    }
    if (t == List<_i3qve637.MapNodeInput>) {
      return (data as List)
              .map((e) => deserialize<_i3qve637.MapNodeInput>(e))
              .toList()
          as T;
    }
    if (t == List<_ipndifli.MapEdgeInput>) {
      return (data as List)
              .map((e) => deserialize<_ipndifli.MapEdgeInput>(e))
              .toList()
          as T;
    }
    if (t == List<_iaviofrw.LocationInput>) {
      return (data as List)
              .map((e) => deserialize<_iaviofrw.LocationInput>(e))
              .toList()
          as T;
    }
    if (t == List<_icks2m2l.WallInput>) {
      return (data as List)
              .map((e) => deserialize<_icks2m2l.WallInput>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_icks2m2l.WallInput>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_icks2m2l.WallInput>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_ibt68ans.Floor>) {
      return (data as List).map((e) => deserialize<_ibt68ans.Floor>(e)).toList()
          as T;
    }
    if (t == List<_i9tve71o.Nodes>) {
      return (data as List).map((e) => deserialize<_i9tve71o.Nodes>(e)).toList()
          as T;
    }
    if (t == List<_ilmyslsx.Edge>) {
      return (data as List).map((e) => deserialize<_ilmyslsx.Edge>(e)).toList()
          as T;
    }
    if (t == List<_iy2kpyso.Locations>) {
      return (data as List)
              .map((e) => deserialize<_iy2kpyso.Locations>(e))
              .toList()
          as T;
    }
    if (t == List<_inoptxl6.WallPoint>) {
      return (data as List)
              .map((e) => deserialize<_inoptxl6.WallPoint>(e))
              .toList()
          as T;
    }
    if (t == List<_ixxicett.Building>) {
      return (data as List)
              .map((e) => deserialize<_ixxicett.Building>(e))
              .toList()
          as T;
    }
    if (t == List<_ik47qssa.FloorConnector>) {
      return (data as List)
              .map((e) => deserialize<_ik47qssa.FloorConnector>(e))
              .toList()
          as T;
    }
    if (t == List<_i1pvqriv.ArCapture>) {
      return (data as List)
              .map((e) => deserialize<_i1pvqriv.ArCapture>(e))
              .toList()
          as T;
    }
    if (t == List<_iwfkkrvw.Locations>) {
      return (data as List)
              .map((e) => deserialize<_iwfkkrvw.Locations>(e))
              .toList()
          as T;
    }
    if (t == List<_i56rwuj1.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i56rwuj1.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == List<_iosiyc7r.LocationCategory>) {
      return (data as List)
              .map((e) => deserialize<_iosiyc7r.LocationCategory>(e))
              .toList()
          as T;
    }
    if (t == List<_i71va5xw.Edge>) {
      return (data as List).map((e) => deserialize<_i71va5xw.Edge>(e)).toList()
          as T;
    }
    if (t == List<_i5ydwcda.MapGraph>) {
      return (data as List)
              .map((e) => deserialize<_i5ydwcda.MapGraph>(e))
              .toList()
          as T;
    }
    if (t == List<_i63byxc2.MapEdgeInput>) {
      return (data as List)
              .map((e) => deserialize<_i63byxc2.MapEdgeInput>(e))
              .toList()
          as T;
    }
    if (t == List<_i6rsjj6d.Nodes>) {
      return (data as List).map((e) => deserialize<_i6rsjj6d.Nodes>(e)).toList()
          as T;
    }
    if (t == List<_i5b93lv5.MapReport>) {
      return (data as List)
              .map((e) => deserialize<_i5b93lv5.MapReport>(e))
              .toList()
          as T;
    }
    if (t == List<_iv0t8d6t.PlaceMapSummary>) {
      return (data as List)
              .map((e) => deserialize<_iv0t8d6t.PlaceMapSummary>(e))
              .toList()
          as T;
    }
    final modules = deserializationMetadata.modulesForDeserialization(
      t,
      className: rawDataClassName,
    );
    for (final module in modules) {
      try {
        return module.deserialize<T>(data, t);
      } on _isc.DeserializationTypeNotFoundException catch (_) {}
    }

    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i16jxfx1.ArCapture => 'ArCapture',
      _icdi8t76.Building => 'Building',
      _ihh4bgnv.CreateGraphRequest => 'CreateGraphRequest',
      _ilmyslsx.Edge => 'Edge',
      _iv43g6lk.EdgeType => 'EdgeType',
      _ibt68ans.Floor => 'Floor',
      _it6qy5v4.FloorConnector => 'FloorConnector',
      _i647gghf.FloorInput => 'FloorInput',
      _iv9rsso3.GraphPatchRequest => 'GraphPatchRequest',
      _iu1utyem.GraphReadResult => 'GraphReadResult',
      _izw8z7ou.Greeting => 'Greeting',
      _iokugpqm.Kind => 'Kind',
      _ipivyxsl.LocationCategory => 'LocationCategory',
      _iaviofrw.LocationInput => 'LocationInput',
      _iy2kpyso.Locations => 'Locations',
      _igm7lgul.MapApiException => 'MapApiException',
      _ipndifli.MapEdgeInput => 'MapEdgeInput',
      _itjn1vsu.MapEntityStatus => 'MapEntityStatus',
      _ikb2yia4.MapGraph => 'MapGraph',
      _iuswi8s2.MapGraphSnapshot => 'MapGraphSnapshot',
      _i3qve637.MapNodeInput => 'MapNodeInput',
      _iictijcz.MapReport => 'MapReport',
      _i064s9h8.MapWall => 'MapWall',
      _i9tve71o.Nodes => 'Nodes',
      _ix1zgdio.PlaceMap => 'PlaceMap',
      _ircy7gpu.PlaceMapSummary => 'PlaceMapSummary',
      _iz7e8f0p.ReplaceGraphRequest => 'ReplaceGraphRequest',
      _ijgj7dn0.ReportReason => 'ReportReason',
      _i8pcsu0p.ReportStatus => 'ReportStatus',
      _iyydfyiu.ReportTargetType => 'ReportTargetType',
      _ifcih7a1.SearchResult => 'SearchResult',
      _icks2m2l.WallInput => 'WallInput',
      _inoptxl6.WallPoint => 'WallPoint',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('madmaps.', '');
    }

    switch (data) {
      case _i16jxfx1.ArCapture():
        return 'ArCapture';
      case _icdi8t76.Building():
        return 'Building';
      case _ihh4bgnv.CreateGraphRequest():
        return 'CreateGraphRequest';
      case _ilmyslsx.Edge():
        return 'Edge';
      case _iv43g6lk.EdgeType():
        return 'EdgeType';
      case _ibt68ans.Floor():
        return 'Floor';
      case _it6qy5v4.FloorConnector():
        return 'FloorConnector';
      case _i647gghf.FloorInput():
        return 'FloorInput';
      case _iv9rsso3.GraphPatchRequest():
        return 'GraphPatchRequest';
      case _iu1utyem.GraphReadResult():
        return 'GraphReadResult';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _iokugpqm.Kind():
        return 'Kind';
      case _ipivyxsl.LocationCategory():
        return 'LocationCategory';
      case _iaviofrw.LocationInput():
        return 'LocationInput';
      case _iy2kpyso.Locations():
        return 'Locations';
      case _igm7lgul.MapApiException():
        return 'MapApiException';
      case _ipndifli.MapEdgeInput():
        return 'MapEdgeInput';
      case _itjn1vsu.MapEntityStatus():
        return 'MapEntityStatus';
      case _ikb2yia4.MapGraph():
        return 'MapGraph';
      case _iuswi8s2.MapGraphSnapshot():
        return 'MapGraphSnapshot';
      case _i3qve637.MapNodeInput():
        return 'MapNodeInput';
      case _iictijcz.MapReport():
        return 'MapReport';
      case _i064s9h8.MapWall():
        return 'MapWall';
      case _i9tve71o.Nodes():
        return 'Nodes';
      case _ix1zgdio.PlaceMap():
        return 'PlaceMap';
      case _ircy7gpu.PlaceMapSummary():
        return 'PlaceMapSummary';
      case _iz7e8f0p.ReplaceGraphRequest():
        return 'ReplaceGraphRequest';
      case _ijgj7dn0.ReportReason():
        return 'ReportReason';
      case _i8pcsu0p.ReportStatus():
        return 'ReportStatus';
      case _iyydfyiu.ReportTargetType():
        return 'ReportTargetType';
      case _ifcih7a1.SearchResult():
        return 'SearchResult';
      case _icks2m2l.WallInput():
        return 'WallInput';
      case _inoptxl6.WallPoint():
        return 'WallPoint';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ArCapture') {
      return deserialize<_i16jxfx1.ArCapture>(data['data']);
    }
    if (dataClassName == 'Building') {
      return deserialize<_icdi8t76.Building>(data['data']);
    }
    if (dataClassName == 'CreateGraphRequest') {
      return deserialize<_ihh4bgnv.CreateGraphRequest>(data['data']);
    }
    if (dataClassName == 'Edge') {
      return deserialize<_ilmyslsx.Edge>(data['data']);
    }
    if (dataClassName == 'EdgeType') {
      return deserialize<_iv43g6lk.EdgeType>(data['data']);
    }
    if (dataClassName == 'Floor') {
      return deserialize<_ibt68ans.Floor>(data['data']);
    }
    if (dataClassName == 'FloorConnector') {
      return deserialize<_it6qy5v4.FloorConnector>(data['data']);
    }
    if (dataClassName == 'FloorInput') {
      return deserialize<_i647gghf.FloorInput>(data['data']);
    }
    if (dataClassName == 'GraphPatchRequest') {
      return deserialize<_iv9rsso3.GraphPatchRequest>(data['data']);
    }
    if (dataClassName == 'GraphReadResult') {
      return deserialize<_iu1utyem.GraphReadResult>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'Kind') {
      return deserialize<_iokugpqm.Kind>(data['data']);
    }
    if (dataClassName == 'LocationCategory') {
      return deserialize<_ipivyxsl.LocationCategory>(data['data']);
    }
    if (dataClassName == 'LocationInput') {
      return deserialize<_iaviofrw.LocationInput>(data['data']);
    }
    if (dataClassName == 'Locations') {
      return deserialize<_iy2kpyso.Locations>(data['data']);
    }
    if (dataClassName == 'MapApiException') {
      return deserialize<_igm7lgul.MapApiException>(data['data']);
    }
    if (dataClassName == 'MapEdgeInput') {
      return deserialize<_ipndifli.MapEdgeInput>(data['data']);
    }
    if (dataClassName == 'MapEntityStatus') {
      return deserialize<_itjn1vsu.MapEntityStatus>(data['data']);
    }
    if (dataClassName == 'MapGraph') {
      return deserialize<_ikb2yia4.MapGraph>(data['data']);
    }
    if (dataClassName == 'MapGraphSnapshot') {
      return deserialize<_iuswi8s2.MapGraphSnapshot>(data['data']);
    }
    if (dataClassName == 'MapNodeInput') {
      return deserialize<_i3qve637.MapNodeInput>(data['data']);
    }
    if (dataClassName == 'MapReport') {
      return deserialize<_iictijcz.MapReport>(data['data']);
    }
    if (dataClassName == 'MapWall') {
      return deserialize<_i064s9h8.MapWall>(data['data']);
    }
    if (dataClassName == 'Nodes') {
      return deserialize<_i9tve71o.Nodes>(data['data']);
    }
    if (dataClassName == 'PlaceMap') {
      return deserialize<_ix1zgdio.PlaceMap>(data['data']);
    }
    if (dataClassName == 'PlaceMapSummary') {
      return deserialize<_ircy7gpu.PlaceMapSummary>(data['data']);
    }
    if (dataClassName == 'ReplaceGraphRequest') {
      return deserialize<_iz7e8f0p.ReplaceGraphRequest>(data['data']);
    }
    if (dataClassName == 'ReportReason') {
      return deserialize<_ijgj7dn0.ReportReason>(data['data']);
    }
    if (dataClassName == 'ReportStatus') {
      return deserialize<_i8pcsu0p.ReportStatus>(data['data']);
    }
    if (dataClassName == 'ReportTargetType') {
      return deserialize<_iyydfyiu.ReportTargetType>(data['data']);
    }
    if (dataClassName == 'SearchResult') {
      return deserialize<_ifcih7a1.SearchResult>(data['data']);
    }
    if (dataClassName == 'WallInput') {
      return deserialize<_icks2m2l.WallInput>(data['data']);
    }
    if (dataClassName == 'WallPoint') {
      return deserialize<_inoptxl6.WallPoint>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      return _iaic.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(19),
      });
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      return _iacc.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(20),
      });
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('madmaps', this);
    _iacc.Protocol().registerHostProtocol('madmaps', this);
  }

  @override
  String getModuleName() => 'madmaps';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
