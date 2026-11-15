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
import 'location_category.dart' as _ipivyxsl;
import 'map_entity_status.dart' as _itjn1vsu;

abstract class Locations
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Locations._({
    this.id,
    required this.locationId,
    this.graphId,
    this.floorId,
    required this.floor,
    this.roomNumber,
    this.name,
    _ipivyxsl.LocationCategory? category,
    this.aliases,
    this.routeNodeId,
    this.reviewNote,
    _itjn1vsu.MapEntityStatus? status,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    int? version,
  }) : category = category ?? _ipivyxsl.LocationCategory.other,
       status = status ?? _itjn1vsu.MapEntityStatus.active,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       version = version ?? 1;

  factory Locations({
    int? id,
    required String locationId,
    int? graphId,
    int? floorId,
    required int floor,
    String? roomNumber,
    String? name,
    _ipivyxsl.LocationCategory? category,
    String? aliases,
    String? routeNodeId,
    String? reviewNote,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) = _LocationsImpl;

  factory Locations.fromJson(Map<String, dynamic> jsonSerialization) {
    return Locations(
      id: jsonSerialization['id'] as int?,
      locationId: jsonSerialization['locationId'] as String,
      graphId: jsonSerialization['graphId'] as int?,
      floorId: jsonSerialization['floorId'] as int?,
      floor: jsonSerialization['floor'] as int,
      roomNumber: jsonSerialization['roomNumber'] as String?,
      name: jsonSerialization['name'] as String?,
      category: jsonSerialization['category'] == null
          ? null
          : _ipivyxsl.LocationCategory.fromJson(
              (jsonSerialization['category'] as String),
            ),
      aliases: jsonSerialization['aliases'] as String?,
      routeNodeId: jsonSerialization['routeNodeId'] as String?,
      reviewNote: jsonSerialization['reviewNote'] as String?,
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

  String locationId;

  int? graphId;

  int? floorId;

  int floor;

  String? roomNumber;

  String? name;

  _ipivyxsl.LocationCategory? category;

  String? aliases;

  String? routeNodeId;

  String? reviewNote;

  _itjn1vsu.MapEntityStatus status;

  String? createdBy;

  String? updatedBy;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  int version;

  /// Returns a shallow copy of this [Locations]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Locations copyWith({
    int? id,
    String? locationId,
    int? graphId,
    int? floorId,
    int? floor,
    String? roomNumber,
    String? name,
    _ipivyxsl.LocationCategory? category,
    String? aliases,
    String? routeNodeId,
    String? reviewNote,
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
      '__className__': 'Locations',
      if (id != null) 'id': id,
      'locationId': locationId,
      if (graphId != null) 'graphId': graphId,
      if (floorId != null) 'floorId': floorId,
      'floor': floor,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (name != null) 'name': name,
      if (category != null) 'category': category?.toJson(),
      if (aliases != null) 'aliases': aliases,
      if (routeNodeId != null) 'routeNodeId': routeNodeId,
      if (reviewNote != null) 'reviewNote': reviewNote,
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
      '__className__': 'Locations',
      if (id != null) 'id': id,
      'locationId': locationId,
      if (graphId != null) 'graphId': graphId,
      if (floorId != null) 'floorId': floorId,
      'floor': floor,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (name != null) 'name': name,
      if (category != null) 'category': category?.toJson(),
      if (aliases != null) 'aliases': aliases,
      if (routeNodeId != null) 'routeNodeId': routeNodeId,
      if (reviewNote != null) 'reviewNote': reviewNote,
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

class _LocationsImpl extends Locations {
  _LocationsImpl({
    int? id,
    required String locationId,
    int? graphId,
    int? floorId,
    required int floor,
    String? roomNumber,
    String? name,
    _ipivyxsl.LocationCategory? category,
    String? aliases,
    String? routeNodeId,
    String? reviewNote,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) : super._(
         id: id,
         locationId: locationId,
         graphId: graphId,
         floorId: floorId,
         floor: floor,
         roomNumber: roomNumber,
         name: name,
         category: category,
         aliases: aliases,
         routeNodeId: routeNodeId,
         reviewNote: reviewNote,
         status: status,
         createdBy: createdBy,
         updatedBy: updatedBy,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
         version: version,
       );

  /// Returns a shallow copy of this [Locations]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Locations copyWith({
    Object? id = _Undefined,
    String? locationId,
    Object? graphId = _Undefined,
    Object? floorId = _Undefined,
    int? floor,
    Object? roomNumber = _Undefined,
    Object? name = _Undefined,
    Object? category = _Undefined,
    Object? aliases = _Undefined,
    Object? routeNodeId = _Undefined,
    Object? reviewNote = _Undefined,
    _itjn1vsu.MapEntityStatus? status,
    Object? createdBy = _Undefined,
    Object? updatedBy = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _isc.$UndefinedDateTime(),
    int? version,
  }) {
    return Locations(
      id: id is int? ? id : this.id,
      locationId: locationId ?? this.locationId,
      graphId: graphId is int? ? graphId : this.graphId,
      floorId: floorId is int? ? floorId : this.floorId,
      floor: floor ?? this.floor,
      roomNumber: roomNumber is String? ? roomNumber : this.roomNumber,
      name: name is String? ? name : this.name,
      category: category is _ipivyxsl.LocationCategory?
          ? category
          : this.category,
      aliases: aliases is String? ? aliases : this.aliases,
      routeNodeId: routeNodeId is String? ? routeNodeId : this.routeNodeId,
      reviewNote: reviewNote is String? ? reviewNote : this.reviewNote,
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
