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

abstract class MapWall
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MapWall._({
    this.id,
    required this.graphId,
    required this.wallId,
    required this.floorId,
    required this.verticesJson,
  });

  factory MapWall({
    int? id,
    required int graphId,
    required String wallId,
    required String floorId,
    required String verticesJson,
  }) = _MapWallImpl;

  factory MapWall.fromJson(Map<String, dynamic> jsonSerialization) {
    return MapWall(
      id: jsonSerialization['id'] as int?,
      graphId: jsonSerialization['graphId'] as int,
      wallId: jsonSerialization['wallId'] as String,
      floorId: jsonSerialization['floorId'] as String,
      verticesJson: jsonSerialization['verticesJson'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int graphId;

  String wallId;

  String floorId;

  String verticesJson;

  /// Returns a shallow copy of this [MapWall]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MapWall copyWith({
    int? id,
    int? graphId,
    String? wallId,
    String? floorId,
    String? verticesJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MapWall',
      if (id != null) 'id': id,
      'graphId': graphId,
      'wallId': wallId,
      'floorId': floorId,
      'verticesJson': verticesJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MapWall',
      if (id != null) 'id': id,
      'graphId': graphId,
      'wallId': wallId,
      'floorId': floorId,
      'verticesJson': verticesJson,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MapWallImpl extends MapWall {
  _MapWallImpl({
    int? id,
    required int graphId,
    required String wallId,
    required String floorId,
    required String verticesJson,
  }) : super._(
         id: id,
         graphId: graphId,
         wallId: wallId,
         floorId: floorId,
         verticesJson: verticesJson,
       );

  /// Returns a shallow copy of this [MapWall]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MapWall copyWith({
    Object? id = _Undefined,
    int? graphId,
    String? wallId,
    String? floorId,
    String? verticesJson,
  }) {
    return MapWall(
      id: id is int? ? id : this.id,
      graphId: graphId ?? this.graphId,
      wallId: wallId ?? this.wallId,
      floorId: floorId ?? this.floorId,
      verticesJson: verticesJson ?? this.verticesJson,
    );
  }
}
