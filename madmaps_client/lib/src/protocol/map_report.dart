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
import 'report_reason.dart' as _ijgj7dn0;
import 'report_status.dart' as _i8pcsu0p;
import 'report_target_type.dart' as _iyydfyiu;

abstract class MapReport
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MapReport._({
    this.id,
    required this.reportId,
    required this.targetType,
    required this.targetId,
    required this.reporterId,
    required this.reason,
    this.notes,
    _i8pcsu0p.ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : status = status ?? _i8pcsu0p.ReportStatus.open,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory MapReport({
    int? id,
    required String reportId,
    required _iyydfyiu.ReportTargetType targetType,
    required String targetId,
    required String reporterId,
    required _ijgj7dn0.ReportReason reason,
    String? notes,
    _i8pcsu0p.ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MapReportImpl;

  factory MapReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return MapReport(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as String,
      targetType: _iyydfyiu.ReportTargetType.fromJson(
        (jsonSerialization['targetType'] as String),
      ),
      targetId: jsonSerialization['targetId'] as String,
      reporterId: jsonSerialization['reporterId'] as String,
      reason: _ijgj7dn0.ReportReason.fromJson(
        (jsonSerialization['reason'] as String),
      ),
      notes: jsonSerialization['notes'] as String?,
      status: jsonSerialization['status'] == null
          ? null
          : _i8pcsu0p.ReportStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
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

  String reportId;

  _iyydfyiu.ReportTargetType targetType;

  String targetId;

  String reporterId;

  _ijgj7dn0.ReportReason reason;

  String? notes;

  _i8pcsu0p.ReportStatus status;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [MapReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MapReport copyWith({
    int? id,
    String? reportId,
    _iyydfyiu.ReportTargetType? targetType,
    String? targetId,
    String? reporterId,
    _ijgj7dn0.ReportReason? reason,
    String? notes,
    _i8pcsu0p.ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MapReport',
      if (id != null) 'id': id,
      'reportId': reportId,
      'targetType': targetType.toJson(),
      'targetId': targetId,
      'reporterId': reporterId,
      'reason': reason.toJson(),
      if (notes != null) 'notes': notes,
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MapReport',
      if (id != null) 'id': id,
      'reportId': reportId,
      'targetType': targetType.toJson(),
      'targetId': targetId,
      'reporterId': reporterId,
      'reason': reason.toJson(),
      if (notes != null) 'notes': notes,
      'status': status.toJson(),
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

class _MapReportImpl extends MapReport {
  _MapReportImpl({
    int? id,
    required String reportId,
    required _iyydfyiu.ReportTargetType targetType,
    required String targetId,
    required String reporterId,
    required _ijgj7dn0.ReportReason reason,
    String? notes,
    _i8pcsu0p.ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         reportId: reportId,
         targetType: targetType,
         targetId: targetId,
         reporterId: reporterId,
         reason: reason,
         notes: notes,
         status: status,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [MapReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MapReport copyWith({
    Object? id = _Undefined,
    String? reportId,
    _iyydfyiu.ReportTargetType? targetType,
    String? targetId,
    String? reporterId,
    _ijgj7dn0.ReportReason? reason,
    Object? notes = _Undefined,
    _i8pcsu0p.ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MapReport(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      reporterId: reporterId ?? this.reporterId,
      reason: reason ?? this.reason,
      notes: notes is String? ? notes : this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
