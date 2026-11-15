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
import 'package:serverpod/serverpod.dart' as _is;
import 'location_category.dart' as _ipivyxsl;

abstract class LocationInput
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LocationInput._({
    required this.locationId,
    required this.floorId,
    this.roomNumber,
    this.name,
    required this.category,
    this.aliases,
    this.routeNodeId,
  });

  factory LocationInput({
    required String locationId,
    required String floorId,
    String? roomNumber,
    String? name,
    required _ipivyxsl.LocationCategory category,
    String? aliases,
    String? routeNodeId,
  }) = _LocationInputImpl;

  factory LocationInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return LocationInput(
      locationId: jsonSerialization['locationId'] as String,
      floorId: jsonSerialization['floorId'] as String,
      roomNumber: jsonSerialization['roomNumber'] as String?,
      name: jsonSerialization['name'] as String?,
      category: _ipivyxsl.LocationCategory.fromJson(
        (jsonSerialization['category'] as String),
      ),
      aliases: jsonSerialization['aliases'] as String?,
      routeNodeId: jsonSerialization['routeNodeId'] as String?,
    );
  }

  String locationId;

  String floorId;

  String? roomNumber;

  String? name;

  _ipivyxsl.LocationCategory category;

  String? aliases;

  String? routeNodeId;

  /// Returns a shallow copy of this [LocationInput]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LocationInput copyWith({
    String? locationId,
    String? floorId,
    String? roomNumber,
    String? name,
    _ipivyxsl.LocationCategory? category,
    String? aliases,
    String? routeNodeId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LocationInput',
      'locationId': locationId,
      'floorId': floorId,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (name != null) 'name': name,
      'category': category.toJson(),
      if (aliases != null) 'aliases': aliases,
      if (routeNodeId != null) 'routeNodeId': routeNodeId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LocationInput',
      'locationId': locationId,
      'floorId': floorId,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (name != null) 'name': name,
      'category': category.toJson(),
      if (aliases != null) 'aliases': aliases,
      if (routeNodeId != null) 'routeNodeId': routeNodeId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LocationInputImpl extends LocationInput {
  _LocationInputImpl({
    required String locationId,
    required String floorId,
    String? roomNumber,
    String? name,
    required _ipivyxsl.LocationCategory category,
    String? aliases,
    String? routeNodeId,
  }) : super._(
         locationId: locationId,
         floorId: floorId,
         roomNumber: roomNumber,
         name: name,
         category: category,
         aliases: aliases,
         routeNodeId: routeNodeId,
       );

  /// Returns a shallow copy of this [LocationInput]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LocationInput copyWith({
    String? locationId,
    String? floorId,
    Object? roomNumber = _Undefined,
    Object? name = _Undefined,
    _ipivyxsl.LocationCategory? category,
    Object? aliases = _Undefined,
    Object? routeNodeId = _Undefined,
  }) {
    return LocationInput(
      locationId: locationId ?? this.locationId,
      floorId: floorId ?? this.floorId,
      roomNumber: roomNumber is String? ? roomNumber : this.roomNumber,
      name: name is String? ? name : this.name,
      category: category ?? this.category,
      aliases: aliases is String? ? aliases : this.aliases,
      routeNodeId: routeNodeId is String? ? routeNodeId : this.routeNodeId,
    );
  }
}
