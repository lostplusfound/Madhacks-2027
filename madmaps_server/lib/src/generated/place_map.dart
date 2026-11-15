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

abstract class PlaceMap
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PlaceMap._({
    this.id,
    required this.mapId,
    required this.buildingName,
    required this.floorLabel,
    required this.mapJson,
    int? version,
    DateTime? updatedAt,
  }) : version = version ?? 1,
       updatedAt = updatedAt ?? DateTime.now();

  factory PlaceMap({
    int? id,
    required String mapId,
    required String buildingName,
    required String floorLabel,
    required String mapJson,
    int? version,
    DateTime? updatedAt,
  }) = _PlaceMapImpl;

  factory PlaceMap.fromJson(Map<String, dynamic> jsonSerialization) {
    return PlaceMap(
      id: jsonSerialization['id'] as int?,
      mapId: jsonSerialization['mapId'] as String,
      buildingName: jsonSerialization['buildingName'] as String,
      floorLabel: jsonSerialization['floorLabel'] as String,
      mapJson: jsonSerialization['mapJson'] as String,
      version: jsonSerialization['version'] as int?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = PlaceMapTable();

  static const db = PlaceMapRepository._();

  @override
  int? id;

  String mapId;

  String buildingName;

  String floorLabel;

  String mapJson;

  int version;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PlaceMap]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PlaceMap copyWith({
    int? id,
    String? mapId,
    String? buildingName,
    String? floorLabel,
    String? mapJson,
    int? version,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PlaceMap',
      if (id != null) 'id': id,
      'mapId': mapId,
      'buildingName': buildingName,
      'floorLabel': floorLabel,
      'mapJson': mapJson,
      'version': version,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PlaceMap',
      if (id != null) 'id': id,
      'mapId': mapId,
      'buildingName': buildingName,
      'floorLabel': floorLabel,
      'mapJson': mapJson,
      'version': version,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static PlaceMapInclude include() {
    return PlaceMapInclude._();
  }

  static PlaceMapIncludeList includeList({
    _is.WhereExpressionBuilder<PlaceMapTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PlaceMapTable>? orderBy,
    _is.OrderByListBuilder<PlaceMapTable>? orderByList,
    PlaceMapInclude? include,
  }) {
    return PlaceMapIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PlaceMap.t),
      orderByList: orderByList?.call(PlaceMap.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PlaceMapImpl extends PlaceMap {
  _PlaceMapImpl({
    int? id,
    required String mapId,
    required String buildingName,
    required String floorLabel,
    required String mapJson,
    int? version,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         mapId: mapId,
         buildingName: buildingName,
         floorLabel: floorLabel,
         mapJson: mapJson,
         version: version,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [PlaceMap]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PlaceMap copyWith({
    Object? id = _Undefined,
    String? mapId,
    String? buildingName,
    String? floorLabel,
    String? mapJson,
    int? version,
    DateTime? updatedAt,
  }) {
    return PlaceMap(
      id: id is int? ? id : this.id,
      mapId: mapId ?? this.mapId,
      buildingName: buildingName ?? this.buildingName,
      floorLabel: floorLabel ?? this.floorLabel,
      mapJson: mapJson ?? this.mapJson,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PlaceMapUpdateTable extends _is.UpdateTable<PlaceMapTable> {
  PlaceMapUpdateTable(super.table);

  _is.ColumnValue<String, String> mapId(String value) => _is.ColumnValue(
    table.mapId,
    value,
  );

  _is.ColumnValue<String, String> buildingName(String value) => _is.ColumnValue(
    table.buildingName,
    value,
  );

  _is.ColumnValue<String, String> floorLabel(String value) => _is.ColumnValue(
    table.floorLabel,
    value,
  );

  _is.ColumnValue<String, String> mapJson(String value) => _is.ColumnValue(
    table.mapJson,
    value,
  );

  _is.ColumnValue<int, int> version(int value) => _is.ColumnValue(
    table.version,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class PlaceMapTable extends _is.Table<int?> {
  PlaceMapTable({super.tableRelation}) : super(tableName: 'place_map') {
    updateTable = PlaceMapUpdateTable(this);
    mapId = _is.ColumnString(
      'map_id',
      this,
      fieldName: 'mapId',
    );
    buildingName = _is.ColumnString(
      'building_name',
      this,
      fieldName: 'buildingName',
    );
    floorLabel = _is.ColumnString(
      'floor_label',
      this,
      fieldName: 'floorLabel',
    );
    mapJson = _is.ColumnString(
      'map_json',
      this,
      fieldName: 'mapJson',
    );
    version = _is.ColumnInt(
      'version',
      this,
      hasDefault: true,
    );
    updatedAt = _is.ColumnDateTime(
      'updated_at',
      this,
      hasDefault: true,
      fieldName: 'updatedAt',
    );
  }

  late final PlaceMapUpdateTable updateTable;

  late final _is.ColumnString mapId;

  late final _is.ColumnString buildingName;

  late final _is.ColumnString floorLabel;

  late final _is.ColumnString mapJson;

  late final _is.ColumnInt version;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    mapId,
    buildingName,
    floorLabel,
    mapJson,
    version,
    updatedAt,
  ];
}

class PlaceMapInclude extends _is.IncludeObject {
  PlaceMapInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PlaceMap.t;
}

class PlaceMapIncludeList extends _is.IncludeList {
  PlaceMapIncludeList._({
    _is.WhereExpressionBuilder<PlaceMapTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PlaceMap.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PlaceMap.t;
}

class PlaceMapRepository {
  const PlaceMapRepository._();

  /// Returns a list of [PlaceMap]s matching the given query parameters.
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
  Future<List<PlaceMap>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PlaceMapTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PlaceMapTable>? orderBy,
    _is.OrderByListBuilder<PlaceMapTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PlaceMap>(
      where: where?.call(PlaceMap.t),
      orderBy: orderBy?.call(PlaceMap.t),
      orderByList: orderByList?.call(PlaceMap.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [PlaceMap]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `PlaceMap.t`.
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
  _ida.Stream<List<PlaceMap>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PlaceMapTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PlaceMapTable>? orderBy,
    _is.OrderByListBuilder<PlaceMapTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<PlaceMap>(
      where: where?.call(PlaceMap.t),
      orderBy: orderBy?.call(PlaceMap.t),
      orderByList: orderByList?.call(PlaceMap.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [PlaceMap] matching the given query parameters.
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
  Future<PlaceMap?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PlaceMapTable>? where,
    int? offset,
    _is.OrderByBuilder<PlaceMapTable>? orderBy,
    _is.OrderByListBuilder<PlaceMapTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PlaceMap>(
      where: where?.call(PlaceMap.t),
      orderBy: orderBy?.call(PlaceMap.t),
      orderByList: orderByList?.call(PlaceMap.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PlaceMap] by its [id] or null if no such row exists.
  Future<PlaceMap?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PlaceMap>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PlaceMap]s in the list and returns the inserted rows.
  ///
  /// The returned [PlaceMap]s will have their `id` fields set.
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
  Future<List<PlaceMap>> insert(
    _is.DatabaseSession session,
    List<PlaceMap> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PlaceMap>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PlaceMap] and returns the inserted row.
  ///
  /// The returned [PlaceMap] will have its `id` field set.
  Future<PlaceMap> insertRow(
    _is.DatabaseSession session,
    PlaceMap row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PlaceMap>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PlaceMap]s in the list and returns the resulting rows.
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
  /// The returned [PlaceMap]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PlaceMap>> upsert(
    _is.DatabaseSession session,
    List<PlaceMap> rows, {
    required _is.ColumnSelections<PlaceMapTable> conflictColumns,
    _is.ColumnSelections<PlaceMapTable>? updateColumns,
    _is.WhereExpressionBuilder<PlaceMapTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PlaceMap>(
      rows,
      conflictColumns: conflictColumns(PlaceMap.t),
      updateColumns: updateColumns?.call(PlaceMap.t),
      updateWhere: updateWhere?.call(PlaceMap.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PlaceMap] and returns the resulting row.
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
  /// The returned [PlaceMap] will have its `id` field set.
  Future<PlaceMap?> upsertRow(
    _is.DatabaseSession session,
    PlaceMap row, {
    required _is.ColumnSelections<PlaceMapTable> conflictColumns,
    _is.ColumnSelections<PlaceMapTable>? updateColumns,
    _is.WhereExpressionBuilder<PlaceMapTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PlaceMap>(
      row,
      conflictColumns: conflictColumns(PlaceMap.t),
      updateColumns: updateColumns?.call(PlaceMap.t),
      updateWhere: updateWhere?.call(PlaceMap.t),
      transaction: transaction,
    );
  }

  /// Updates all [PlaceMap]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PlaceMap>> update(
    _is.DatabaseSession session,
    List<PlaceMap> rows, {
    _is.ColumnSelections<PlaceMapTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PlaceMap>(
      rows,
      columns: columns?.call(PlaceMap.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PlaceMap]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PlaceMap> updateRow(
    _is.DatabaseSession session,
    PlaceMap row, {
    _is.ColumnSelections<PlaceMapTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PlaceMap>(
      row,
      columns: columns?.call(PlaceMap.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PlaceMap] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PlaceMap?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PlaceMapUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PlaceMap>(
      id,
      columnValues: columnValues(PlaceMap.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PlaceMap]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PlaceMap>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PlaceMapUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PlaceMapTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PlaceMapTable>? orderBy,
    _is.OrderByListBuilder<PlaceMapTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PlaceMap>(
      columnValues: columnValues(PlaceMap.t.updateTable),
      where: where(PlaceMap.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PlaceMap.t),
      orderByList: orderByList?.call(PlaceMap.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PlaceMap]s in the list and returns the deleted rows.
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
  Future<List<PlaceMap>> delete(
    _is.DatabaseSession session,
    List<PlaceMap> rows, {
    _is.OrderByBuilder<PlaceMapTable>? orderBy,
    _is.OrderByListBuilder<PlaceMapTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PlaceMap>(
      rows,
      orderBy: orderBy?.call(PlaceMap.t),
      orderByList: orderByList?.call(PlaceMap.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PlaceMap].
  Future<PlaceMap> deleteRow(
    _is.DatabaseSession session,
    PlaceMap row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PlaceMap>(
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
  Future<List<PlaceMap>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PlaceMapTable> where,
    _is.OrderByBuilder<PlaceMapTable>? orderBy,
    _is.OrderByListBuilder<PlaceMapTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PlaceMap>(
      where: where(PlaceMap.t),
      orderBy: orderBy?.call(PlaceMap.t),
      orderByList: orderByList?.call(PlaceMap.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PlaceMapTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PlaceMap>(
      where: where?.call(PlaceMap.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PlaceMap] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PlaceMapTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PlaceMap>(
      where: where(PlaceMap.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
