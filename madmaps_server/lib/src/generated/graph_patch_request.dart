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
import 'location_input.dart' as _iaviofrw;
import 'map_edge_input.dart' as _ipndifli;
import 'map_node_input.dart' as _i3qve637;
import 'wall_input.dart' as _icks2m2l;

abstract class GraphPatchRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  GraphPatchRequest._({
    required this.graphId,
    required this.expectedVersion,
    required this.nodesToCreate,
    required this.nodesToUpdate,
    required this.nodeIdsToDelete,
    required this.edgesToCreate,
    required this.edgesToUpdate,
    required this.edgeIdsToDelete,
    required this.locationsToCreate,
    required this.locationsToUpdate,
    required this.locationIdsToDelete,
    this.walls,
  });

  factory GraphPatchRequest({
    required String graphId,
    required int expectedVersion,
    required List<_i3qve637.MapNodeInput> nodesToCreate,
    required List<_i3qve637.MapNodeInput> nodesToUpdate,
    required List<String> nodeIdsToDelete,
    required List<_ipndifli.MapEdgeInput> edgesToCreate,
    required List<_ipndifli.MapEdgeInput> edgesToUpdate,
    required List<String> edgeIdsToDelete,
    required List<_iaviofrw.LocationInput> locationsToCreate,
    required List<_iaviofrw.LocationInput> locationsToUpdate,
    required List<String> locationIdsToDelete,
    List<_icks2m2l.WallInput>? walls,
  }) = _GraphPatchRequestImpl;

  factory GraphPatchRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return GraphPatchRequest(
      graphId: jsonSerialization['graphId'] as String,
      expectedVersion: jsonSerialization['expectedVersion'] as int,
      nodesToCreate: _i1t1vlhc.Protocol()
          .deserialize<List<_i3qve637.MapNodeInput>>(
            jsonSerialization['nodesToCreate'],
          ),
      nodesToUpdate: _i1t1vlhc.Protocol()
          .deserialize<List<_i3qve637.MapNodeInput>>(
            jsonSerialization['nodesToUpdate'],
          ),
      nodeIdsToDelete: _i1t1vlhc.Protocol().deserialize<List<String>>(
        jsonSerialization['nodeIdsToDelete'],
      ),
      edgesToCreate: _i1t1vlhc.Protocol()
          .deserialize<List<_ipndifli.MapEdgeInput>>(
            jsonSerialization['edgesToCreate'],
          ),
      edgesToUpdate: _i1t1vlhc.Protocol()
          .deserialize<List<_ipndifli.MapEdgeInput>>(
            jsonSerialization['edgesToUpdate'],
          ),
      edgeIdsToDelete: _i1t1vlhc.Protocol().deserialize<List<String>>(
        jsonSerialization['edgeIdsToDelete'],
      ),
      locationsToCreate: _i1t1vlhc.Protocol()
          .deserialize<List<_iaviofrw.LocationInput>>(
            jsonSerialization['locationsToCreate'],
          ),
      locationsToUpdate: _i1t1vlhc.Protocol()
          .deserialize<List<_iaviofrw.LocationInput>>(
            jsonSerialization['locationsToUpdate'],
          ),
      locationIdsToDelete: _i1t1vlhc.Protocol().deserialize<List<String>>(
        jsonSerialization['locationIdsToDelete'],
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

  List<_i3qve637.MapNodeInput> nodesToCreate;

  List<_i3qve637.MapNodeInput> nodesToUpdate;

  List<String> nodeIdsToDelete;

  List<_ipndifli.MapEdgeInput> edgesToCreate;

  List<_ipndifli.MapEdgeInput> edgesToUpdate;

  List<String> edgeIdsToDelete;

  List<_iaviofrw.LocationInput> locationsToCreate;

  List<_iaviofrw.LocationInput> locationsToUpdate;

  List<String> locationIdsToDelete;

  List<_icks2m2l.WallInput>? walls;

  /// Returns a shallow copy of this [GraphPatchRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GraphPatchRequest copyWith({
    String? graphId,
    int? expectedVersion,
    List<_i3qve637.MapNodeInput>? nodesToCreate,
    List<_i3qve637.MapNodeInput>? nodesToUpdate,
    List<String>? nodeIdsToDelete,
    List<_ipndifli.MapEdgeInput>? edgesToCreate,
    List<_ipndifli.MapEdgeInput>? edgesToUpdate,
    List<String>? edgeIdsToDelete,
    List<_iaviofrw.LocationInput>? locationsToCreate,
    List<_iaviofrw.LocationInput>? locationsToUpdate,
    List<String>? locationIdsToDelete,
    List<_icks2m2l.WallInput>? walls =
        const _is.$UndefinedList<_icks2m2l.WallInput>(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GraphPatchRequest',
      'graphId': graphId,
      'expectedVersion': expectedVersion,
      'nodesToCreate': nodesToCreate.toJson(valueToJson: (v) => v.toJson()),
      'nodesToUpdate': nodesToUpdate.toJson(valueToJson: (v) => v.toJson()),
      'nodeIdsToDelete': nodeIdsToDelete.toJson(),
      'edgesToCreate': edgesToCreate.toJson(valueToJson: (v) => v.toJson()),
      'edgesToUpdate': edgesToUpdate.toJson(valueToJson: (v) => v.toJson()),
      'edgeIdsToDelete': edgeIdsToDelete.toJson(),
      'locationsToCreate': locationsToCreate.toJson(
        valueToJson: (v) => v.toJson(),
      ),
      'locationsToUpdate': locationsToUpdate.toJson(
        valueToJson: (v) => v.toJson(),
      ),
      'locationIdsToDelete': locationIdsToDelete.toJson(),
      if (walls != null) 'walls': walls?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GraphPatchRequest',
      'graphId': graphId,
      'expectedVersion': expectedVersion,
      'nodesToCreate': nodesToCreate.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'nodesToUpdate': nodesToUpdate.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'nodeIdsToDelete': nodeIdsToDelete.toJson(),
      'edgesToCreate': edgesToCreate.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'edgesToUpdate': edgesToUpdate.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'edgeIdsToDelete': edgeIdsToDelete.toJson(),
      'locationsToCreate': locationsToCreate.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'locationsToUpdate': locationsToUpdate.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'locationIdsToDelete': locationIdsToDelete.toJson(),
      if (walls != null)
        'walls': walls?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _GraphPatchRequestImpl extends GraphPatchRequest {
  _GraphPatchRequestImpl({
    required String graphId,
    required int expectedVersion,
    required List<_i3qve637.MapNodeInput> nodesToCreate,
    required List<_i3qve637.MapNodeInput> nodesToUpdate,
    required List<String> nodeIdsToDelete,
    required List<_ipndifli.MapEdgeInput> edgesToCreate,
    required List<_ipndifli.MapEdgeInput> edgesToUpdate,
    required List<String> edgeIdsToDelete,
    required List<_iaviofrw.LocationInput> locationsToCreate,
    required List<_iaviofrw.LocationInput> locationsToUpdate,
    required List<String> locationIdsToDelete,
    List<_icks2m2l.WallInput>? walls,
  }) : super._(
         graphId: graphId,
         expectedVersion: expectedVersion,
         nodesToCreate: nodesToCreate,
         nodesToUpdate: nodesToUpdate,
         nodeIdsToDelete: nodeIdsToDelete,
         edgesToCreate: edgesToCreate,
         edgesToUpdate: edgesToUpdate,
         edgeIdsToDelete: edgeIdsToDelete,
         locationsToCreate: locationsToCreate,
         locationsToUpdate: locationsToUpdate,
         locationIdsToDelete: locationIdsToDelete,
         walls: walls,
       );

  /// Returns a shallow copy of this [GraphPatchRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GraphPatchRequest copyWith({
    String? graphId,
    int? expectedVersion,
    List<_i3qve637.MapNodeInput>? nodesToCreate,
    List<_i3qve637.MapNodeInput>? nodesToUpdate,
    List<String>? nodeIdsToDelete,
    List<_ipndifli.MapEdgeInput>? edgesToCreate,
    List<_ipndifli.MapEdgeInput>? edgesToUpdate,
    List<String>? edgeIdsToDelete,
    List<_iaviofrw.LocationInput>? locationsToCreate,
    List<_iaviofrw.LocationInput>? locationsToUpdate,
    List<String>? locationIdsToDelete,
    List<_icks2m2l.WallInput>? walls =
        const _is.$UndefinedList<_icks2m2l.WallInput>(),
  }) {
    return GraphPatchRequest(
      graphId: graphId ?? this.graphId,
      expectedVersion: expectedVersion ?? this.expectedVersion,
      nodesToCreate:
          nodesToCreate ??
          this.nodesToCreate.map((e0) => e0.copyWith()).toList(),
      nodesToUpdate:
          nodesToUpdate ??
          this.nodesToUpdate.map((e0) => e0.copyWith()).toList(),
      nodeIdsToDelete:
          nodeIdsToDelete ?? this.nodeIdsToDelete.map((e0) => e0).toList(),
      edgesToCreate:
          edgesToCreate ??
          this.edgesToCreate.map((e0) => e0.copyWith()).toList(),
      edgesToUpdate:
          edgesToUpdate ??
          this.edgesToUpdate.map((e0) => e0.copyWith()).toList(),
      edgeIdsToDelete:
          edgeIdsToDelete ?? this.edgeIdsToDelete.map((e0) => e0).toList(),
      locationsToCreate:
          locationsToCreate ??
          this.locationsToCreate.map((e0) => e0.copyWith()).toList(),
      locationsToUpdate:
          locationsToUpdate ??
          this.locationsToUpdate.map((e0) => e0.copyWith()).toList(),
      locationIdsToDelete:
          locationIdsToDelete ??
          this.locationIdsToDelete.map((e0) => e0).toList(),
      walls: walls is _is.UndefinedSentinel
          ? this.walls?.map((e0) => e0.copyWith()).toList()
          : walls,
    );
  }
}
