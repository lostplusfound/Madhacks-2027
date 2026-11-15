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
import 'floor_input.dart' as _i647gghf;
import 'location_input.dart' as _iaviofrw;
import 'map_edge_input.dart' as _ipndifli;
import 'map_node_input.dart' as _i3qve637;
import 'wall_input.dart' as _icks2m2l;

abstract class ReplaceGraphRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ReplaceGraphRequest._({
    required this.graphId,
    required this.expectedVersion,
    required this.name,
    required this.floors,
    required this.nodes,
    required this.edges,
    required this.locations,
    this.walls,
  });

  factory ReplaceGraphRequest({
    required String graphId,
    required int expectedVersion,
    required String name,
    required List<_i647gghf.FloorInput> floors,
    required List<_i3qve637.MapNodeInput> nodes,
    required List<_ipndifli.MapEdgeInput> edges,
    required List<_iaviofrw.LocationInput> locations,
    List<_icks2m2l.WallInput>? walls,
  }) = _ReplaceGraphRequestImpl;

  factory ReplaceGraphRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReplaceGraphRequest(
      graphId: jsonSerialization['graphId'] as String,
      expectedVersion: jsonSerialization['expectedVersion'] as int,
      name: jsonSerialization['name'] as String,
      floors: _i1t1vlhc.Protocol().deserialize<List<_i647gghf.FloorInput>>(
        jsonSerialization['floors'],
      ),
      nodes: _i1t1vlhc.Protocol().deserialize<List<_i3qve637.MapNodeInput>>(
        jsonSerialization['nodes'],
      ),
      edges: _i1t1vlhc.Protocol().deserialize<List<_ipndifli.MapEdgeInput>>(
        jsonSerialization['edges'],
      ),
      locations: _i1t1vlhc.Protocol()
          .deserialize<List<_iaviofrw.LocationInput>>(
            jsonSerialization['locations'],
          ),
      walls: jsonSerialization['walls'] == null
          ? null
          : _i1t1vlhc.Protocol().deserialize<List<_icks2m2l.WallInput>>(
              jsonSerialization['walls'],
            ),
    );
  }

  String graphId;

  int expectedVersion;

  String name;

  List<_i647gghf.FloorInput> floors;

  List<_i3qve637.MapNodeInput> nodes;

  List<_ipndifli.MapEdgeInput> edges;

  List<_iaviofrw.LocationInput> locations;

  List<_icks2m2l.WallInput>? walls;

  /// Returns a shallow copy of this [ReplaceGraphRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ReplaceGraphRequest copyWith({
    String? graphId,
    int? expectedVersion,
    String? name,
    List<_i647gghf.FloorInput>? floors,
    List<_i3qve637.MapNodeInput>? nodes,
    List<_ipndifli.MapEdgeInput>? edges,
    List<_iaviofrw.LocationInput>? locations,
    List<_icks2m2l.WallInput>? walls =
        const _is.$UndefinedList<_icks2m2l.WallInput>(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReplaceGraphRequest',
      'graphId': graphId,
      'expectedVersion': expectedVersion,
      'name': name,
      'floors': floors.toJson(valueToJson: (v) => v.toJson()),
      'nodes': nodes.toJson(valueToJson: (v) => v.toJson()),
      'edges': edges.toJson(valueToJson: (v) => v.toJson()),
      'locations': locations.toJson(valueToJson: (v) => v.toJson()),
      if (walls != null) 'walls': walls?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReplaceGraphRequest',
      'graphId': graphId,
      'expectedVersion': expectedVersion,
      'name': name,
      'floors': floors.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'nodes': nodes.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'edges': edges.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'locations': locations.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (walls != null)
        'walls': walls?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ReplaceGraphRequestImpl extends ReplaceGraphRequest {
  _ReplaceGraphRequestImpl({
    required String graphId,
    required int expectedVersion,
    required String name,
    required List<_i647gghf.FloorInput> floors,
    required List<_i3qve637.MapNodeInput> nodes,
    required List<_ipndifli.MapEdgeInput> edges,
    required List<_iaviofrw.LocationInput> locations,
    List<_icks2m2l.WallInput>? walls,
  }) : super._(
         graphId: graphId,
         expectedVersion: expectedVersion,
         name: name,
         floors: floors,
         nodes: nodes,
         edges: edges,
         locations: locations,
         walls: walls,
       );

  /// Returns a shallow copy of this [ReplaceGraphRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ReplaceGraphRequest copyWith({
    String? graphId,
    int? expectedVersion,
    String? name,
    List<_i647gghf.FloorInput>? floors,
    List<_i3qve637.MapNodeInput>? nodes,
    List<_ipndifli.MapEdgeInput>? edges,
    List<_iaviofrw.LocationInput>? locations,
    List<_icks2m2l.WallInput>? walls =
        const _is.$UndefinedList<_icks2m2l.WallInput>(),
  }) {
    return ReplaceGraphRequest(
      graphId: graphId ?? this.graphId,
      expectedVersion: expectedVersion ?? this.expectedVersion,
      name: name ?? this.name,
      floors: floors ?? this.floors.map((e0) => e0.copyWith()).toList(),
      nodes: nodes ?? this.nodes.map((e0) => e0.copyWith()).toList(),
      edges: edges ?? this.edges.map((e0) => e0.copyWith()).toList(),
      locations:
          locations ?? this.locations.map((e0) => e0.copyWith()).toList(),
      walls: walls is _is.UndefinedSentinel
          ? this.walls?.map((e0) => e0.copyWith()).toList()
          : walls,
    );
  }
}
