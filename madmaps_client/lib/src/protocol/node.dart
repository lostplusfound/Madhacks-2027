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
import 'kind.dart' as _iokugpqm;
import 'map_entity_status.dart' as _itjn1vsu;

abstract class Nodes
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Nodes._({
    this.id,
    required this.nodeId,
    this.graphId,
    this.floorId,
    required this.floor,
    required this.x,
    required this.y,
    this.locationId,
    required this.kind,
    _itjn1vsu.MapEntityStatus? status,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    int? version,
  }) : status = status ?? _itjn1vsu.MapEntityStatus.active,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       version = version ?? 1;

  factory Nodes({
    int? id,
    required String nodeId,
    int? graphId,
    int? floorId,
    required int floor,
    required double x,
    required double y,
    String? locationId,
    required _iokugpqm.Kind kind,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) = _NodesImpl;

  factory Nodes.fromJson(Map<String, dynamic> jsonSerialization) {
    return Nodes(
      id: jsonSerialization['id'] as int?,
      nodeId: jsonSerialization['nodeId'] as String,
      graphId: jsonSerialization['graphId'] as int?,
      floorId: jsonSerialization['floorId'] as int?,
      floor: jsonSerialization['floor'] as int,
      x: (jsonSerialization['x'] as num).toDouble(),
      y: (jsonSerialization['y'] as num).toDouble(),
      locationId: jsonSerialization['locationId'] as String?,
      kind: _iokugpqm.Kind.fromJson((jsonSerialization['kind'] as String)),
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

  String nodeId;

  int? graphId;

  int? floorId;

  int floor;

  double x;

  double y;

  String? locationId;

  _iokugpqm.Kind kind;

  _itjn1vsu.MapEntityStatus status;

  String? createdBy;

  String? updatedBy;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  int version;

  /// Returns a shallow copy of this [Nodes]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Nodes copyWith({
    int? id,
    String? nodeId,
    int? graphId,
    int? floorId,
    int? floor,
    double? x,
    double? y,
    String? locationId,
    _iokugpqm.Kind? kind,
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
      '__className__': 'Nodes',
      if (id != null) 'id': id,
      'nodeId': nodeId,
      if (graphId != null) 'graphId': graphId,
      if (floorId != null) 'floorId': floorId,
      'floor': floor,
      'x': x,
      'y': y,
      if (locationId != null) 'locationId': locationId,
      'kind': kind.toJson(),
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
      '__className__': 'Nodes',
      if (id != null) 'id': id,
      'nodeId': nodeId,
      if (graphId != null) 'graphId': graphId,
      if (floorId != null) 'floorId': floorId,
      'floor': floor,
      'x': x,
      'y': y,
      if (locationId != null) 'locationId': locationId,
      'kind': kind.toJson(),
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

class _NodesImpl extends Nodes {
  _NodesImpl({
    int? id,
    required String nodeId,
    int? graphId,
    int? floorId,
    required int floor,
    required double x,
    required double y,
    String? locationId,
    required _iokugpqm.Kind kind,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) : super._(
         id: id,
         nodeId: nodeId,
         graphId: graphId,
         floorId: floorId,
         floor: floor,
         x: x,
         y: y,
         locationId: locationId,
         kind: kind,
         status: status,
         createdBy: createdBy,
         updatedBy: updatedBy,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
         version: version,
       );

  /// Returns a shallow copy of this [Nodes]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Nodes copyWith({
    Object? id = _Undefined,
    String? nodeId,
    Object? graphId = _Undefined,
    Object? floorId = _Undefined,
    int? floor,
    double? x,
    double? y,
    Object? locationId = _Undefined,
    _iokugpqm.Kind? kind,
    _itjn1vsu.MapEntityStatus? status,
    Object? createdBy = _Undefined,
    Object? updatedBy = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _isc.$UndefinedDateTime(),
    int? version,
  }) {
    return Nodes(
      id: id is int? ? id : this.id,
      nodeId: nodeId ?? this.nodeId,
      graphId: graphId is int? ? graphId : this.graphId,
      floorId: floorId is int? ? floorId : this.floorId,
      floor: floor ?? this.floor,
      x: x ?? this.x,
      y: y ?? this.y,
      locationId: locationId is String? ? locationId : this.locationId,
      kind: kind ?? this.kind,
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
