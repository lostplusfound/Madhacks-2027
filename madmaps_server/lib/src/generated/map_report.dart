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
import 'dart:async' as _ida;
import 'package:serverpod/serverpod.dart' as _is;
import 'report_reason.dart' as _ijgj7dn0;
import 'report_status.dart' as _i8pcsu0p;
import 'report_target_type.dart' as _iyydfyiu;

abstract class MapReport
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = MapReportTable();

  static const db = MapReportRepository._();

  @override
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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MapReport]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static MapReportInclude include() {
    return MapReportInclude._();
  }

  static MapReportIncludeList includeList({
    _is.WhereExpressionBuilder<MapReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MapReportTable>? orderBy,
    _is.OrderByListBuilder<MapReportTable>? orderByList,
    MapReportInclude? include,
  }) {
    return MapReportIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MapReport.t),
      orderByList: orderByList?.call(MapReport.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class MapReportUpdateTable extends _is.UpdateTable<MapReportTable> {
  MapReportUpdateTable(super.table);

  _is.ColumnValue<String, String> reportId(String value) => _is.ColumnValue(
    table.reportId,
    value,
  );

  _is.ColumnValue<_iyydfyiu.ReportTargetType, _iyydfyiu.ReportTargetType>
  targetType(_iyydfyiu.ReportTargetType value) => _is.ColumnValue(
    table.targetType,
    value,
  );

  _is.ColumnValue<String, String> targetId(String value) => _is.ColumnValue(
    table.targetId,
    value,
  );

  _is.ColumnValue<String, String> reporterId(String value) => _is.ColumnValue(
    table.reporterId,
    value,
  );

  _is.ColumnValue<_ijgj7dn0.ReportReason, _ijgj7dn0.ReportReason> reason(
    _ijgj7dn0.ReportReason value,
  ) => _is.ColumnValue(
    table.reason,
    value,
  );

  _is.ColumnValue<String, String> notes(String? value) => _is.ColumnValue(
    table.notes,
    value,
  );

  _is.ColumnValue<_i8pcsu0p.ReportStatus, _i8pcsu0p.ReportStatus> status(
    _i8pcsu0p.ReportStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class MapReportTable extends _is.Table<int?> {
  MapReportTable({super.tableRelation}) : super(tableName: 'map_report') {
    updateTable = MapReportUpdateTable(this);
    reportId = _is.ColumnString(
      'report_id',
      this,
      fieldName: 'reportId',
    );
    targetType = _is.ColumnEnum(
      'target_type',
      this,
      _is.EnumSerialization.byName,
      fieldName: 'targetType',
    );
    targetId = _is.ColumnString(
      'target_id',
      this,
      fieldName: 'targetId',
    );
    reporterId = _is.ColumnString(
      'reporter_id',
      this,
      fieldName: 'reporterId',
    );
    reason = _is.ColumnEnum(
      'reason',
      this,
      _is.EnumSerialization.byName,
    );
    notes = _is.ColumnString(
      'notes',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'created_at',
      this,
      hasDefault: true,
      fieldName: 'createdAt',
    );
    updatedAt = _is.ColumnDateTime(
      'updated_at',
      this,
      hasDefault: true,
      fieldName: 'updatedAt',
    );
  }

  late final MapReportUpdateTable updateTable;

  late final _is.ColumnString reportId;

  late final _is.ColumnEnum<_iyydfyiu.ReportTargetType> targetType;

  late final _is.ColumnString targetId;

  late final _is.ColumnString reporterId;

  late final _is.ColumnEnum<_ijgj7dn0.ReportReason> reason;

  late final _is.ColumnString notes;

  late final _is.ColumnEnum<_i8pcsu0p.ReportStatus> status;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    reportId,
    targetType,
    targetId,
    reporterId,
    reason,
    notes,
    status,
    createdAt,
    updatedAt,
  ];
}

class MapReportInclude extends _is.IncludeObject {
  MapReportInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => MapReport.t;
}

class MapReportIncludeList extends _is.IncludeList {
  MapReportIncludeList._({
    _is.WhereExpressionBuilder<MapReportTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MapReport.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MapReport.t;
}

class MapReportRepository {
  const MapReportRepository._();

  /// Returns a list of [MapReport]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<MapReport>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MapReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MapReportTable>? orderBy,
    _is.OrderByListBuilder<MapReportTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MapReport>(
      where: where?.call(MapReport.t),
      orderBy: orderBy?.call(MapReport.t),
      orderByList: orderByList?.call(MapReport.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [MapReport]s matching the given query parameters every time the
  /// source tables are modified.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// Use [throttle] to specify the minimum interval between queries. It can
  /// also be set to `null`, in which case the stream will only be throttled
  /// when its subscription is paused.
  ///
  /// Source tables are collected from the queried table, [where], [orderBy],
  /// [orderByList], and the [include] graph. [alsoTriggerOnTables] is added
  /// to that set. Pass [Table] instances such as `MapReport.t`.
  ///
  /// Raw [Expression] SQL is not inspected. Tables referenced only in raw
  /// SQL must be passed via [alsoTriggerOnTables].
  ///
  /// The stream always reads committed state and never joins an ambient
  /// [Transaction]. Emissions for a write fire after that write commits.
  ///
  /// Currently only supported on SQLite. Calling this method on PostgreSQL
  /// throws an [UnsupportedError].
  ///
  /// ```dart
  /// var subscription = Persons.db.watch(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// ).listen((persons) {
  ///   // Handle the latest matching rows.
  /// });
  /// ```
  _ida.Stream<List<MapReport>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MapReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MapReportTable>? orderBy,
    _is.OrderByListBuilder<MapReportTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<MapReport>(
      where: where?.call(MapReport.t),
      orderBy: orderBy?.call(MapReport.t),
      orderByList: orderByList?.call(MapReport.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [MapReport] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<MapReport?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MapReportTable>? where,
    int? offset,
    _is.OrderByBuilder<MapReportTable>? orderBy,
    _is.OrderByListBuilder<MapReportTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MapReport>(
      where: where?.call(MapReport.t),
      orderBy: orderBy?.call(MapReport.t),
      orderByList: orderByList?.call(MapReport.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MapReport] by its [id] or null if no such row exists.
  Future<MapReport?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MapReport>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MapReport]s in the list and returns the inserted rows.
  ///
  /// The returned [MapReport]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MapReport>> insert(
    _is.DatabaseSession session,
    List<MapReport> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MapReport>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MapReport] and returns the inserted row.
  ///
  /// The returned [MapReport] will have its `id` field set.
  Future<MapReport> insertRow(
    _is.DatabaseSession session,
    MapReport row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MapReport>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MapReport]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [MapReport]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MapReport>> upsert(
    _is.DatabaseSession session,
    List<MapReport> rows, {
    required _is.ColumnSelections<MapReportTable> conflictColumns,
    _is.ColumnSelections<MapReportTable>? updateColumns,
    _is.WhereExpressionBuilder<MapReportTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MapReport>(
      rows,
      conflictColumns: conflictColumns(MapReport.t),
      updateColumns: updateColumns?.call(MapReport.t),
      updateWhere: updateWhere?.call(MapReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MapReport] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [MapReport] will have its `id` field set.
  Future<MapReport?> upsertRow(
    _is.DatabaseSession session,
    MapReport row, {
    required _is.ColumnSelections<MapReportTable> conflictColumns,
    _is.ColumnSelections<MapReportTable>? updateColumns,
    _is.WhereExpressionBuilder<MapReportTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MapReport>(
      row,
      conflictColumns: conflictColumns(MapReport.t),
      updateColumns: updateColumns?.call(MapReport.t),
      updateWhere: updateWhere?.call(MapReport.t),
      transaction: transaction,
    );
  }

  /// Updates all [MapReport]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MapReport>> update(
    _is.DatabaseSession session,
    List<MapReport> rows, {
    _is.ColumnSelections<MapReportTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MapReport>(
      rows,
      columns: columns?.call(MapReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MapReport]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MapReport> updateRow(
    _is.DatabaseSession session,
    MapReport row, {
    _is.ColumnSelections<MapReportTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MapReport>(
      row,
      columns: columns?.call(MapReport.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MapReport] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MapReport?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MapReportUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MapReport>(
      id,
      columnValues: columnValues(MapReport.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MapReport]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MapReport>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MapReportUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MapReportTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MapReportTable>? orderBy,
    _is.OrderByListBuilder<MapReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MapReport>(
      columnValues: columnValues(MapReport.t.updateTable),
      where: where(MapReport.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MapReport.t),
      orderByList: orderByList?.call(MapReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MapReport]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MapReport>> delete(
    _is.DatabaseSession session,
    List<MapReport> rows, {
    _is.OrderByBuilder<MapReportTable>? orderBy,
    _is.OrderByListBuilder<MapReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MapReport>(
      rows,
      orderBy: orderBy?.call(MapReport.t),
      orderByList: orderByList?.call(MapReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MapReport].
  Future<MapReport> deleteRow(
    _is.DatabaseSession session,
    MapReport row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MapReport>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MapReport>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MapReportTable> where,
    _is.OrderByBuilder<MapReportTable>? orderBy,
    _is.OrderByListBuilder<MapReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MapReport>(
      where: where(MapReport.t),
      orderBy: orderBy?.call(MapReport.t),
      orderByList: orderByList?.call(MapReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MapReportTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MapReport>(
      where: where?.call(MapReport.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MapReport] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MapReportTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MapReport>(
      where: where(MapReport.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
