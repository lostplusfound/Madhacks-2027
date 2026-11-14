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
import 'kind.dart' as _iokugpqm;

abstract class Nodes implements _is.TableRow<int?>, _is.ProtocolSerialization {
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

  static final t = NodesTable();

  static const db = NodesRepository._();

  @override
  int? id;

  String nodeId;

  int floor;

  double x;

  double y;

  String? locationId;

  _iokugpqm.Kind kind;

  String status;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Nodes]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static NodesInclude include() {
    return NodesInclude._();
  }

  static NodesIncludeList includeList({
    _is.WhereExpressionBuilder<NodesTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<NodesTable>? orderBy,
    _is.OrderByListBuilder<NodesTable>? orderByList,
    NodesInclude? include,
  }) {
    return NodesIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Nodes.t),
      orderByList: orderByList?.call(Nodes.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class NodesUpdateTable extends _is.UpdateTable<NodesTable> {
  NodesUpdateTable(super.table);

  _is.ColumnValue<String, String> nodeId(String value) => _is.ColumnValue(
    table.nodeId,
    value,
  );

  _is.ColumnValue<int, int> floor(int value) => _is.ColumnValue(
    table.floor,
    value,
  );

  _is.ColumnValue<double, double> x(double value) => _is.ColumnValue(
    table.x,
    value,
  );

  _is.ColumnValue<double, double> y(double value) => _is.ColumnValue(
    table.y,
    value,
  );

  _is.ColumnValue<String, String> locationId(String? value) => _is.ColumnValue(
    table.locationId,
    value,
  );

  _is.ColumnValue<_iokugpqm.Kind, _iokugpqm.Kind> kind(_iokugpqm.Kind value) =>
      _is.ColumnValue(
        table.kind,
        value,
      );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );
}

