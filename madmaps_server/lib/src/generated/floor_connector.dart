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
import 'edge_type.dart' as _iv43g6lk;

abstract class FloorConnector
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  FloorConnector._({
    this.id,
    required this.connectorId,
    required this.buildingId,
    required this.label,
    required this.fromGraphId,
    required this.fromFloor,
    required this.fromNodeId,
    required this.toGraphId,
    required this.toFloor,
    required this.toNodeId,
    required this.type,
    required this.seconds,
    bool? bidirectional,
    bool? active,
  }) : bidirectional = bidirectional ?? true,
       active = active ?? true;

  factory FloorConnector({
    int? id,
    required String connectorId,
    required String buildingId,
    required String label,
    required String fromGraphId,
    required int fromFloor,
    required String fromNodeId,
    required String toGraphId,
    required int toFloor,
    required String toNodeId,
    required _iv43g6lk.EdgeType type,
    required double seconds,
    bool? bidirectional,
    bool? active,
  }) = _FloorConnectorImpl;

  factory FloorConnector.fromJson(Map<String, dynamic> jsonSerialization) {
    return FloorConnector(
      id: jsonSerialization['id'] as int?,
      connectorId: jsonSerialization['connectorId'] as String,
      buildingId: jsonSerialization['buildingId'] as String,
      label: jsonSerialization['label'] as String,
      fromGraphId: jsonSerialization['fromGraphId'] as String,
      fromFloor: jsonSerialization['fromFloor'] as int,
      fromNodeId: jsonSerialization['fromNodeId'] as String,
      toGraphId: jsonSerialization['toGraphId'] as String,
      toFloor: jsonSerialization['toFloor'] as int,
      toNodeId: jsonSerialization['toNodeId'] as String,
      type: _iv43g6lk.EdgeType.fromJson((jsonSerialization['type'] as String)),
      seconds: (jsonSerialization['seconds'] as num).toDouble(),
      bidirectional: jsonSerialization['bidirectional'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['bidirectional']),
      active: jsonSerialization['active'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['active']),
    );
  }

  static final t = FloorConnectorTable();

  static const db = FloorConnectorRepository._();

  @override
  int? id;

  String connectorId;

  String buildingId;

  String label;

  String fromGraphId;

  int fromFloor;

  String fromNodeId;

  String toGraphId;

  int toFloor;

  String toNodeId;

  _iv43g6lk.EdgeType type;

  double seconds;

  bool bidirectional;

  bool active;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [FloorConnector]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FloorConnector copyWith({
    int? id,
    String? connectorId,
    String? buildingId,
    String? label,
    String? fromGraphId,
    int? fromFloor,
    String? fromNodeId,
    String? toGraphId,
    int? toFloor,
    String? toNodeId,
    _iv43g6lk.EdgeType? type,
    double? seconds,
    bool? bidirectional,
    bool? active,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FloorConnector',
      if (id != null) 'id': id,
      'connectorId': connectorId,
      'buildingId': buildingId,
      'label': label,
      'fromGraphId': fromGraphId,
      'fromFloor': fromFloor,
      'fromNodeId': fromNodeId,
      'toGraphId': toGraphId,
      'toFloor': toFloor,
      'toNodeId': toNodeId,
      'type': type.toJson(),
      'seconds': seconds,
      'bidirectional': bidirectional,
      'active': active,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FloorConnector',
      if (id != null) 'id': id,
      'connectorId': connectorId,
      'buildingId': buildingId,
      'label': label,
      'fromGraphId': fromGraphId,
      'fromFloor': fromFloor,
      'fromNodeId': fromNodeId,
      'toGraphId': toGraphId,
      'toFloor': toFloor,
      'toNodeId': toNodeId,
      'type': type.toJson(),
      'seconds': seconds,
      'bidirectional': bidirectional,
      'active': active,
    };
  }

  static FloorConnectorInclude include() {
    return FloorConnectorInclude._();
  }

  static FloorConnectorIncludeList includeList({
    _is.WhereExpressionBuilder<FloorConnectorTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FloorConnectorTable>? orderBy,
    _is.OrderByListBuilder<FloorConnectorTable>? orderByList,
    FloorConnectorInclude? include,
  }) {
    return FloorConnectorIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FloorConnector.t),
      orderByList: orderByList?.call(FloorConnector.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FloorConnectorImpl extends FloorConnector {
  _FloorConnectorImpl({
    int? id,
    required String connectorId,
    required String buildingId,
    required String label,
    required String fromGraphId,
    required int fromFloor,
    required String fromNodeId,
    required String toGraphId,
    required int toFloor,
    required String toNodeId,
    required _iv43g6lk.EdgeType type,
    required double seconds,
    bool? bidirectional,
    bool? active,
  }) : super._(
         id: id,
         connectorId: connectorId,
         buildingId: buildingId,
         label: label,
         fromGraphId: fromGraphId,
         fromFloor: fromFloor,
         fromNodeId: fromNodeId,
         toGraphId: toGraphId,
         toFloor: toFloor,
         toNodeId: toNodeId,
         type: type,
         seconds: seconds,
         bidirectional: bidirectional,
         active: active,
       );

  /// Returns a shallow copy of this [FloorConnector]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FloorConnector copyWith({
    Object? id = _Undefined,
    String? connectorId,
    String? buildingId,
    String? label,
    String? fromGraphId,
    int? fromFloor,
    String? fromNodeId,
    String? toGraphId,
    int? toFloor,
    String? toNodeId,
    _iv43g6lk.EdgeType? type,
    double? seconds,
    bool? bidirectional,
    bool? active,
  }) {
    return FloorConnector(
      id: id is int? ? id : this.id,
      connectorId: connectorId ?? this.connectorId,
      buildingId: buildingId ?? this.buildingId,
      label: label ?? this.label,
      fromGraphId: fromGraphId ?? this.fromGraphId,
      fromFloor: fromFloor ?? this.fromFloor,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toGraphId: toGraphId ?? this.toGraphId,
      toFloor: toFloor ?? this.toFloor,
      toNodeId: toNodeId ?? this.toNodeId,
      type: type ?? this.type,
      seconds: seconds ?? this.seconds,
      bidirectional: bidirectional ?? this.bidirectional,
      active: active ?? this.active,
    );
  }
}

