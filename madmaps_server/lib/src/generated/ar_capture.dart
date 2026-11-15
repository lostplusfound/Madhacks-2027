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

abstract class ArCapture
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ArCaptureTable();

  static const db = ArCaptureRepository._();

  @override
  int? id;

  String captureId;

  String graphId;

  int graphVersion;

  int floorNumber;

  String anchorMapJson;

  DateTime expiresAt;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ArCapture]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static ArCaptureInclude include() {
    return ArCaptureInclude._();
  }

  static ArCaptureIncludeList includeList({
    _is.WhereExpressionBuilder<ArCaptureTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ArCaptureTable>? orderBy,
    _is.OrderByListBuilder<ArCaptureTable>? orderByList,
    ArCaptureInclude? include,
  }) {
    return ArCaptureIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ArCapture.t),
      orderByList: orderByList?.call(ArCapture.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class ArCaptureUpdateTable extends _is.UpdateTable<ArCaptureTable> {
  ArCaptureUpdateTable(super.table);

  _is.ColumnValue<String, String> captureId(String value) => _is.ColumnValue(
    table.captureId,
    value,
  );

  _is.ColumnValue<String, String> graphId(String value) => _is.ColumnValue(
    table.graphId,
    value,
  );

  _is.ColumnValue<int, int> graphVersion(int value) => _is.ColumnValue(
    table.graphVersion,
    value,
  );

  _is.ColumnValue<int, int> floorNumber(int value) => _is.ColumnValue(
    table.floorNumber,
    value,
  );

  _is.ColumnValue<String, String> anchorMapJson(String value) =>
      _is.ColumnValue(
        table.anchorMapJson,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ArCaptureTable extends _is.Table<int?> {
  ArCaptureTable({super.tableRelation}) : super(tableName: 'ar_capture') {
    updateTable = ArCaptureUpdateTable(this);
    captureId = _is.ColumnString(
      'captureId',
      this,
    );
    graphId = _is.ColumnString(
      'graphId',
      this,
    );
    graphVersion = _is.ColumnInt(
      'graphVersion',
      this,
    );
    floorNumber = _is.ColumnInt(
      'floorNumber',
      this,
    );
    anchorMapJson = _is.ColumnString(
      'anchorMapJson',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final ArCaptureUpdateTable updateTable;

  late final _is.ColumnString captureId;

  late final _is.ColumnString graphId;

  late final _is.ColumnInt graphVersion;

  late final _is.ColumnInt floorNumber;

  late final _is.ColumnString anchorMapJson;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    captureId,
    graphId,
    graphVersion,
    floorNumber,
    anchorMapJson,
    expiresAt,
    createdAt,
  ];
}

class ArCaptureInclude extends _is.IncludeObject {
  ArCaptureInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ArCapture.t;
}

class ArCaptureIncludeList extends _is.IncludeList {
  ArCaptureIncludeList._({
    _is.WhereExpressionBuilder<ArCaptureTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ArCapture.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ArCapture.t;
}

class ArCaptureRepository {
  const ArCaptureRepository._();

  /// Returns a list of [ArCapture]s matching the given query parameters.
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
  Future<List<ArCapture>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ArCaptureTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ArCaptureTable>? orderBy,
    _is.OrderByListBuilder<ArCaptureTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ArCapture>(
      where: where?.call(ArCapture.t),
      orderBy: orderBy?.call(ArCapture.t),
      orderByList: orderByList?.call(ArCapture.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ArCapture]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ArCapture.t`.
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
  _ida.Stream<List<ArCapture>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ArCaptureTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ArCaptureTable>? orderBy,
    _is.OrderByListBuilder<ArCaptureTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ArCapture>(
      where: where?.call(ArCapture.t),
      orderBy: orderBy?.call(ArCapture.t),
      orderByList: orderByList?.call(ArCapture.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ArCapture] matching the given query parameters.
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
  Future<ArCapture?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ArCaptureTable>? where,
    int? offset,
    _is.OrderByBuilder<ArCaptureTable>? orderBy,
    _is.OrderByListBuilder<ArCaptureTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ArCapture>(
      where: where?.call(ArCapture.t),
      orderBy: orderBy?.call(ArCapture.t),
      orderByList: orderByList?.call(ArCapture.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ArCapture] by its [id] or null if no such row exists.
  Future<ArCapture?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ArCapture>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ArCapture]s in the list and returns the inserted rows.
  ///
  /// The returned [ArCapture]s will have their `id` fields set.
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
  Future<List<ArCapture>> insert(
    _is.DatabaseSession session,
    List<ArCapture> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ArCapture>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ArCapture] and returns the inserted row.
  ///
  /// The returned [ArCapture] will have its `id` field set.
  Future<ArCapture> insertRow(
    _is.DatabaseSession session,
    ArCapture row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ArCapture>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ArCapture]s in the list and returns the resulting rows.
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
  /// The returned [ArCapture]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ArCapture>> upsert(
    _is.DatabaseSession session,
    List<ArCapture> rows, {
    required _is.ColumnSelections<ArCaptureTable> conflictColumns,
    _is.ColumnSelections<ArCaptureTable>? updateColumns,
    _is.WhereExpressionBuilder<ArCaptureTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ArCapture>(
      rows,
      conflictColumns: conflictColumns(ArCapture.t),
      updateColumns: updateColumns?.call(ArCapture.t),
      updateWhere: updateWhere?.call(ArCapture.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ArCapture] and returns the resulting row.
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
  /// The returned [ArCapture] will have its `id` field set.
  Future<ArCapture?> upsertRow(
    _is.DatabaseSession session,
    ArCapture row, {
    required _is.ColumnSelections<ArCaptureTable> conflictColumns,
    _is.ColumnSelections<ArCaptureTable>? updateColumns,
    _is.WhereExpressionBuilder<ArCaptureTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ArCapture>(
      row,
      conflictColumns: conflictColumns(ArCapture.t),
      updateColumns: updateColumns?.call(ArCapture.t),
      updateWhere: updateWhere?.call(ArCapture.t),
      transaction: transaction,
    );
  }

  /// Updates all [ArCapture]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ArCapture>> update(
    _is.DatabaseSession session,
    List<ArCapture> rows, {
    _is.ColumnSelections<ArCaptureTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ArCapture>(
      rows,
      columns: columns?.call(ArCapture.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ArCapture]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ArCapture> updateRow(
    _is.DatabaseSession session,
    ArCapture row, {
    _is.ColumnSelections<ArCaptureTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ArCapture>(
      row,
      columns: columns?.call(ArCapture.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ArCapture] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ArCapture?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ArCaptureUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ArCapture>(
      id,
      columnValues: columnValues(ArCapture.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ArCapture]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ArCapture>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ArCaptureUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ArCaptureTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ArCaptureTable>? orderBy,
    _is.OrderByListBuilder<ArCaptureTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ArCapture>(
      columnValues: columnValues(ArCapture.t.updateTable),
      where: where(ArCapture.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ArCapture.t),
      orderByList: orderByList?.call(ArCapture.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ArCapture]s in the list and returns the deleted rows.
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
  Future<List<ArCapture>> delete(
    _is.DatabaseSession session,
    List<ArCapture> rows, {
    _is.OrderByBuilder<ArCaptureTable>? orderBy,
    _is.OrderByListBuilder<ArCaptureTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ArCapture>(
      rows,
      orderBy: orderBy?.call(ArCapture.t),
      orderByList: orderByList?.call(ArCapture.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ArCapture].
  Future<ArCapture> deleteRow(
    _is.DatabaseSession session,
    ArCapture row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ArCapture>(
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
  Future<List<ArCapture>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ArCaptureTable> where,
    _is.OrderByBuilder<ArCaptureTable>? orderBy,
    _is.OrderByListBuilder<ArCaptureTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ArCapture>(
      where: where(ArCapture.t),
      orderBy: orderBy?.call(ArCapture.t),
      orderByList: orderByList?.call(ArCapture.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ArCaptureTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ArCapture>(
      where: where?.call(ArCapture.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ArCapture] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ArCaptureTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ArCapture>(
      where: where(ArCapture.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
