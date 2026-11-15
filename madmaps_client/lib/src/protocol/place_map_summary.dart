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

abstract class PlaceMapSummary
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PlaceMapSummary._({
    required this.mapId,
    required this.buildingName,
    required this.floorLabel,
    required this.placesJson,
    required this.version,
  });

  factory PlaceMapSummary({
    required String mapId,
    required String buildingName,
    required String floorLabel,
    required String placesJson,
    required int version,
  }) = _PlaceMapSummaryImpl;

  factory PlaceMapSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return PlaceMapSummary(
      mapId: jsonSerialization['mapId'] as String,
      buildingName: jsonSerialization['buildingName'] as String,
      floorLabel: jsonSerialization['floorLabel'] as String,
      placesJson: jsonSerialization['placesJson'] as String,
      version: jsonSerialization['version'] as int,
    );
  }

  String mapId;

  String buildingName;

  String floorLabel;

  String placesJson;

  int version;

  /// Returns a shallow copy of this [PlaceMapSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PlaceMapSummary copyWith({
    String? mapId,
    String? buildingName,
    String? floorLabel,
    String? placesJson,
    int? version,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PlaceMapSummary',
      'mapId': mapId,
      'buildingName': buildingName,
      'floorLabel': floorLabel,
      'placesJson': placesJson,
      'version': version,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PlaceMapSummary',
      'mapId': mapId,
      'buildingName': buildingName,
      'floorLabel': floorLabel,
      'placesJson': placesJson,
      'version': version,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _PlaceMapSummaryImpl extends PlaceMapSummary {
  _PlaceMapSummaryImpl({
    required String mapId,
    required String buildingName,
    required String floorLabel,
    required String placesJson,
    required int version,
  }) : super._(
         mapId: mapId,
         buildingName: buildingName,
         floorLabel: floorLabel,
         placesJson: placesJson,
         version: version,
       );

  /// Returns a shallow copy of this [PlaceMapSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PlaceMapSummary copyWith({
    String? mapId,
    String? buildingName,
    String? floorLabel,
    String? placesJson,
    int? version,
  }) {
    return PlaceMapSummary(
      mapId: mapId ?? this.mapId,
      buildingName: buildingName ?? this.buildingName,
      floorLabel: floorLabel ?? this.floorLabel,
      placesJson: placesJson ?? this.placesJson,
      version: version ?? this.version,
    );
  }
}