class FloorConnectorUpdateTable extends _is.UpdateTable<FloorConnectorTable> {
  FloorConnectorUpdateTable(super.table);

  _is.ColumnValue<String, String> connectorId(String value) => _is.ColumnValue(
    table.connectorId,
    value,
  );

  _is.ColumnValue<String, String> buildingId(String value) => _is.ColumnValue(
    table.buildingId,
    value,
  );

  _is.ColumnValue<String, String> label(String value) => _is.ColumnValue(
    table.label,
    value,
  );

  _is.ColumnValue<String, String> fromGraphId(String value) => _is.ColumnValue(
    table.fromGraphId,
    value,
  );

  _is.ColumnValue<int, int> fromFloor(int value) => _is.ColumnValue(
    table.fromFloor,
    value,
  );

  _is.ColumnValue<String, String> fromNodeId(String value) => _is.ColumnValue(
    table.fromNodeId,
    value,
  );

  _is.ColumnValue<String, String> toGraphId(String value) => _is.ColumnValue(
    table.toGraphId,
    value,
  );

  _is.ColumnValue<int, int> toFloor(int value) => _is.ColumnValue(
    table.toFloor,
    value,
  );

  _is.ColumnValue<String, String> toNodeId(String value) => _is.ColumnValue(
    table.toNodeId,
    value,
  );

  _is.ColumnValue<_iv43g6lk.EdgeType, _iv43g6lk.EdgeType> type(
    _iv43g6lk.EdgeType value,
  ) => _is.ColumnValue(
    table.type,
    value,
  );

  _is.ColumnValue<double, double> seconds(double value) => _is.ColumnValue(
    table.seconds,
    value,
  );

  _is.ColumnValue<bool, bool> bidirectional(bool value) => _is.ColumnValue(
    table.bidirectional,
    value,
  );

  _is.ColumnValue<bool, bool> active(bool value) => _is.ColumnValue(
    table.active,
    value,
  );
}

