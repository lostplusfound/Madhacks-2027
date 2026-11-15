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
import 'package:madmaps_server/src/generated/protocol.dart' as _i1t1vlhc;
import 'package:serverpod/serverpod.dart' as _is;
import 'building.dart' as _icdi8t76;
import 'edge.dart' as _ilmyslsx;
import 'floor.dart' as _ibt68ans;
import 'locations.dart' as _iy2kpyso;
import 'map_graph.dart' as _ikb2yia4;
import 'node.dart' as _i9tve71o;
import 'wall_input.dart' as _icks2m2l;

abstract class MapGraphSnapshot
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MapGraphSnapshot._({
    required this.graph,
    required this.building,
    required this.floors,
    required this.nodes,
    required this.edges,
    required this.locations,
    required this.walls,
  });

  factory MapGraphSnapshot({
    required _ikb2yia4.MapGraph graph,
    required _icdi8t76.Building building,
    required List<_ibt68ans.Floor> floors,
    required List<_i9tve71o.Nodes> nodes,
    required List<_ilmyslsx.Edge> edges,
    required List<_iy2kpyso.Locations> locations,
    required List<_icks2m2l.WallInput> walls,
  }) = _MapGraphSnapshotImpl;

  factory MapGraphSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return MapGraphSnapshot(
      graph: _i1t1vlhc.Protocol().deserialize<_ikb2yia4.MapGraph>(
        jsonSerialization['graph'],
      ),
      building: _i1t1vlhc.Protocol().deserialize<_icdi8t76.Building>(
        jsonSerialization['building'],
      ),
      floors: _i1t1vlhc.Protocol().deserialize<List<_ibt68ans.Floor>>(
        jsonSerialization['floors'],
      ),
      nodes: _i1t1vlhc.Protocol().deserialize<List<_i9tve71o.Nodes>>(
        jsonSerialization['nodes'],
      ),
      edges: _i1t1vlhc.Protocol().deserialize<List<_ilmyslsx.Edge>>(
        jsonSerialization['edges'],
      ),
      locations: _i1t1vlhc.Protocol().deserialize<List<_iy2kpyso.Locations>>(
        jsonSerialization['locations'],
      ),
      walls: _i1t1vlhc.Protocol().deserialize<List<_icks2m2l.WallInput>>(
        jsonSerialization['walls'],
      ),
    );
  }

  _ikb2yia4.MapGraph graph;

  _icdi8t76.Building building;

  List<_ibt68ans.Floor> floors;

  List<_i9tve71o.Nodes> nodes;

  List<_ilmyslsx.Edge> edges;

  List<_iy2kpyso.Locations> locations;

  List<_icks2m2l.WallInput> walls;

  /// Returns a shallow copy of this [MapGraphSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MapGraphSnapshot copyWith({
    _ikb2yia4.MapGraph? graph,
    _icdi8t76.Building? building,
    List<_ibt68ans.Floor>? floors,
    List<_i9tve71o.Nodes>? nodes,
    List<_ilmyslsx.Edge>? edges,
    List<_iy2kpyso.Locations>? locations,
    List<_icks2m2l.WallInput>? walls,
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
      'walls': walls.toJson(valueToJson: (v) => v.toJson()),
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
      'walls': walls.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
    required List<_icks2m2l.WallInput> walls,
  }) : super._(
         graph: graph,
         building: building,
         floors: floors,
         nodes: nodes,
         edges: edges,
         locations: locations,
         walls: walls,
       );

  /// Returns a shallow copy of this [MapGraphSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MapGraphSnapshot copyWith({
    _ikb2yia4.MapGraph? graph,
    _icdi8t76.Building? building,
    List<_ibt68ans.Floor>? floors,
    List<_i9tve71o.Nodes>? nodes,
    List<_ilmyslsx.Edge>? edges,
    List<_iy2kpyso.Locations>? locations,
    List<_icks2m2l.WallInput>? walls,
  }) {
    return MapGraphSnapshot(
      graph: graph ?? this.graph.copyWith(),
      building: building ?? this.building.copyWith(),
      floors: floors ?? this.floors.map((e0) => e0.copyWith()).toList(),
      nodes: nodes ?? this.nodes.map((e0) => e0.copyWith()).toList(),
      edges: edges ?? this.edges.map((e0) => e0.copyWith()).toList(),
      locations:
          locations ?? this.locations.map((e0) => e0.copyWith()).toList(),
      walls: walls ?? this.walls.map((e0) => e0.copyWith()).toList(),
    );
  }
}
