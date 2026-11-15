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

abstract class ArCapture
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ArCapture._({
    this.id,
    required this.captureId,
    required this.graphId,
    required this.graphVersion,
    required this.floorNumber,
    required this.anchorMapJson,
    required this.expiresAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ArCapture({
    int? id,
    required String captureId,
    required String graphId,
    required int graphVersion,
    required int floorNumber,
    required String anchorMapJson,
    required DateTime expiresAt,
    DateTime? createdAt,
  }) = _ArCaptureImpl;

  factory ArCapture.fromJson(Map<String, dynamic> jsonSerialization) {
    return ArCapture(
      id: jsonSerialization['id'] as int?,
      captureId: jsonSerialization['captureId'] as String,
      graphId: jsonSerialization['graphId'] as String,
      graphVersion: jsonSerialization['graphVersion'] as int,
      floorNumber: jsonSerialization['floorNumber'] as int,
      anchorMapJson: jsonSerialization['anchorMapJson'] as String,
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String captureId;

  String graphId;

  int graphVersion;

  int floorNumber;

  String anchorMapJson;

  DateTime expiresAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [ArCapture]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ArCapture copyWith({
    int? id,
    String? captureId,
    String? graphId,
    int? graphVersion,
    int? floorNumber,
    String? anchorMapJson,
    DateTime? expiresAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ArCapture',
      if (id != null) 'id': id,
      'captureId': captureId,
      'graphId': graphId,
      'graphVersion': graphVersion,
      'floorNumber': floorNumber,
      'anchorMapJson': anchorMapJson,
      'expiresAt': expiresAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ArCapture',
      if (id != null) 'id': id,
      'captureId': captureId,
      'graphId': graphId,
      'graphVersion': graphVersion,
      'floorNumber': floorNumber,
      'anchorMapJson': anchorMapJson,
      'expiresAt': expiresAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ArCaptureImpl extends ArCapture {
  _ArCaptureImpl({
    int? id,
    required String captureId,
    required String graphId,
    required int graphVersion,
    required int floorNumber,
    required String anchorMapJson,
    required DateTime expiresAt,
    DateTime? createdAt,
  }) : super._(
         id: id,
         captureId: captureId,
         graphId: graphId,
         graphVersion: graphVersion,
         floorNumber: floorNumber,
         anchorMapJson: anchorMapJson,
         expiresAt: expiresAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ArCapture]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ArCapture copyWith({
    Object? id = _Undefined,
    String? captureId,
    String? graphId,
    int? graphVersion,
    int? floorNumber,
    String? anchorMapJson,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return ArCapture(
      id: id is int? ? id : this.id,
      captureId: captureId ?? this.captureId,
      graphId: graphId ?? this.graphId,
      graphVersion: graphVersion ?? this.graphVersion,
      floorNumber: floorNumber ?? this.floorNumber,
      anchorMapJson: anchorMapJson ?? this.anchorMapJson,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