class FloorConnectorTable extends _is.Table<int?> {
  FloorConnectorTable({super.tableRelation})
    : super(tableName: 'floor_connector') {
    updateTable = FloorConnectorUpdateTable(this);
    connectorId = _is.ColumnString(
      'connectorId',
      this,
    );
    buildingId = _is.ColumnString(
      'buildingId',
      this,
    );
    label = _is.ColumnString(
      'label',
      this,
    );
    fromGraphId = _is.ColumnString(
      'fromGraphId',
      this,
    );
    fromFloor = _is.ColumnInt(
      'fromFloor',
      this,
    );
    fromNodeId = _is.ColumnString(
      'fromNodeId',
      this,
    );
    toGraphId = _is.ColumnString(
      'toGraphId',
      this,
    );
    toFloor = _is.ColumnInt(
      'toFloor',
      this,
    );
    toNodeId = _is.ColumnString(
      'toNodeId',
      this,
    );
    type = _is.ColumnEnum(
      'type',
      this,
      _is.EnumSerialization.byName,
    );
    seconds = _is.ColumnDouble(
      'seconds',
      this,
    );
    bidirectional = _is.ColumnBool(
      'bidirectional',
      this,
      hasDefault: true,
    );
    active = _is.ColumnBool(
      'active',
      this,
      hasDefault: true,
    );
  }

  late final FloorConnectorUpdateTable updateTable;

  late final _is.ColumnString connectorId;

  late final _is.ColumnString buildingId;

  late final _is.ColumnString label;

  late final _is.ColumnString fromGraphId;

  late final _is.ColumnInt fromFloor;

  late final _is.ColumnString fromNodeId;

  late final _is.ColumnString toGraphId;

  late final _is.ColumnInt toFloor;

  late final _is.ColumnString toNodeId;

  late final _is.ColumnEnum<_iv43g6lk.EdgeType> type;

  late final _is.ColumnDouble seconds;

  late final _is.ColumnBool bidirectional;

  late final _is.ColumnBool active;

  @override
  List<_is.Column> get columns => [
    id,
    connectorId,
    buildingId,
    label,
    fromGraphId,
    fromFloor,
    fromNodeId,
    toGraphId,
    toFloor,
    toNodeId,
    type,
    seconds,
    bidirectional,
    active,
  ];
}

class FloorConnectorInclude extends _is.IncludeObject {
  FloorConnectorInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => FloorConnector.t;
}

