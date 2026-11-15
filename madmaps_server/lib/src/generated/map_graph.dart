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
import 'map_entity_status.dart' as _itjn1vsu;

abstract class MapGraph
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  MapGraph._({
    this.id,
    required this.graphId,
    required this.buildingId,
    required this.name,
    required this.ownerId,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : status = status ?? _itjn1vsu.MapEntityStatus.active,
       version = version ?? 1,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory MapGraph({
    int? id,
    required String graphId,
    required int buildingId,
    required String name,
    required String ownerId,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _MapGraphImpl;

  factory MapGraph.fromJson(Map<String, dynamic> jsonSerialization) {
    return MapGraph(
      id: jsonSerialization['id'] as int?,
      graphId: jsonSerialization['graphId'] as String,
      buildingId: jsonSerialization['buildingId'] as int,
      name: jsonSerialization['name'] as String,
      ownerId: jsonSerialization['ownerId'] as String,
      status: jsonSerialization['status'] == null
          ? null
          : _itjn1vsu.MapEntityStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      version: jsonSerialization['version'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = MapGraphTable();

  static const db = MapGraphRepository._();

  @override
  int? id;

  String graphId;

  int buildingId;

  String name;

  String ownerId;

  _itjn1vsu.MapEntityStatus status;

  int version;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MapGraph]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MapGraph copyWith({
    int? id,
    String? graphId,
    int? buildingId,
    String? name,
    String? ownerId,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MapGraph',
      if (id != null) 'id': id,
      'graphId': graphId,
      'buildingId': buildingId,
      'name': name,
      'ownerId': ownerId,
      'status': status.toJson(),
      'version': version,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MapGraph',
      if (id != null) 'id': id,
      'graphId': graphId,
      'buildingId': buildingId,
      'name': name,
      'ownerId': ownerId,
      'status': status.toJson(),
      'version': version,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static MapGraphInclude include() {
    return MapGraphInclude._();
  }

  static MapGraphIncludeList includeList({
    _is.WhereExpressionBuilder<MapGraphTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MapGraphTable>? orderBy,
    _is.OrderByListBuilder<MapGraphTable>? orderByList,
    MapGraphInclude? include,
  }) {
    return MapGraphIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MapGraph.t),
      orderByList: orderByList?.call(MapGraph.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MapGraphImpl extends MapGraph {
  _MapGraphImpl({
    int? id,
    required String graphId,
    required int buildingId,
    required String name,
    required String ownerId,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         graphId: graphId,
         buildingId: buildingId,
         name: name,
         ownerId: ownerId,
         status: status,
         version: version,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [MapGraph]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MapGraph copyWith({
    Object? id = _Undefined,
    String? graphId,
    int? buildingId,
    String? name,
    String? ownerId,
    _itjn1vsu.MapEntityStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _is.$UndefinedDateTime(),
  }) {
    return MapGraph(
      id: id is int? ? id : this.id,
      graphId: graphId ?? this.graphId,
      buildingId: buildingId ?? this.buildingId,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is _is.UndefinedSentinel
          ? this.deletedAt
          : deletedAt,
    );
  }
}

class MapGraphUpdateTable extends _is.UpdateTable<MapGraphTable> {
  MapGraphUpdateTable(super.table);

  _is.ColumnValue<String, String> graphId(String value) => _is.ColumnValue(
    table.graphId,
    value,
  );

  _is.ColumnValue<int, int> buildingId(int value) => _is.ColumnValue(
    table.buildingId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> ownerId(String value) => _is.ColumnValue(
    table.ownerId,
    value,
  );

  _is.ColumnValue<_itjn1vsu.MapEntityStatus, _itjn1vsu.MapEntityStatus> status(
    _itjn1vsu.MapEntityStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<int, int> version(int value) => _is.ColumnValue(
    table.version,
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
}

class MapGraphTable extends _is.Table<int?> {
  MapGraphTable({super.tableRelation}) : super(tableName: 'map_graph') {
    updateTable = MapGraphUpdateTable(this);
    graphId = _is.ColumnString(
      'graph_id',
      this,
      fieldName: 'graphId',
    );
    buildingId = _is.ColumnInt(
      'building_id',
      this,
      fieldName: 'buildingId',
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    ownerId = _is.ColumnString(
      'owner_id',
      this,
      fieldName: 'ownerId',
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    version = _is.ColumnInt(
      'version',
      this,
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
    deletedAt = _is.ColumnDateTime(
      'deleted_at',
      this,
      fieldName: 'deletedAt',
    );
  }

  late final MapGraphUpdateTable updateTable;

  late final _is.ColumnString graphId;

  late final _is.ColumnInt buildingId;

  late final _is.ColumnString name;

  late final _is.ColumnString ownerId;

  late final _is.ColumnEnum<_itjn1vsu.MapEntityStatus> status;

  late final _is.ColumnInt version;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime deletedAt;

  @override
  List<_is.Column> get columns => [
    id,
    graphId,
    buildingId,
    name,
    ownerId,
    status,
    version,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class MapGraphInclude extends _is.IncludeObject {
  MapGraphInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => MapGraph.t;
}

class MapGraphIncludeList extends _is.IncludeList {
  MapGraphIncludeList._({
    _is.WhereExpressionBuilder<MapGraphTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MapGraph.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MapGraph.t;
}

class MapGraphRepository {
  const MapGraphRepository._();

  /// Returns a list of [MapGraph]s matching the given query parameters.
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
  Future<List<MapGraph>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MapGraphTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MapGraphTable>? orderBy,
    _is.OrderByListBuilder<MapGraphTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MapGraph>(
      where: where?.call(MapGraph.t),
      orderBy: orderBy?.call(MapGraph.t),
      orderByList: orderByList?.call(MapGraph.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [MapGraph]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `MapGraph.t`.
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
  _ida.Stream<List<MapGraph>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MapGraphTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MapGraphTable>? orderBy,
    _is.OrderByListBuilder<MapGraphTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<MapGraph>(
      where: where?.call(MapGraph.t),
      orderBy: orderBy?.call(MapGraph.t),
      orderByList: orderByList?.call(MapGraph.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [MapGraph] matching the given query parameters.
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
  Future<MapGraph?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MapGraphTable>? where,
    int? offset,
    _is.OrderByBuilder<MapGraphTable>? orderBy,
    _is.OrderByListBuilder<MapGraphTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MapGraph>(
      where: where?.call(MapGraph.t),
      orderBy: orderBy?.call(MapGraph.t),
      orderByList: orderByList?.call(MapGraph.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MapGraph] by its [id] or null if no such row exists.
  Future<MapGraph?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MapGraph>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MapGraph]s in the list and returns the inserted rows.
  ///
  /// The returned [MapGraph]s will have their `id` fields set.
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
  Future<List<MapGraph>> insert(
    _is.DatabaseSession session,
    List<MapGraph> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MapGraph>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MapGraph] and returns the inserted row.
  ///
  /// The returned [MapGraph] will have its `id` field set.
  Future<MapGraph> insertRow(
    _is.DatabaseSession session,
    MapGraph row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MapGraph>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MapGraph]s in the list and returns the resulting rows.
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
  /// The returned [MapGraph]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MapGraph>> upsert(
    _is.DatabaseSession session,
    List<MapGraph> rows, {
    required _is.ColumnSelections<MapGraphTable> conflictColumns,
    _is.ColumnSelections<MapGraphTable>? updateColumns,
    _is.WhereExpressionBuilder<MapGraphTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MapGraph>(
      rows,
      conflictColumns: conflictColumns(MapGraph.t),
      updateColumns: updateColumns?.call(MapGraph.t),
      updateWhere: updateWhere?.call(MapGraph.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MapGraph] and returns the resulting row.
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
  /// The returned [MapGraph] will have its `id` field set.
  Future<MapGraph?> upsertRow(
    _is.DatabaseSession session,
    MapGraph row, {
    required _is.ColumnSelections<MapGraphTable> conflictColumns,
    _is.ColumnSelections<MapGraphTable>? updateColumns,
    _is.WhereExpressionBuilder<MapGraphTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MapGraph>(
      row,
      conflictColumns: conflictColumns(MapGraph.t),
      updateColumns: updateColumns?.call(MapGraph.t),
      updateWhere: updateWhere?.call(MapGraph.t),
      transaction: transaction,
    );
  }

  /// Updates all [MapGraph]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MapGraph>> update(
    _is.DatabaseSession session,
    List<MapGraph> rows, {
    _is.ColumnSelections<MapGraphTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MapGraph>(
      rows,
      columns: columns?.call(MapGraph.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MapGraph]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MapGraph> updateRow(
    _is.DatabaseSession session,
    MapGraph row, {
    _is.ColumnSelections<MapGraphTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MapGraph>(
      row,
      columns: columns?.call(MapGraph.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MapGraph] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MapGraph?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MapGraphUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MapGraph>(
      id,
      columnValues: columnValues(MapGraph.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MapGraph]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MapGraph>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MapGraphUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MapGraphTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MapGraphTable>? orderBy,
    _is.OrderByListBuilder<MapGraphTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MapGraph>(
      columnValues: columnValues(MapGraph.t.updateTable),
      where: where(MapGraph.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MapGraph.t),
      orderByList: orderByList?.call(MapGraph.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MapGraph]s in the list and returns the deleted rows.
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
  Future<List<MapGraph>> delete(
    _is.DatabaseSession session,
    List<MapGraph> rows, {
    _is.OrderByBuilder<MapGraphTable>? orderBy,
    _is.OrderByListBuilder<MapGraphTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MapGraph>(
      rows,
      orderBy: orderBy?.call(MapGraph.t),
      orderByList: orderByList?.call(MapGraph.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MapGraph].
  Future<MapGraph> deleteRow(
    _is.DatabaseSession session,
    MapGraph row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MapGraph>(
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
  Future<List<MapGraph>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MapGraphTable> where,
    _is.OrderByBuilder<MapGraphTable>? orderBy,
    _is.OrderByListBuilder<MapGraphTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MapGraph>(
      where: where(MapGraph.t),
      orderBy: orderBy?.call(MapGraph.t),
      orderByList: orderByList?.call(MapGraph.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MapGraphTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MapGraph>(
      where: where?.call(MapGraph.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MapGraph] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MapGraphTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MapGraph>(
      where: where(MapGraph.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
