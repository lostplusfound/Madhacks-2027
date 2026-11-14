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

abstract class Edge
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Edge._({
    this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.type,
    required this.costPx,
    required this.bidirectional,
    required this.status,
  });

  factory Edge({
    int? id,
    required String fromNodeId,
    required String toNodeId,
    required String type,
    required double costPx,
    required bool bidirectional,
    required String status,
  }) = _EdgeImpl;

  factory Edge.fromJson(Map<String, dynamic> jsonSerialization) {
    return Edge(
      id: jsonSerialization['id'] as int?,
      fromNodeId: jsonSerialization['from_node_id'] as String,
      toNodeId: jsonSerialization['to_node_id'] as String,
      type: jsonSerialization['type'] as String,
      costPx: (jsonSerialization['cost_px'] as num).toDouble(),
      bidirectional: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['bidirectional'],
      ),
      status: jsonSerialization['status'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String fromNodeId;

  String toNodeId;

  String type;

  double costPx;

  bool bidirectional;

  String status;

  /// Returns a shallow copy of this [Edge]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Edge copyWith({
    int? id,
    String? fromNodeId,
    String? toNodeId,
    String? type,
    double? costPx,
    bool? bidirectional,
    String? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Edge',
      if (id != null) 'id': id,
      'from_node_id': fromNodeId,
      'to_node_id': toNodeId,
      'type': type,
      'cost_px': costPx,
      'bidirectional': bidirectional,
      'status': status,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Edge',
      if (id != null) 'id': id,
      'from_node_id': fromNodeId,
      'to_node_id': toNodeId,
      'type': type,
      'cost_px': costPx,
      'bidirectional': bidirectional,
      'status': status,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EdgeImpl extends Edge {
  _EdgeImpl({
    int? id,
    required String fromNodeId,
    required String toNodeId,
    required String type,
    required double costPx,
    required bool bidirectional,
    required String status,
  }) : super._(
         id: id,
         fromNodeId: fromNodeId,
         toNodeId: toNodeId,
         type: type,
         costPx: costPx,
         bidirectional: bidirectional,
         status: status,
       );

  /// Returns a shallow copy of this [Edge]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Edge copyWith({
    Object? id = _Undefined,
    String? fromNodeId,
    String? toNodeId,
    String? type,
    double? costPx,
    bool? bidirectional,
    String? status,
  }) {
    return Edge(
      id: id is int? ? id : this.id,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      type: type ?? this.type,
      costPx: costPx ?? this.costPx,
      bidirectional: bidirectional ?? this.bidirectional,
      status: status ?? this.status,
    );
  }
}
