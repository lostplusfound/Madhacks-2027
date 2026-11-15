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
import 'map_entity_status.dart' as _itjn1vsu;

abstract class Edge implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Edge._({
    this.id,
    this.edgeId,
    this.graphId,
    required this.fromNodeId,
    required this.toNodeId,
    _iv43g6lk.EdgeType? type,
    required this.costPx,
    required this.bidirectional,
    _itjn1vsu.MapEntityStatus? status,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    int? version,
  }) : type = type ?? _iv43g6lk.EdgeType.walk,
       status = status ?? _itjn1vsu.MapEntityStatus.active,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       version = version ?? 1;

  factory Edge({
    int? id,
    String? edgeId,
    int? graphId,
    required String fromNodeId,
    required String toNodeId,
    _iv43g6lk.EdgeType? type,
    required double costPx,
    required bool bidirectional,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) = _EdgeImpl;

  factory Edge.fromJson(Map<String, dynamic> jsonSerialization) {
    return Edge(
      id: jsonSerialization['id'] as int?,
      edgeId: jsonSerialization['edgeId'] as String?,
      graphId: jsonSerialization['graphId'] as int?,
      fromNodeId: jsonSerialization['fromNodeId'] as String,
      toNodeId: jsonSerialization['toNodeId'] as String,
      type: jsonSerialization['type'] == null
          ? null
          : _iv43g6lk.EdgeType.fromJson((jsonSerialization['type'] as String)),
      costPx: (jsonSerialization['costPx'] as num).toDouble(),
      bidirectional: _is.BoolJsonExtension.fromJson(
        jsonSerialization['bidirectional'],
      ),
      status: jsonSerialization['status'] == null
          ? null
          : _itjn1vsu.MapEntityStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      createdBy: jsonSerialization['createdBy'] as String?,
      updatedBy: jsonSerialization['updatedBy'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      version: jsonSerialization['version'] as int?,
    );
  }

  static final t = EdgeTable();

  static const db = EdgeRepository._();

  @override
  int? id;

  String? edgeId;

  int? graphId;

  String fromNodeId;

  String toNodeId;

  _iv43g6lk.EdgeType type;

  double costPx;

  bool bidirectional;

  _itjn1vsu.MapEntityStatus status;

  String? createdBy;

  String? updatedBy;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  int version;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Edge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Edge copyWith({
    int? id,
    String? edgeId,
    int? graphId,
    String? fromNodeId,
    String? toNodeId,
    _iv43g6lk.EdgeType? type,
    double? costPx,
    bool? bidirectional,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _is.$UndefinedDateTime(),
    int? version,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Edge',
      if (id != null) 'id': id,
      if (edgeId != null) 'edgeId': edgeId,
      if (graphId != null) 'graphId': graphId,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'type': type.toJson(),
      'costPx': costPx,
      'bidirectional': bidirectional,
      'status': status.toJson(),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      'version': version,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Edge',
      if (id != null) 'id': id,
      if (edgeId != null) 'edgeId': edgeId,
      if (graphId != null) 'graphId': graphId,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'type': type.toJson(),
      'costPx': costPx,
      'bidirectional': bidirectional,
      'status': status.toJson(),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      'version': version,
    };
  }

  static EdgeInclude include() {
    return EdgeInclude._();
  }

  static EdgeIncludeList includeList({
    _is.WhereExpressionBuilder<EdgeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EdgeTable>? orderBy,
    _is.OrderByListBuilder<EdgeTable>? orderByList,
    EdgeInclude? include,
  }) {
    return EdgeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Edge.t),
      orderByList: orderByList?.call(Edge.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EdgeImpl extends Edge {
  _EdgeImpl({
    int? id,
    String? edgeId,
    int? graphId,
    required String fromNodeId,
    required String toNodeId,
    _iv43g6lk.EdgeType? type,
    required double costPx,
    required bool bidirectional,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) : super._(
         id: id,
         edgeId: edgeId,
         graphId: graphId,
         fromNodeId: fromNodeId,
         toNodeId: toNodeId,
         type: type,
         costPx: costPx,
         bidirectional: bidirectional,
         status: status,
         createdBy: createdBy,
         updatedBy: updatedBy,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
         version: version,
       );

  /// Returns a shallow copy of this [Edge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Edge copyWith({
    Object? id = _Undefined,
    Object? edgeId = _Undefined,
    Object? graphId = _Undefined,
    String? fromNodeId,
    String? toNodeId,
    _iv43g6lk.EdgeType? type,
    double? costPx,
    bool? bidirectional,
    _itjn1vsu.MapEntityStatus? status,
    Object? createdBy = _Undefined,
    Object? updatedBy = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _is.$UndefinedDateTime(),
    int? version,
  }) {
    return Edge(
      id: id is int? ? id : this.id,
      edgeId: edgeId is String? ? edgeId : this.edgeId,
      graphId: graphId is int? ? graphId : this.graphId,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      type: type ?? this.type,
      costPx: costPx ?? this.costPx,
      bidirectional: bidirectional ?? this.bidirectional,
      status: status ?? this.status,
      createdBy: createdBy is String? ? createdBy : this.createdBy,
      updatedBy: updatedBy is String? ? updatedBy : this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is _is.UndefinedSentinel
          ? this.deletedAt
          : deletedAt,
      version: version ?? this.version,
    );
  }
}

class EdgeUpdateTable extends _is.UpdateTable<EdgeTable> {
  EdgeUpdateTable(super.table);

  _is.ColumnValue<String, String> edgeId(String? value) => _is.ColumnValue(
    table.edgeId,
    value,
  );

  _is.ColumnValue<int, int> graphId(int? value) => _is.ColumnValue(
    table.graphId,
    value,
  );

  _is.ColumnValue<String, String> fromNodeId(String value) => _is.ColumnValue(
    table.fromNodeId,
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

  _is.ColumnValue<double, double> costPx(double value) => _is.ColumnValue(
    table.costPx,
    value,
  );

  _is.ColumnValue<bool, bool> bidirectional(bool value) => _is.ColumnValue(
    table.bidirectional,
    value,
  );

  _is.ColumnValue<_itjn1vsu.MapEntityStatus, _itjn1vsu.MapEntityStatus> status(
    _itjn1vsu.MapEntityStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> createdBy(String? value) => _is.ColumnValue(
    table.createdBy,
    value,
  );

  _is.ColumnValue<String, String> updatedBy(String? value) => _is.ColumnValue(
    table.updatedBy,
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

  _is.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _is.ColumnValue(
        table.deletedAt,
        value,
      );

  _is.ColumnValue<int, int> version(int value) => _is.ColumnValue(
    table.version,
    value,
  );
}

class EdgeTable extends _is.Table<int?> {
  EdgeTable({super.tableRelation}) : super(tableName: 'edge') {
    updateTable = EdgeUpdateTable(this);
    edgeId = _is.ColumnString(
      'edge_id',
      this,
      fieldName: 'edgeId',
    );
    graphId = _is.ColumnInt(
      'graph_id',
      this,
      fieldName: 'graphId',
    );
    fromNodeId = _is.ColumnString(
      'from_node_id',
      this,
      fieldName: 'fromNodeId',
    );
    toNodeId = _is.ColumnString(
      'to_node_id',
      this,
      fieldName: 'toNodeId',
    );
    type = _is.ColumnEnum(
      'type',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    costPx = _is.ColumnDouble(
      'cost_px',
      this,
      fieldName: 'costPx',
    );
    bidirectional = _is.ColumnBool(
      'bidirectional',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    createdBy = _is.ColumnString(
      'created_by',
      this,
      fieldName: 'createdBy',
    );
    updatedBy = _is.ColumnString(
      'updated_by',
      this,
      fieldName: 'updatedBy',
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
    deletedAt = _is.ColumnDateTime(
      'deleted_at',
      this,
      fieldName: 'deletedAt',
    );
    version = _is.ColumnInt(
      'version',
      this,
      hasDefault: true,
    );
  }

  late final EdgeUpdateTable updateTable;

  late final _is.ColumnString edgeId;

  late final _is.ColumnInt graphId;

  late final _is.ColumnString fromNodeId;

  late final _is.ColumnString toNodeId;

  late final _is.ColumnEnum<_iv43g6lk.EdgeType> type;

  late final _is.ColumnDouble costPx;

  late final _is.ColumnBool bidirectional;

  late final _is.ColumnEnum<_itjn1vsu.MapEntityStatus> status;

  late final _is.ColumnString createdBy;

  late final _is.ColumnString updatedBy;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime deletedAt;

  late final _is.ColumnInt version;

  @override
  List<_is.Column> get columns => [
    id,
    edgeId,
    graphId,
    fromNodeId,
    toNodeId,
    type,
    costPx,
    bidirectional,
    status,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
    deletedAt,
    version,
  ];
}

class EdgeInclude extends _is.IncludeObject {
  EdgeInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Edge.t;
}

class EdgeIncludeList extends _is.IncludeList {
  EdgeIncludeList._({
    _is.WhereExpressionBuilder<EdgeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Edge.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Edge.t;
}

class EdgeRepository {
  const EdgeRepository._();

  /// Returns a list of [Edge]s matching the given query parameters.
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
  Future<List<Edge>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EdgeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EdgeTable>? orderBy,
    _is.OrderByListBuilder<EdgeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Edge>(
      where: where?.call(Edge.t),
      orderBy: orderBy?.call(Edge.t),
      orderByList: orderByList?.call(Edge.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Edge]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Edge.t`.
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
  _ida.Stream<List<Edge>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EdgeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EdgeTable>? orderBy,
    _is.OrderByListBuilder<EdgeTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Edge>(
      where: where?.call(Edge.t),
      orderBy: orderBy?.call(Edge.t),
      orderByList: orderByList?.call(Edge.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Edge] matching the given query parameters.
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
  Future<Edge?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EdgeTable>? where,
    int? offset,
    _is.OrderByBuilder<EdgeTable>? orderBy,
    _is.OrderByListBuilder<EdgeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Edge>(
      where: where?.call(Edge.t),
      orderBy: orderBy?.call(Edge.t),
      orderByList: orderByList?.call(Edge.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Edge] by its [id] or null if no such row exists.
  Future<Edge?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Edge>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Edge]s in the list and returns the inserted rows.
  ///
  /// The returned [Edge]s will have their `id` fields set.
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
  Future<List<Edge>> insert(
    _is.DatabaseSession session,
    List<Edge> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Edge>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Edge] and returns the inserted row.
  ///
  /// The returned [Edge] will have its `id` field set.
  Future<Edge> insertRow(
    _is.DatabaseSession session,
    Edge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Edge>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Edge]s in the list and returns the resulting rows.
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
  /// The returned [Edge]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Edge>> upsert(
    _is.DatabaseSession session,
    List<Edge> rows, {
    required _is.ColumnSelections<EdgeTable> conflictColumns,
    _is.ColumnSelections<EdgeTable>? updateColumns,
    _is.WhereExpressionBuilder<EdgeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Edge>(
      rows,
      conflictColumns: conflictColumns(Edge.t),
      updateColumns: updateColumns?.call(Edge.t),
      updateWhere: updateWhere?.call(Edge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Edge] and returns the resulting row.
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
  /// The returned [Edge] will have its `id` field set.
  Future<Edge?> upsertRow(
    _is.DatabaseSession session,
    Edge row, {
    required _is.ColumnSelections<EdgeTable> conflictColumns,
    _is.ColumnSelections<EdgeTable>? updateColumns,
    _is.WhereExpressionBuilder<EdgeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Edge>(
      row,
      conflictColumns: conflictColumns(Edge.t),
      updateColumns: updateColumns?.call(Edge.t),
      updateWhere: updateWhere?.call(Edge.t),
      transaction: transaction,
    );
  }

  /// Updates all [Edge]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Edge>> update(
    _is.DatabaseSession session,
    List<Edge> rows, {
    _is.ColumnSelections<EdgeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Edge>(
      rows,
      columns: columns?.call(Edge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Edge]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Edge> updateRow(
    _is.DatabaseSession session,
    Edge row, {
    _is.ColumnSelections<EdgeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Edge>(
      row,
      columns: columns?.call(Edge.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Edge] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Edge?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<EdgeUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Edge>(
      id,
      columnValues: columnValues(Edge.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Edge]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Edge>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<EdgeUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<EdgeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EdgeTable>? orderBy,
    _is.OrderByListBuilder<EdgeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Edge>(
      columnValues: columnValues(Edge.t.updateTable),
      where: where(Edge.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Edge.t),
      orderByList: orderByList?.call(Edge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Edge]s in the list and returns the deleted rows.
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
  Future<List<Edge>> delete(
    _is.DatabaseSession session,
    List<Edge> rows, {
    _is.OrderByBuilder<EdgeTable>? orderBy,
    _is.OrderByListBuilder<EdgeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Edge>(
      rows,
      orderBy: orderBy?.call(Edge.t),
      orderByList: orderByList?.call(Edge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Edge].
  Future<Edge> deleteRow(
    _is.DatabaseSession session,
    Edge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Edge>(
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
  Future<List<Edge>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EdgeTable> where,
    _is.OrderByBuilder<EdgeTable>? orderBy,
    _is.OrderByListBuilder<EdgeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Edge>(
      where: where(Edge.t),
      orderBy: orderBy?.call(Edge.t),
      orderByList: orderByList?.call(Edge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EdgeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Edge>(
      where: where?.call(Edge.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Edge] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EdgeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Edge>(
      where: where(Edge.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
