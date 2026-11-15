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

abstract class Floor
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Floor._({
    this.id,
    required this.floorId,
    required this.buildingId,
    required this.floorNumber,
    this.name,
    required this.width,
    required this.height,
    double? metersPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : metersPerUnit = metersPerUnit ?? 1.0,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Floor({
    int? id,
    required String floorId,
    required int buildingId,
    required int floorNumber,
    String? name,
    required double width,
    required double height,
    double? metersPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FloorImpl;

  factory Floor.fromJson(Map<String, dynamic> jsonSerialization) {
    return Floor(
      id: jsonSerialization['id'] as int?,
      floorId: jsonSerialization['floorId'] as String,
      buildingId: jsonSerialization['buildingId'] as int,
      floorNumber: jsonSerialization['floorNumber'] as int,
      name: jsonSerialization['name'] as String?,
      width: (jsonSerialization['width'] as num).toDouble(),
      height: (jsonSerialization['height'] as num).toDouble(),
      metersPerUnit: (jsonSerialization['metersPerUnit'] as num?)?.toDouble(),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String floorId;

  int buildingId;

  int floorNumber;

  String? name;

  double width;

  double height;

  double metersPerUnit;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Floor]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Floor copyWith({
    int? id,
    String? floorId,
    int? buildingId,
    int? floorNumber,
    String? name,
    double? width,
    double? height,
    double? metersPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Floor',
      if (id != null) 'id': id,
      'floorId': floorId,
      'buildingId': buildingId,
      'floorNumber': floorNumber,
      if (name != null) 'name': name,
      'width': width,
      'height': height,
      'metersPerUnit': metersPerUnit,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Floor',
      if (id != null) 'id': id,
      'floorId': floorId,
      'buildingId': buildingId,
      'floorNumber': floorNumber,
      if (name != null) 'name': name,
      'width': width,
      'height': height,
      'metersPerUnit': metersPerUnit,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FloorImpl extends Floor {
  _FloorImpl({
    int? id,
    required String floorId,
    required int buildingId,
    required int floorNumber,
    String? name,
    required double width,
    required double height,
    double? metersPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         floorId: floorId,
         buildingId: buildingId,
         floorNumber: floorNumber,
         name: name,
         width: width,
         height: height,
         metersPerUnit: metersPerUnit,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Floor]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Floor copyWith({
    Object? id = _Undefined,
    String? floorId,
    int? buildingId,
    int? floorNumber,
    Object? name = _Undefined,
    double? width,
    double? height,
    double? metersPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Floor(
      id: id is int? ? id : this.id,
      floorId: floorId ?? this.floorId,
      buildingId: buildingId ?? this.buildingId,
      floorNumber: floorNumber ?? this.floorNumber,
      name: name is String? ? name : this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      metersPerUnit: metersPerUnit ?? this.metersPerUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
