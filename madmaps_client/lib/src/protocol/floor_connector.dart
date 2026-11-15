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

abstract class FloorConnector
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FloorConnector._({
    this.id,
    required this.connectorId,
    required this.buildingId,
    required this.label,
    required this.fromGraphId,
    required this.fromFloor,
    required this.fromNodeId,
    required this.toGraphId,
    required this.toFloor,
    required this.toNodeId,
    required this.type,
    required this.seconds,
    bool? bidirectional,
    bool? active,
  }) : bidirectional = bidirectional ?? true,
       active = active ?? true;

  factory FloorConnector({
    int? id,
    required String connectorId,
    required String buildingId,
    required String label,
    required String fromGraphId,
    required int fromFloor,
    required String fromNodeId,
    required String toGraphId,
    required int toFloor,
    required String toNodeId,
    required _iv43g6lk.EdgeType type,
    required double seconds,
    bool? bidirectional,
    bool? active,
  }) = _FloorConnectorImpl;

  factory FloorConnector.fromJson(Map<String, dynamic> jsonSerialization) {
    return FloorConnector(
      id: jsonSerialization['id'] as int?,
      connectorId: jsonSerialization['connectorId'] as String,
      buildingId: jsonSerialization['buildingId'] as String,
      label: jsonSerialization['label'] as String,
      fromGraphId: jsonSerialization['fromGraphId'] as String,
      fromFloor: jsonSerialization['fromFloor'] as int,
      fromNodeId: jsonSerialization['fromNodeId'] as String,
      toGraphId: jsonSerialization['toGraphId'] as String,
      toFloor: jsonSerialization['toFloor'] as int,
      toNodeId: jsonSerialization['toNodeId'] as String,
      type: _iv43g6lk.EdgeType.fromJson((jsonSerialization['type'] as String)),
      seconds: (jsonSerialization['seconds'] as num).toDouble(),
      bidirectional: jsonSerialization['bidirectional'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['bidirectional']),
      active: jsonSerialization['active'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['active']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String connectorId;

  String buildingId;

  String label;

  String fromGraphId;

  int fromFloor;

  String fromNodeId;

  String toGraphId;

  int toFloor;

  String toNodeId;

  _iv43g6lk.EdgeType type;

  double seconds;

  bool bidirectional;

  bool active;

  /// Returns a shallow copy of this [FloorConnector]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FloorConnector copyWith({
    int? id,
    String? connectorId,
    String? buildingId,
    String? label,
    String? fromGraphId,
    int? fromFloor,
    String? fromNodeId,
    String? toGraphId,
    int? toFloor,
    String? toNodeId,
    _iv43g6lk.EdgeType? type,
    double? seconds,
    bool? bidirectional,
    bool? active,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FloorConnector',
      if (id != null) 'id': id,
      'connectorId': connectorId,
      'buildingId': buildingId,
      'label': label,
      'fromGraphId': fromGraphId,
      'fromFloor': fromFloor,
      'fromNodeId': fromNodeId,
      'toGraphId': toGraphId,
      'toFloor': toFloor,
      'toNodeId': toNodeId,
      'type': type.toJson(),
      'seconds': seconds,
      'bidirectional': bidirectional,
      'active': active,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FloorConnector',
      if (id != null) 'id': id,
      'connectorId': connectorId,
      'buildingId': buildingId,
      'label': label,
      'fromGraphId': fromGraphId,
      'fromFloor': fromFloor,
      'fromNodeId': fromNodeId,
      'toGraphId': toGraphId,
      'toFloor': toFloor,
      'toNodeId': toNodeId,
      'type': type.toJson(),
      'seconds': seconds,
      'bidirectional': bidirectional,
      'active': active,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FloorConnectorImpl extends FloorConnector {
  _FloorConnectorImpl({
    int? id,
    required String connectorId,
    required String buildingId,
    required String label,
    required String fromGraphId,
    required int fromFloor,
    required String fromNodeId,
    required String toGraphId,
    required int toFloor,
    required String toNodeId,
    required _iv43g6lk.EdgeType type,
    required double seconds,
    bool? bidirectional,
    bool? active,
  }) : super._(
         id: id,
         connectorId: connectorId,
         buildingId: buildingId,
         label: label,
         fromGraphId: fromGraphId,
         fromFloor: fromFloor,
         fromNodeId: fromNodeId,
         toGraphId: toGraphId,
         toFloor: toFloor,
         toNodeId: toNodeId,
         type: type,
         seconds: seconds,
         bidirectional: bidirectional,
         active: active,
       );

  /// Returns a shallow copy of this [FloorConnector]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FloorConnector copyWith({
    Object? id = _Undefined,
    String? connectorId,
    String? buildingId,
    String? label,
    String? fromGraphId,
    int? fromFloor,
    String? fromNodeId,
    String? toGraphId,
    int? toFloor,
    String? toNodeId,
    _iv43g6lk.EdgeType? type,
    double? seconds,
    bool? bidirectional,
    bool? active,
  }) {
    return FloorConnector(
      id: id is int? ? id : this.id,
      connectorId: connectorId ?? this.connectorId,
      buildingId: buildingId ?? this.buildingId,
      label: label ?? this.label,
      fromGraphId: fromGraphId ?? this.fromGraphId,
      fromFloor: fromFloor ?? this.fromFloor,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toGraphId: toGraphId ?? this.toGraphId,
      toFloor: toFloor ?? this.toFloor,
      toNodeId: toNodeId ?? this.toNodeId,
      type: type ?? this.type,
      seconds: seconds ?? this.seconds,
      bidirectional: bidirectional ?? this.bidirectional,
      active: active ?? this.active,
    );
  }
}
