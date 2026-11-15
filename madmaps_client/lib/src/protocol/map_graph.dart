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
import 'map_entity_status.dart' as _itjn1vsu;

abstract class MapGraph
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MapGraph._({
    this.id,
    required this.graphId,
    required this.buildingId,
    required this.name,
    required this.ownerId,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : status = status ?? _itjn1vsu.MapEntityStatus.active,
       version = version ?? 1,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory MapGraph({
    int? id,
    required String graphId,
    required int buildingId,
    required String name,
    required String ownerId,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _MapGraphImpl;

  factory MapGraph.fromJson(Map<String, dynamic> jsonSerialization) {
    return MapGraph(
      id: jsonSerialization['id'] as int?,
      graphId: jsonSerialization['graphId'] as String,
      buildingId: jsonSerialization['buildingId'] as int,
      name: jsonSerialization['name'] as String,
      ownerId: jsonSerialization['ownerId'] as String,
      status: jsonSerialization['status'] == null
          ? null
          : _itjn1vsu.MapEntityStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      version: jsonSerialization['version'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String graphId;

  int buildingId;

  String name;

  String ownerId;

  _itjn1vsu.MapEntityStatus status;

  int version;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [MapGraph]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MapGraph copyWith({
    int? id,
    String? graphId,
    int? buildingId,
    String? name,
    String? ownerId,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _isc.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MapGraph',
      if (id != null) 'id': id,
      'graphId': graphId,
      'buildingId': buildingId,
      'name': name,
      'ownerId': ownerId,
      'status': status.toJson(),
      'version': version,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MapGraph',
      if (id != null) 'id': id,
      'graphId': graphId,
      'buildingId': buildingId,
      'name': name,
      'ownerId': ownerId,
      'status': status.toJson(),
      'version': version,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MapGraphImpl extends MapGraph {
  _MapGraphImpl({
    int? id,
    required String graphId,
    required int buildingId,
    required String name,
    required String ownerId,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         graphId: graphId,
         buildingId: buildingId,
         name: name,
         ownerId: ownerId,
         status: status,
         version: version,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [MapGraph]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MapGraph copyWith({
    Object? id = _Undefined,
    String? graphId,
    int? buildingId,
    String? name,
    String? ownerId,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _isc.$UndefinedDateTime(),
  }) {
    return MapGraph(
      id: id is int? ? id : this.id,
      graphId: graphId ?? this.graphId,
      buildingId: buildingId ?? this.buildingId,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is _isc.UndefinedSentinel
          ? this.deletedAt
          : deletedAt,
    );
  }
}
