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
import 'package:madmaps_client/src/protocol/protocol.dart' as _isgyuksw;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'building.dart' as _icdi8t76;
import 'edge.dart' as _ilmyslsx;
import 'floor.dart' as _ibt68ans;
import 'locations.dart' as _iy2kpyso;
import 'map_graph.dart' as _ikb2yia4;
import 'node.dart' as _i9tve71o;

abstract class MapGraphSnapshot
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MapGraphSnapshot._({
    required this.graph,
    required this.building,
    required this.floors,
    required this.nodes,
    required this.edges,
    required this.locations,
  });

  factory MapGraphSnapshot({
    required _ikb2yia4.MapGraph graph,
    required _icdi8t76.Building building,
    required List<_ibt68ans.Floor> floors,
    required List<_i9tve71o.Nodes> nodes,
    required List<_ilmyslsx.Edge> edges,
    required List<_iy2kpyso.Locations> locations,
  }) = _MapGraphSnapshotImpl;

  factory MapGraphSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return MapGraphSnapshot(
      graph: _isgyuksw.Protocol().deserialize<_ikb2yia4.MapGraph>(
        jsonSerialization['graph'],
      ),
      building: _isgyuksw.Protocol().deserialize<_icdi8t76.Building>(
        jsonSerialization['building'],
      ),
      floors: _isgyuksw.Protocol().deserialize<List<_ibt68ans.Floor>>(
        jsonSerialization['floors'],
      ),
      nodes: _isgyuksw.Protocol().deserialize<List<_i9tve71o.Nodes>>(
        jsonSerialization['nodes'],
      ),
      edges: _isgyuksw.Protocol().deserialize<List<_ilmyslsx.Edge>>(
        jsonSerialization['edges'],
      ),
      locations: _isgyuksw.Protocol().deserialize<List<_iy2kpyso.Locations>>(
        jsonSerialization['locations'],
      ),
    );
  }

  _ikb2yia4.MapGraph graph;

  _icdi8t76.Building building;

  List<_ibt68ans.Floor> floors;

  List<_i9tve71o.Nodes> nodes;

  List<_ilmyslsx.Edge> edges;

  List<_iy2kpyso.Locations> locations;

  /// Returns a shallow copy of this [MapGraphSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MapGraphSnapshot copyWith({
    _ikb2yia4.MapGraph? graph,
    _icdi8t76.Building? building,
    List<_ibt68ans.Floor>? floors,
    List<_i9tve71o.Nodes>? nodes,
    List<_ilmyslsx.Edge>? edges,
    List<_iy2kpyso.Locations>? locations,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MapGraphSnapshot',
      'graph': graph.toJson(),
      'building': building.toJson(),
      'floors': floors.toJson(valueToJson: (v) => v.toJson()),
      'nodes': nodes.toJson(valueToJson: (v) => v.toJson()),
      'edges': edges.toJson(valueToJson: (v) => v.toJson()),
      'locations': locations.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MapGraphSnapshot',
      'graph': graph.toJsonForProtocol(),
      'building': building.toJsonForProtocol(),
      'floors': floors.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'nodes': nodes.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'edges': edges.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'locations': locations.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _MapGraphSnapshotImpl extends MapGraphSnapshot {
  _MapGraphSnapshotImpl({
    required _ikb2yia4.MapGraph graph,
    required _icdi8t76.Building building,
    required List<_ibt68ans.Floor> floors,
    required List<_i9tve71o.Nodes> nodes,
    required List<_ilmyslsx.Edge> edges,
    required List<_iy2kpyso.Locations> locations,
  }) : super._(
         graph: graph,
         building: building,
         floors: floors,
         nodes: nodes,
         edges: edges,
         locations: locations,
       );

  /// Returns a shallow copy of this [MapGraphSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MapGraphSnapshot copyWith({
    _ikb2yia4.MapGraph? graph,
    _icdi8t76.Building? building,
    List<_ibt68ans.Floor>? floors,
    List<_i9tve71o.Nodes>? nodes,
    List<_ilmyslsx.Edge>? edges,
    List<_iy2kpyso.Locations>? locations,
  }) {
    return MapGraphSnapshot(
      graph: graph ?? this.graph.copyWith(),
      building: building ?? this.building.copyWith(),
      floors: floors ?? this.floors.map((e0) => e0.copyWith()).toList(),
      nodes: nodes ?? this.nodes.map((e0) => e0.copyWith()).toList(),
      edges: edges ?? this.edges.map((e0) => e0.copyWith()).toList(),
      locations:
          locations ?? this.locations.map((e0) => e0.copyWith()).toList(),
    );
  }
}
