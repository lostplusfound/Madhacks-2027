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

abstract class MapNodeInput
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MapNodeInput._({
    required this.nodeId,
    required this.floorId,
    required this.x,
    required this.y,
    this.locationId,
    required this.kind,
  });

  factory MapNodeInput({
    required String nodeId,
    required String floorId,
    required double x,
    required double y,
    String? locationId,
    required _iokugpqm.Kind kind,
  }) = _MapNodeInputImpl;

  factory MapNodeInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return MapNodeInput(
      nodeId: jsonSerialization['nodeId'] as String,
      floorId: jsonSerialization['floorId'] as String,
      x: (jsonSerialization['x'] as num).toDouble(),
      y: (jsonSerialization['y'] as num).toDouble(),
      locationId: jsonSerialization['locationId'] as String?,
      kind: _iokugpqm.Kind.fromJson((jsonSerialization['kind'] as String)),
    );
  }

  String nodeId;

  String floorId;

  double x;

  double y;

  String? locationId;

  _iokugpqm.Kind kind;

  /// Returns a shallow copy of this [MapNodeInput]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MapNodeInput copyWith({
    String? nodeId,
    String? floorId,
    double? x,
    double? y,
    String? locationId,
    _iokugpqm.Kind? kind,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MapNodeInput',
      'nodeId': nodeId,
      'floorId': floorId,
      'x': x,
      'y': y,
      if (locationId != null) 'locationId': locationId,
      'kind': kind.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MapNodeInput',
      'nodeId': nodeId,
      'floorId': floorId,
      'x': x,
      'y': y,
      if (locationId != null) 'locationId': locationId,
      'kind': kind.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MapNodeInputImpl extends MapNodeInput {
  _MapNodeInputImpl({
    required String nodeId,
    required String floorId,
    required double x,
    required double y,
    String? locationId,
    required _iokugpqm.Kind kind,
  }) : super._(
         nodeId: nodeId,
         floorId: floorId,
         x: x,
         y: y,
         locationId: locationId,
         kind: kind,
       );

  /// Returns a shallow copy of this [MapNodeInput]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MapNodeInput copyWith({
    String? nodeId,
    String? floorId,
    double? x,
    double? y,
    Object? locationId = _Undefined,
    _iokugpqm.Kind? kind,
  }) {
    return MapNodeInput(
      nodeId: nodeId ?? this.nodeId,
      floorId: floorId ?? this.floorId,
      x: x ?? this.x,
      y: y ?? this.y,
      locationId: locationId is String? ? locationId : this.locationId,
      kind: kind ?? this.kind,
    );
  }
}
