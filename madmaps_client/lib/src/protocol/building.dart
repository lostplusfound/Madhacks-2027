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

abstract class Building
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Building._({
    this.id,
    required this.buildingId,
    required this.name,
    this.address,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       status = status ?? _itjn1vsu.MapEntityStatus.active,
       version = version ?? 1;

  factory Building({
    int? id,
    required String buildingId,
    required String name,
    String? address,
    required String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
  }) = _BuildingImpl;

  factory Building.fromJson(Map<String, dynamic> jsonSerialization) {
    return Building(
      id: jsonSerialization['id'] as int?,
      buildingId: jsonSerialization['buildingId'] as String,
      name: jsonSerialization['name'] as String,
      address: jsonSerialization['address'] as String?,
      createdBy: jsonSerialization['createdBy'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      status: jsonSerialization['status'] == null
          ? null
          : _itjn1vsu.MapEntityStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      version: jsonSerialization['version'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String buildingId;

  String name;

  String? address;

  String createdBy;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  _itjn1vsu.MapEntityStatus status;

  int version;

  /// Returns a shallow copy of this [Building]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Building copyWith({
    int? id,
    String? buildingId,
    String? name,
    String? address,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _isc.$UndefinedDateTime(),
    _itjn1vsu.MapEntityStatus? status,
    int? version,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Building',
      if (id != null) 'id': id,
      'buildingId': buildingId,
      'name': name,
      if (address != null) 'address': address,
      'createdBy': createdBy,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      'status': status.toJson(),
      'version': version,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Building',
      if (id != null) 'id': id,
      'buildingId': buildingId,
      'name': name,
      if (address != null) 'address': address,
      'createdBy': createdBy,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      'status': status.toJson(),
      'version': version,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BuildingImpl extends Building {
  _BuildingImpl({
    int? id,
    required String buildingId,
    required String name,
    String? address,
    required String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
  }) : super._(
         id: id,
         buildingId: buildingId,
         name: name,
         address: address,
         createdBy: createdBy,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
         status: status,
         version: version,
       );

  /// Returns a shallow copy of this [Building]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Building copyWith({
    Object? id = _Undefined,
    String? buildingId,
    String? name,
    Object? address = _Undefined,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _isc.$UndefinedDateTime(),
    _itjn1vsu.MapEntityStatus? status,
    int? version,
  }) {
    return Building(
      id: id is int? ? id : this.id,
      buildingId: buildingId ?? this.buildingId,
      name: name ?? this.name,
      address: address is String? ? address : this.address,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is _isc.UndefinedSentinel
          ? this.deletedAt
          : deletedAt,
      status: status ?? this.status,
      version: version ?? this.version,
    );
  }
}
