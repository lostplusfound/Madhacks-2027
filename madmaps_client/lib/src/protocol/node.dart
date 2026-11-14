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

abstract class Nodes
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Nodes._({
    this.id,
    required this.nodeId,
    required this.floor,
    required this.x,
    required this.y,
    this.locationId,
    required this.kind,
    required this.status,
  });

  factory Nodes({
    int? id,
    required String nodeId,
    required int floor,
    required double x,
    required double y,
    String? locationId,
    required _iokugpqm.Kind kind,
    required String status,
  }) = _NodesImpl;

  factory Nodes.fromJson(Map<String, dynamic> jsonSerialization) {
    return Nodes(
      id: jsonSerialization['id'] as int?,
      nodeId: jsonSerialization['node_id'] as String,
      floor: jsonSerialization['floor'] as int,
      x: (jsonSerialization['x'] as num).toDouble(),
      y: (jsonSerialization['y'] as num).toDouble(),
      locationId: jsonSerialization['location_id'] as String?,
      kind: _iokugpqm.Kind.fromJson((jsonSerialization['kind'] as String)),
      status: jsonSerialization['status'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String nodeId;

  int floor;

  double x;

  double y;

  String? locationId;

  _iokugpqm.Kind kind;

  String status;

  /// Returns a shallow copy of this [Nodes]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Nodes copyWith({
    int? id,
    String? nodeId,
    int? floor,
    double? x,
    double? y,
    String? locationId,
    _iokugpqm.Kind? kind,
    String? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Nodes',
      if (id != null) 'id': id,
      'node_id': nodeId,
      'floor': floor,
      'x': x,
      'y': y,
      if (locationId != null) 'location_id': locationId,
      'kind': kind.toJson(),
      'status': status,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Nodes',
      if (id != null) 'id': id,
      'node_id': nodeId,
      'floor': floor,
      'x': x,
      'y': y,
      if (locationId != null) 'location_id': locationId,
      'kind': kind.toJson(),
      'status': status,
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
    required int floor,
    required double x,
    required double y,
    String? locationId,
    required _iokugpqm.Kind kind,
    required String status,
  }) : super._(
         id: id,
         nodeId: nodeId,
         floor: floor,
         x: x,
         y: y,
         locationId: locationId,
         kind: kind,
         status: status,
       );

  /// Returns a shallow copy of this [Nodes]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Nodes copyWith({
    Object? id = _Undefined,
    String? nodeId,
    int? floor,
    double? x,
    double? y,
    Object? locationId = _Undefined,
    _iokugpqm.Kind? kind,
    String? status,
  }) {
    return Nodes(
      id: id is int? ? id : this.id,
      nodeId: nodeId ?? this.nodeId,
      floor: floor ?? this.floor,
      x: x ?? this.x,
      y: y ?? this.y,
      locationId: locationId is String? ? locationId : this.locationId,
      kind: kind ?? this.kind,
      status: status ?? this.status,
    );
  }
}
