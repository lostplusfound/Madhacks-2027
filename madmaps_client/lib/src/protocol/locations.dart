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

abstract class Locations
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Locations._({
    this.id,
    required this.locationId,
    required this.floor,
    this.roomNumber,
    this.name,
    this.category,
    this.aliases,
    this.routeNodeId,
    this.reviewNote,
  });

  factory Locations({
    int? id,
    required String locationId,
    required int floor,
    String? roomNumber,
    String? name,
    String? category,
    String? aliases,
    String? routeNodeId,
    String? reviewNote,
  }) = _LocationsImpl;

  factory Locations.fromJson(Map<String, dynamic> jsonSerialization) {
    return Locations(
      id: jsonSerialization['id'] as int?,
      locationId: jsonSerialization['location_id'] as String,
      floor: jsonSerialization['floor'] as int,
      roomNumber: jsonSerialization['room_number'] as String?,
      name: jsonSerialization['name'] as String?,
      category: jsonSerialization['category'] as String?,
      aliases: jsonSerialization['aliases'] as String?,
      routeNodeId: jsonSerialization['route_node_id'] as String?,
      reviewNote: jsonSerialization['review_note'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String locationId;

  int floor;

  String? roomNumber;

  String? name;

  String? category;

  String? aliases;

  String? routeNodeId;

  String? reviewNote;

  /// Returns a shallow copy of this [Locations]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Locations copyWith({
    int? id,
    String? locationId,
    int? floor,
    String? roomNumber,
    String? name,
    String? category,
    String? aliases,
    String? routeNodeId,
    String? reviewNote,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Locations',
      if (id != null) 'id': id,
      'location_id': locationId,
      'floor': floor,
      if (roomNumber != null) 'room_number': roomNumber,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (aliases != null) 'aliases': aliases,
      if (routeNodeId != null) 'route_node_id': routeNodeId,
      if (reviewNote != null) 'review_note': reviewNote,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Locations',
      if (id != null) 'id': id,
      'location_id': locationId,
      'floor': floor,
      if (roomNumber != null) 'room_number': roomNumber,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (aliases != null) 'aliases': aliases,
      if (routeNodeId != null) 'route_node_id': routeNodeId,
      if (reviewNote != null) 'review_note': reviewNote,
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
    required int floor,
    String? roomNumber,
    String? name,
    String? category,
    String? aliases,
    String? routeNodeId,
    String? reviewNote,
  }) : super._(
         id: id,
         locationId: locationId,
         floor: floor,
         roomNumber: roomNumber,
         name: name,
         category: category,
         aliases: aliases,
         routeNodeId: routeNodeId,
         reviewNote: reviewNote,
       );

  /// Returns a shallow copy of this [Locations]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Locations copyWith({
    Object? id = _Undefined,
    String? locationId,
    int? floor,
    Object? roomNumber = _Undefined,
    Object? name = _Undefined,
    Object? category = _Undefined,
    Object? aliases = _Undefined,
    Object? routeNodeId = _Undefined,
    Object? reviewNote = _Undefined,
  }) {
    return Locations(
      id: id is int? ? id : this.id,
      locationId: locationId ?? this.locationId,
      floor: floor ?? this.floor,
      roomNumber: roomNumber is String? ? roomNumber : this.roomNumber,
      name: name is String? ? name : this.name,
      category: category is String? ? category : this.category,
      aliases: aliases is String? ? aliases : this.aliases,
      routeNodeId: routeNodeId is String? ? routeNodeId : this.routeNodeId,
      reviewNote: reviewNote is String? ? reviewNote : this.reviewNote,
    );
  }
}
