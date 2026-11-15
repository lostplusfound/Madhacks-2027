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
import 'floor_input.dart' as _i647gghf;
import 'location_input.dart' as _iaviofrw;
import 'map_edge_input.dart' as _ipndifli;
import 'map_node_input.dart' as _i3qve637;

abstract class CreateGraphRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CreateGraphRequest._({
    required this.graphId,
    required this.buildingId,
    required this.name,
    required this.floors,
    required this.nodes,
    required this.edges,
    required this.locations,
  });

  factory CreateGraphRequest({
    required String graphId,
    required String buildingId,
    required String name,
    required List<_i647gghf.FloorInput> floors,
    required List<_i3qve637.MapNodeInput> nodes,
    required List<_ipndifli.MapEdgeInput> edges,
    required List<_iaviofrw.LocationInput> locations,
  }) = _CreateGraphRequestImpl;

  factory CreateGraphRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return CreateGraphRequest(
      graphId: jsonSerialization['graphId'] as String,
      buildingId: jsonSerialization['buildingId'] as String,
      name: jsonSerialization['name'] as String,
      floors: _isgyuksw.Protocol().deserialize<List<_i647gghf.FloorInput>>(
        jsonSerialization['floors'],
      ),
      nodes: _isgyuksw.Protocol().deserialize<List<_i3qve637.MapNodeInput>>(
        jsonSerialization['nodes'],
      ),
      edges: _isgyuksw.Protocol().deserialize<List<_ipndifli.MapEdgeInput>>(
        jsonSerialization['edges'],
      ),
      locations: _isgyuksw.Protocol()
          .deserialize<List<_iaviofrw.LocationInput>>(
            jsonSerialization['locations'],
          ),
    );
  }

  String graphId;

  String buildingId;

  String name;

  List<_i647gghf.FloorInput> floors;

  List<_i3qve637.MapNodeInput> nodes;

  List<_ipndifli.MapEdgeInput> edges;

  List<_iaviofrw.LocationInput> locations;

  /// Returns a shallow copy of this [CreateGraphRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CreateGraphRequest copyWith({
    String? graphId,
    String? buildingId,
    String? name,
    List<_i647gghf.FloorInput>? floors,
    List<_i3qve637.MapNodeInput>? nodes,
    List<_ipndifli.MapEdgeInput>? edges,
    List<_iaviofrw.LocationInput>? locations,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateGraphRequest',
      'graphId': graphId,
      'buildingId': buildingId,
      'name': name,
      'floors': floors.toJson(valueToJson: (v) => v.toJson()),
      'nodes': nodes.toJson(valueToJson: (v) => v.toJson()),
      'edges': edges.toJson(valueToJson: (v) => v.toJson()),
      'locations': locations.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CreateGraphRequest',
      'graphId': graphId,
      'buildingId': buildingId,
      'name': name,
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

class _CreateGraphRequestImpl extends CreateGraphRequest {
  _CreateGraphRequestImpl({
    required String graphId,
    required String buildingId,
    required String name,
    required List<_i647gghf.FloorInput> floors,
    required List<_i3qve637.MapNodeInput> nodes,
    required List<_ipndifli.MapEdgeInput> edges,
    required List<_iaviofrw.LocationInput> locations,
  }) : super._(
         graphId: graphId,
         buildingId: buildingId,
         name: name,
         floors: floors,
         nodes: nodes,
         edges: edges,
         locations: locations,
       );

  /// Returns a shallow copy of this [CreateGraphRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CreateGraphRequest copyWith({
    String? graphId,
    String? buildingId,
    String? name,
    List<_i647gghf.FloorInput>? floors,
    List<_i3qve637.MapNodeInput>? nodes,
    List<_ipndifli.MapEdgeInput>? edges,
    List<_iaviofrw.LocationInput>? locations,
  }) {
    return CreateGraphRequest(
      graphId: graphId ?? this.graphId,
      buildingId: buildingId ?? this.buildingId,
      name: name ?? this.name,
      floors: floors ?? this.floors.map((e0) => e0.copyWith()).toList(),
      nodes: nodes ?? this.nodes.map((e0) => e0.copyWith()).toList(),
      edges: edges ?? this.edges.map((e0) => e0.copyWith()).toList(),
      locations:
          locations ?? this.locations.map((e0) => e0.copyWith()).toList(),
    );
  }
}