class FloorConnectorIncludeList extends _is.IncludeList {
  FloorConnectorIncludeList._({
    _is.WhereExpressionBuilder<FloorConnectorTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FloorConnector.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => FloorConnector.t;
}

class FloorConnectorRepository {
  const FloorConnectorRepository._();

  /// Returns a list of [FloorConnector]s matching the given query parameters.
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
  Future<List<FloorConnector>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FloorConnectorTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FloorConnectorTable>? orderBy,
    _is.OrderByListBuilder<FloorConnectorTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<FloorConnector>(
      where: where?.call(FloorConnector.t),
      orderBy: orderBy?.call(FloorConnector.t),
      orderByList: orderByList?.call(FloorConnector.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [FloorConnector]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `FloorConnector.t`.
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
  _ida.Stream<List<FloorConnector>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FloorConnectorTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FloorConnectorTable>? orderBy,
    _is.OrderByListBuilder<FloorConnectorTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<FloorConnector>(
      where: where?.call(FloorConnector.t),
      orderBy: orderBy?.call(FloorConnector.t),
      orderByList: orderByList?.call(FloorConnector.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [FloorConnector] matching the given query parameters.
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
  Future<FloorConnector?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FloorConnectorTable>? where,
    int? offset,
    _is.OrderByBuilder<FloorConnectorTable>? orderBy,
    _is.OrderByListBuilder<FloorConnectorTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<FloorConnector>(
      where: where?.call(FloorConnector.t),
      orderBy: orderBy?.call(FloorConnector.t),
      orderByList: orderByList?.call(FloorConnector.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [FloorConnector] by its [id] or null if no such row exists.
  Future<FloorConnector?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<FloorConnector>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [FloorConnector]s in the list and returns the inserted rows.
  ///
  /// The returned [FloorConnector]s will have their `id` fields set.
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
  Future<List<FloorConnector>> insert(
    _is.DatabaseSession session,
    List<FloorConnector> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<FloorConnector>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [FloorConnector] and returns the inserted row.
  ///
  /// The returned [FloorConnector] will have its `id` field set.
  Future<FloorConnector> insertRow(
    _is.DatabaseSession session,
    FloorConnector row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<FloorConnector>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [FloorConnector]s in the list and returns the resulting rows.
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
  /// The returned [FloorConnector]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FloorConnector>> upsert(
    _is.DatabaseSession session,
    List<FloorConnector> rows, {
    required _is.ColumnSelections<FloorConnectorTable> conflictColumns,
    _is.ColumnSelections<FloorConnectorTable>? updateColumns,
    _is.WhereExpressionBuilder<FloorConnectorTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<FloorConnector>(
      rows,
      conflictColumns: conflictColumns(FloorConnector.t),
      updateColumns: updateColumns?.call(FloorConnector.t),
      updateWhere: updateWhere?.call(FloorConnector.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [FloorConnector] and returns the resulting row.
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
  /// The returned [FloorConnector] will have its `id` field set.
  Future<FloorConnector?> upsertRow(
    _is.DatabaseSession session,
    FloorConnector row, {
    required _is.ColumnSelections<FloorConnectorTable> conflictColumns,
    _is.ColumnSelections<FloorConnectorTable>? updateColumns,
    _is.WhereExpressionBuilder<FloorConnectorTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<FloorConnector>(
      row,
      conflictColumns: conflictColumns(FloorConnector.t),
      updateColumns: updateColumns?.call(FloorConnector.t),
      updateWhere: updateWhere?.call(FloorConnector.t),
      transaction: transaction,
    );
  }

  /// Updates all [FloorConnector]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FloorConnector>> update(
    _is.DatabaseSession session,
    List<FloorConnector> rows, {
    _is.ColumnSelections<FloorConnectorTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<FloorConnector>(
      rows,
      columns: columns?.call(FloorConnector.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [FloorConnector]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FloorConnector> updateRow(
    _is.DatabaseSession session,
    FloorConnector row, {
    _is.ColumnSelections<FloorConnectorTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<FloorConnector>(
      row,
      columns: columns?.call(FloorConnector.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FloorConnector] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<FloorConnector?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<FloorConnectorUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<FloorConnector>(
      id,
      columnValues: columnValues(FloorConnector.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FloorConnector]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FloorConnector>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<FloorConnectorUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<FloorConnectorTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FloorConnectorTable>? orderBy,
    _is.OrderByListBuilder<FloorConnectorTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<FloorConnector>(
      columnValues: columnValues(FloorConnector.t.updateTable),
      where: where(FloorConnector.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FloorConnector.t),
      orderByList: orderByList?.call(FloorConnector.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [FloorConnector]s in the list and returns the deleted rows.
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
  Future<List<FloorConnector>> delete(
    _is.DatabaseSession session,
    List<FloorConnector> rows, {
    _is.OrderByBuilder<FloorConnectorTable>? orderBy,
    _is.OrderByListBuilder<FloorConnectorTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<FloorConnector>(
      rows,
      orderBy: orderBy?.call(FloorConnector.t),
      orderByList: orderByList?.call(FloorConnector.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [FloorConnector].
  Future<FloorConnector> deleteRow(
    _is.DatabaseSession session,
    FloorConnector row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FloorConnector>(
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
  Future<List<FloorConnector>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FloorConnectorTable> where,
    _is.OrderByBuilder<FloorConnectorTable>? orderBy,
    _is.OrderByListBuilder<FloorConnectorTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<FloorConnector>(
      where: where(FloorConnector.t),
      orderBy: orderBy?.call(FloorConnector.t),
      orderByList: orderByList?.call(FloorConnector.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FloorConnectorTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<FloorConnector>(
      where: where?.call(FloorConnector.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [FloorConnector] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FloorConnectorTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<FloorConnector>(
      where: where(FloorConnector.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