class NodesTable extends _is.Table<int?> {
  NodesTable({super.tableRelation}) : super(tableName: 'nodes') {
    updateTable = NodesUpdateTable(this);
    nodeId = _is.ColumnString(
      'node_id',
      this,
      fieldName: 'nodeId',
    );
    floor = _is.ColumnInt(
      'floor',
      this,
    );
    x = _is.ColumnDouble(
      'x',
      this,
    );
    y = _is.ColumnDouble(
      'y',
      this,
    );
    locationId = _is.ColumnString(
      'location_id',
      this,
      fieldName: 'locationId',
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
  }

  late final NodesUpdateTable updateTable;

  late final _is.ColumnString nodeId;

  late final _is.ColumnInt floor;

  late final _is.ColumnDouble x;

  late final _is.ColumnDouble y;

  late final _is.ColumnString locationId;

  late final _is.ColumnEnum<_iokugpqm.Kind> kind;

  late final _is.ColumnString status;

  @override
  List<_is.Column> get columns => [
    id,
    nodeId,
    floor,
    x,
    y,
    locationId,
    kind,
    status,
  ];
}

class NodesInclude extends _is.IncludeObject {
  NodesInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Nodes.t;
}

class NodesIncludeList extends _is.IncludeList {
  NodesIncludeList._({
    _is.WhereExpressionBuilder<NodesTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Nodes.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Nodes.t;
}

class NodesRepository {
  const NodesRepository._();

  /// Returns a list of [Nodes]s matching the given query parameters.
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
  Future<List<Nodes>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<NodesTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<NodesTable>? orderBy,
    _is.OrderByListBuilder<NodesTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Nodes>(
      where: where?.call(Nodes.t),
      orderBy: orderBy?.call(Nodes.t),
      orderByList: orderByList?.call(Nodes.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Nodes]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Nodes.t`.
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
  _ida.Stream<List<Nodes>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<NodesTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<NodesTable>? orderBy,
    _is.OrderByListBuilder<NodesTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Nodes>(
      where: where?.call(Nodes.t),
      orderBy: orderBy?.call(Nodes.t),
      orderByList: orderByList?.call(Nodes.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Nodes] matching the given query parameters.
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
  Future<Nodes?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<NodesTable>? where,
    int? offset,
    _is.OrderByBuilder<NodesTable>? orderBy,
    _is.OrderByListBuilder<NodesTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Nodes>(
      where: where?.call(Nodes.t),
      orderBy: orderBy?.call(Nodes.t),
      orderByList: orderByList?.call(Nodes.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Nodes] by its [id] or null if no such row exists.
  Future<Nodes?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Nodes>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Nodes]s in the list and returns the inserted rows.
  ///
  /// The returned [Nodes]s will have their `id` fields set.
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
  Future<List<Nodes>> insert(
    _is.DatabaseSession session,
    List<Nodes> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Nodes>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Nodes] and returns the inserted row.
  ///
  /// The returned [Nodes] will have its `id` field set.
  Future<Nodes> insertRow(
    _is.DatabaseSession session,
    Nodes row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Nodes>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Nodes]s in the list and returns the resulting rows.
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
  /// The returned [Nodes]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Nodes>> upsert(
    _is.DatabaseSession session,
    List<Nodes> rows, {
    required _is.ColumnSelections<NodesTable> conflictColumns,
    _is.ColumnSelections<NodesTable>? updateColumns,
    _is.WhereExpressionBuilder<NodesTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Nodes>(
      rows,
      conflictColumns: conflictColumns(Nodes.t),
      updateColumns: updateColumns?.call(Nodes.t),
      updateWhere: updateWhere?.call(Nodes.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Nodes] and returns the resulting row.
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
  /// The returned [Nodes] will have its `id` field set.
  Future<Nodes?> upsertRow(
    _is.DatabaseSession session,
    Nodes row, {
    required _is.ColumnSelections<NodesTable> conflictColumns,
    _is.ColumnSelections<NodesTable>? updateColumns,
    _is.WhereExpressionBuilder<NodesTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Nodes>(
      row,
      conflictColumns: conflictColumns(Nodes.t),
      updateColumns: updateColumns?.call(Nodes.t),
      updateWhere: updateWhere?.call(Nodes.t),
      transaction: transaction,
    );
  }

  /// Updates all [Nodes]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Nodes>> update(
    _is.DatabaseSession session,
    List<Nodes> rows, {
    _is.ColumnSelections<NodesTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Nodes>(
      rows,
      columns: columns?.call(Nodes.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Nodes]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Nodes> updateRow(
    _is.DatabaseSession session,
    Nodes row, {
    _is.ColumnSelections<NodesTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Nodes>(
      row,
      columns: columns?.call(Nodes.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Nodes] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Nodes?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<NodesUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Nodes>(
      id,
      columnValues: columnValues(Nodes.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Nodes]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Nodes>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<NodesUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<NodesTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<NodesTable>? orderBy,
    _is.OrderByListBuilder<NodesTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Nodes>(
      columnValues: columnValues(Nodes.t.updateTable),
      where: where(Nodes.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Nodes.t),
      orderByList: orderByList?.call(Nodes.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Nodes]s in the list and returns the deleted rows.
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
  Future<List<Nodes>> delete(
    _is.DatabaseSession session,
    List<Nodes> rows, {
    _is.OrderByBuilder<NodesTable>? orderBy,
    _is.OrderByListBuilder<NodesTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Nodes>(
      rows,
      orderBy: orderBy?.call(Nodes.t),
      orderByList: orderByList?.call(Nodes.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Nodes].
  Future<Nodes> deleteRow(
    _is.DatabaseSession session,
    Nodes row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Nodes>(
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
  Future<List<Nodes>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<NodesTable> where,
    _is.OrderByBuilder<NodesTable>? orderBy,
    _is.OrderByListBuilder<NodesTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Nodes>(
      where: where(Nodes.t),
      orderBy: orderBy?.call(Nodes.t),
      orderByList: orderByList?.call(Nodes.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<NodesTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Nodes>(
      where: where?.call(Nodes.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Nodes] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<NodesTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Nodes>(
      where: where(Nodes.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
