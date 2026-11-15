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

abstract class PlaceMap
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PlaceMap._({
    this.id,
    required this.mapId,
    required this.buildingName,
    required this.floorLabel,
    required this.mapJson,
    int? version,
    DateTime? updatedAt,
  }) : version = version ?? 1,
       updatedAt = updatedAt ?? DateTime.now();

  factory PlaceMap({
    int? id,
    required String mapId,
    required String buildingName,
    required String floorLabel,
    required String mapJson,
    int? version,
    DateTime? updatedAt,
  }) = _PlaceMapImpl;

  factory PlaceMap.fromJson(Map<String, dynamic> jsonSerialization) {
    return PlaceMap(
      id: jsonSerialization['id'] as int?,
      mapId: jsonSerialization['mapId'] as String,
      buildingName: jsonSerialization['buildingName'] as String,
      floorLabel: jsonSerialization['floorLabel'] as String,
      mapJson: jsonSerialization['mapJson'] as String,
      version: jsonSerialization['version'] as int?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String mapId;

  String buildingName;

  String floorLabel;

  String mapJson;

  int version;

  DateTime updatedAt;

  /// Returns a shallow copy of this [PlaceMap]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PlaceMap copyWith({
    int? id,
    String? mapId,
    String? buildingName,
    String? floorLabel,
    String? mapJson,
    int? version,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PlaceMap',
      if (id != null) 'id': id,
      'mapId': mapId,
      'buildingName': buildingName,
      'floorLabel': floorLabel,
      'mapJson': mapJson,
      'version': version,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PlaceMap',
      if (id != null) 'id': id,
      'mapId': mapId,
      'buildingName': buildingName,
      'floorLabel': floorLabel,
      'mapJson': mapJson,
      'version': version,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PlaceMapImpl extends PlaceMap {
  _PlaceMapImpl({
    int? id,
    required String mapId,
    required String buildingName,
    required String floorLabel,
    required String mapJson,
    int? version,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         mapId: mapId,
         buildingName: buildingName,
         floorLabel: floorLabel,
         mapJson: mapJson,
         version: version,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [PlaceMap]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PlaceMap copyWith({
    Object? id = _Undefined,
    String? mapId,
    String? buildingName,
    String? floorLabel,
    String? mapJson,
    int? version,
    DateTime? updatedAt,
  }) {
    return PlaceMap(
      id: id is int? ? id : this.id,
      mapId: mapId ?? this.mapId,
      buildingName: buildingName ?? this.buildingName,
      floorLabel: floorLabel ?? this.floorLabel,
      mapJson: mapJson ?? this.mapJson,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
