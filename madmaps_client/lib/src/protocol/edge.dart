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
import 'map_entity_status.dart' as _itjn1vsu;

abstract class Edge
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Edge._({
    this.id,
    this.edgeId,
    this.graphId,
    required this.fromNodeId,
    required this.toNodeId,
    _iv43g6lk.EdgeType? type,
    required this.costPx,
    required this.bidirectional,
    _itjn1vsu.MapEntityStatus? status,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    int? version,
  }) : type = type ?? _iv43g6lk.EdgeType.walk,
       status = status ?? _itjn1vsu.MapEntityStatus.active,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       version = version ?? 1;

  factory Edge({
    int? id,
    String? edgeId,
    int? graphId,
    required String fromNodeId,
    required String toNodeId,
    _iv43g6lk.EdgeType? type,
    required double costPx,
    required bool bidirectional,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) = _EdgeImpl;

  factory Edge.fromJson(Map<String, dynamic> jsonSerialization) {
    return Edge(
      id: jsonSerialization['id'] as int?,
      edgeId: jsonSerialization['edgeId'] as String?,
      graphId: jsonSerialization['graphId'] as int?,
      fromNodeId: jsonSerialization['fromNodeId'] as String,
      toNodeId: jsonSerialization['toNodeId'] as String,
      type: jsonSerialization['type'] == null
          ? null
          : _iv43g6lk.EdgeType.fromJson((jsonSerialization['type'] as String)),
      costPx: (jsonSerialization['costPx'] as num).toDouble(),
      bidirectional: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['bidirectional'],
      ),
      status: jsonSerialization['status'] == null
          ? null
          : _itjn1vsu.MapEntityStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      createdBy: jsonSerialization['createdBy'] as String?,
      updatedBy: jsonSerialization['updatedBy'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      version: jsonSerialization['version'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String? edgeId;

  int? graphId;

  String fromNodeId;

  String toNodeId;

  _iv43g6lk.EdgeType type;

  double costPx;

  bool bidirectional;

  _itjn1vsu.MapEntityStatus status;

  String? createdBy;

  String? updatedBy;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  int version;

  /// Returns a shallow copy of this [Edge]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Edge copyWith({
    int? id,
    String? edgeId,
    int? graphId,
    String? fromNodeId,
    String? toNodeId,
    _iv43g6lk.EdgeType? type,
    double? costPx,
    bool? bidirectional,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _isc.$UndefinedDateTime(),
    int? version,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Edge',
      if (id != null) 'id': id,
      if (edgeId != null) 'edgeId': edgeId,
      if (graphId != null) 'graphId': graphId,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'type': type.toJson(),
      'costPx': costPx,
      'bidirectional': bidirectional,
      'status': status.toJson(),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      'version': version,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Edge',
      if (id != null) 'id': id,
      if (edgeId != null) 'edgeId': edgeId,
      if (graphId != null) 'graphId': graphId,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'type': type.toJson(),
      'costPx': costPx,
      'bidirectional': bidirectional,
      'status': status.toJson(),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      'version': version,
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
    String? edgeId,
    int? graphId,
    required String fromNodeId,
    required String toNodeId,
    _iv43g6lk.EdgeType? type,
    required double costPx,
    required bool bidirectional,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) : super._(
         id: id,
         edgeId: edgeId,
         graphId: graphId,
         fromNodeId: fromNodeId,
         toNodeId: toNodeId,
         type: type,
         costPx: costPx,
         bidirectional: bidirectional,
         status: status,
         createdBy: createdBy,
         updatedBy: updatedBy,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
         version: version,
       );

  /// Returns a shallow copy of this [Edge]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Edge copyWith({
    Object? id = _Undefined,
    Object? edgeId = _Undefined,
    Object? graphId = _Undefined,
    String? fromNodeId,
    String? toNodeId,
    _iv43g6lk.EdgeType? type,
    double? costPx,
    bool? bidirectional,
    _itjn1vsu.MapEntityStatus? status,
    Object? createdBy = _Undefined,
    Object? updatedBy = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _isc.$UndefinedDateTime(),
    int? version,
  }) {
    return Edge(
      id: id is int? ? id : this.id,
      edgeId: edgeId is String? ? edgeId : this.edgeId,
      graphId: graphId is int? ? graphId : this.graphId,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      type: type ?? this.type,
      costPx: costPx ?? this.costPx,
      bidirectional: bidirectional ?? this.bidirectional,
      status: status ?? this.status,
      createdBy: createdBy is String? ? createdBy : this.createdBy,
      updatedBy: updatedBy is String? ? updatedBy : this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is _isc.UndefinedSentinel
          ? this.deletedAt
          : deletedAt,
      version: version ?? this.version,
    );
  }
}
