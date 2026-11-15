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
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'edge_type.dart' as _iv43g6lk;

abstract class MapEdgeInput
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MapEdgeInput._({
    required this.edgeId,
    required this.fromNodeId,
    required this.toNodeId,
    required this.type,
    this.cost,
    required this.bidirectional,
  });

  factory MapEdgeInput({
    required String edgeId,
    required String fromNodeId,
    required String toNodeId,
    required _iv43g6lk.EdgeType type,
    double? cost,
    required bool bidirectional,
  }) = _MapEdgeInputImpl;

  factory MapEdgeInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return MapEdgeInput(
      edgeId: jsonSerialization['edgeId'] as String,
      fromNodeId: jsonSerialization['fromNodeId'] as String,
      toNodeId: jsonSerialization['toNodeId'] as String,
      type: _iv43g6lk.EdgeType.fromJson((jsonSerialization['type'] as String)),
      cost: (jsonSerialization['cost'] as num?)?.toDouble(),
      bidirectional: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['bidirectional'],
      ),
    );
  }

  String edgeId;

  String fromNodeId;

  String toNodeId;

  _iv43g6lk.EdgeType type;

  double? cost;

  bool bidirectional;

  /// Returns a shallow copy of this [MapEdgeInput]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MapEdgeInput copyWith({
    String? edgeId,
    String? fromNodeId,
    String? toNodeId,
    _iv43g6lk.EdgeType? type,
    double? cost,
    bool? bidirectional,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MapEdgeInput',
      'edgeId': edgeId,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'type': type.toJson(),
      if (cost != null) 'cost': cost,
      'bidirectional': bidirectional,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MapEdgeInput',
      'edgeId': edgeId,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'type': type.toJson(),
      if (cost != null) 'cost': cost,
      'bidirectional': bidirectional,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MapEdgeInputImpl extends MapEdgeInput {
  _MapEdgeInputImpl({
    required String edgeId,
    required String fromNodeId,
    required String toNodeId,
    required _iv43g6lk.EdgeType type,
    double? cost,
    required bool bidirectional,
  }) : super._(
         edgeId: edgeId,
         fromNodeId: fromNodeId,
         toNodeId: toNodeId,
         type: type,
         cost: cost,
         bidirectional: bidirectional,
       );

  /// Returns a shallow copy of this [MapEdgeInput]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MapEdgeInput copyWith({
    String? edgeId,
    String? fromNodeId,
    String? toNodeId,
    _iv43g6lk.EdgeType? type,
    Object? cost = _Undefined,
    bool? bidirectional,
  }) {
    return MapEdgeInput(
      edgeId: edgeId ?? this.edgeId,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      type: type ?? this.type,
      cost: cost is double? ? cost : this.cost,
      bidirectional: bidirectional ?? this.bidirectional,
    );
  }
}
