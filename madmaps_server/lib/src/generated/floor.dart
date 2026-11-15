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

abstract class Floor implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Floor._({
    this.id,
    required this.floorId,
    required this.buildingId,
    required this.floorNumber,
    this.name,
    required this.width,
    required this.height,
    double? metersPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : metersPerUnit = metersPerUnit ?? 1.0,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Floor({
    int? id,
    required String floorId,
    required int buildingId,
    required int floorNumber,
    String? name,
    required double width,
    required double height,
    double? metersPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FloorImpl;

  factory Floor.fromJson(Map<String, dynamic> jsonSerialization) {
    return Floor(
      id: jsonSerialization['id'] as int?,
      floorId: jsonSerialization['floorId'] as String,
      buildingId: jsonSerialization['buildingId'] as int,
      floorNumber: jsonSerialization['floorNumber'] as int,
      name: jsonSerialization['name'] as String?,
      width: (jsonSerialization['width'] as num).toDouble(),
      height: (jsonSerialization['height'] as num).toDouble(),
      metersPerUnit: (jsonSerialization['metersPerUnit'] as num?)?.toDouble(),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = FloorTable();

  static const db = FloorRepository._();

  @override
  int? id;

  String floorId;

  int buildingId;

  int floorNumber;

  String? name;

  double width;

  double height;

  double metersPerUnit;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Floor]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Floor copyWith({
    int? id,
    String? floorId,
    int? buildingId,
    int? floorNumber,
    String? name,
    double? width,
    double? height,
    double? metersPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Floor',
      if (id != null) 'id': id,
      'floorId': floorId,
      'buildingId': buildingId,
      'floorNumber': floorNumber,
      if (name != null) 'name': name,
      'width': width,
      'height': height,
      'metersPerUnit': metersPerUnit,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Floor',
      if (id != null) 'id': id,
      'floorId': floorId,
      'buildingId': buildingId,
      'floorNumber': floorNumber,
      if (name != null) 'name': name,
      'width': width,
      'height': height,
      'metersPerUnit': metersPerUnit,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static FloorInclude include() {
    return FloorInclude._();
  }

  static FloorIncludeList includeList({
    _is.WhereExpressionBuilder<FloorTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FloorTable>? orderBy,
    _is.OrderByListBuilder<FloorTable>? orderByList,
    FloorInclude? include,
  }) {
    return FloorIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Floor.t),
      orderByList: orderByList?.call(Floor.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FloorImpl extends Floor {
  _FloorImpl({
    int? id,
    required String floorId,
    required int buildingId,
    required int floorNumber,
    String? name,
    required double width,
    required double height,
    double? metersPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         floorId: floorId,
         buildingId: buildingId,
         floorNumber: floorNumber,
         name: name,
         width: width,
         height: height,
         metersPerUnit: metersPerUnit,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Floor]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Floor copyWith({
    Object? id = _Undefined,
    String? floorId,
    int? buildingId,
    int? floorNumber,
    Object? name = _Undefined,
    double? width,
    double? height,
    double? metersPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Floor(
      id: id is int? ? id : this.id,
      floorId: floorId ?? this.floorId,
      buildingId: buildingId ?? this.buildingId,
      floorNumber: floorNumber ?? this.floorNumber,
      name: name is String? ? name : this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      metersPerUnit: metersPerUnit ?? this.metersPerUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FloorUpdateTable extends _is.UpdateTable<FloorTable> {
  FloorUpdateTable(super.table);

  _is.ColumnValue<String, String> floorId(String value) => _is.ColumnValue(
    table.floorId,
    value,
  );

  _is.ColumnValue<int, int> buildingId(int value) => _is.ColumnValue(
    table.buildingId,
    value,
  );

  _is.ColumnValue<int, int> floorNumber(int value) => _is.ColumnValue(
    table.floorNumber,
    value,
  );

  _is.ColumnValue<String, String> name(String? value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<double, double> width(double value) => _is.ColumnValue(
    table.width,
    value,
  );

  _is.ColumnValue<double, double> height(double value) => _is.ColumnValue(
    table.height,
    value,
  );

  _is.ColumnValue<double, double> metersPerUnit(double value) =>
      _is.ColumnValue(
        table.metersPerUnit,
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

class FloorTable extends _is.Table<int?> {
  FloorTable({super.tableRelation}) : super(tableName: 'floor') {
    updateTable = FloorUpdateTable(this);
    floorId = _is.ColumnString(
      'floor_id',
      this,
      fieldName: 'floorId',
    );
    buildingId = _is.ColumnInt(
      'building_id',
      this,
      fieldName: 'buildingId',
    );
    floorNumber = _is.ColumnInt(
      'floor_number',
      this,
      fieldName: 'floorNumber',
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    width = _is.ColumnDouble(
      'width',
      this,
    );
    height = _is.ColumnDouble(
      'height',
      this,
    );
    metersPerUnit = _is.ColumnDouble(
      'meters_per_unit',
      this,
      hasDefault: true,
      fieldName: 'metersPerUnit',
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

  late final FloorUpdateTable updateTable;

  late final _is.ColumnString floorId;

  late final _is.ColumnInt buildingId;

  late final _is.ColumnInt floorNumber;

  late final _is.ColumnString name;

  late final _is.ColumnDouble width;

  late final _is.ColumnDouble height;

  late final _is.ColumnDouble metersPerUnit;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    floorId,
    buildingId,
    floorNumber,
    name,
    width,
    height,
    metersPerUnit,
    createdAt,
    updatedAt,
  ];
}

class FloorInclude extends _is.IncludeObject {
  FloorInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Floor.t;
}

class FloorIncludeList extends _is.IncludeList {
  FloorIncludeList._({
    _is.WhereExpressionBuilder<FloorTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Floor.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Floor.t;
}

class FloorRepository {
  const FloorRepository._();

  /// Returns a list of [Floor]s matching the given query parameters.
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
  Future<List<Floor>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FloorTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FloorTable>? orderBy,
    _is.OrderByListBuilder<FloorTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Floor>(
      where: where?.call(Floor.t),
      orderBy: orderBy?.call(Floor.t),
      orderByList: orderByList?.call(Floor.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Floor]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Floor.t`.
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
  _ida.Stream<List<Floor>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FloorTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FloorTable>? orderBy,
    _is.OrderByListBuilder<FloorTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Floor>(
      where: where?.call(Floor.t),
      orderBy: orderBy?.call(Floor.t),
      orderByList: orderByList?.call(Floor.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Floor] matching the given query parameters.
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
  Future<Floor?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FloorTable>? where,
    int? offset,
    _is.OrderByBuilder<FloorTable>? orderBy,
    _is.OrderByListBuilder<FloorTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Floor>(
      where: where?.call(Floor.t),
      orderBy: orderBy?.call(Floor.t),
      orderByList: orderByList?.call(Floor.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Floor] by its [id] or null if no such row exists.
  Future<Floor?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Floor>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Floor]s in the list and returns the inserted rows.
  ///
  /// The returned [Floor]s will have their `id` fields set.
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
  Future<List<Floor>> insert(
    _is.DatabaseSession session,
    List<Floor> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Floor>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Floor] and returns the inserted row.
  ///
  /// The returned [Floor] will have its `id` field set.
  Future<Floor> insertRow(
    _is.DatabaseSession session,
    Floor row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Floor>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Floor]s in the list and returns the resulting rows.
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
  /// The returned [Floor]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Floor>> upsert(
    _is.DatabaseSession session,
    List<Floor> rows, {
    required _is.ColumnSelections<FloorTable> conflictColumns,
    _is.ColumnSelections<FloorTable>? updateColumns,
    _is.WhereExpressionBuilder<FloorTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Floor>(
      rows,
      conflictColumns: conflictColumns(Floor.t),
      updateColumns: updateColumns?.call(Floor.t),
      updateWhere: updateWhere?.call(Floor.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Floor] and returns the resulting row.
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
  /// The returned [Floor] will have its `id` field set.
  Future<Floor?> upsertRow(
    _is.DatabaseSession session,
    Floor row, {
    required _is.ColumnSelections<FloorTable> conflictColumns,
    _is.ColumnSelections<FloorTable>? updateColumns,
    _is.WhereExpressionBuilder<FloorTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Floor>(
      row,
      conflictColumns: conflictColumns(Floor.t),
      updateColumns: updateColumns?.call(Floor.t),
      updateWhere: updateWhere?.call(Floor.t),
      transaction: transaction,
    );
  }

  /// Updates all [Floor]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Floor>> update(
    _is.DatabaseSession session,
    List<Floor> rows, {
    _is.ColumnSelections<FloorTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Floor>(
      rows,
      columns: columns?.call(Floor.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Floor]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Floor> updateRow(
    _is.DatabaseSession session,
    Floor row, {
    _is.ColumnSelections<FloorTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Floor>(
      row,
      columns: columns?.call(Floor.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Floor] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Floor?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<FloorUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Floor>(
      id,
      columnValues: columnValues(Floor.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Floor]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Floor>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<FloorUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<FloorTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FloorTable>? orderBy,
    _is.OrderByListBuilder<FloorTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Floor>(
      columnValues: columnValues(Floor.t.updateTable),
      where: where(Floor.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Floor.t),
      orderByList: orderByList?.call(Floor.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Floor]s in the list and returns the deleted rows.
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
  Future<List<Floor>> delete(
    _is.DatabaseSession session,
    List<Floor> rows, {
    _is.OrderByBuilder<FloorTable>? orderBy,
    _is.OrderByListBuilder<FloorTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Floor>(
      rows,
      orderBy: orderBy?.call(Floor.t),
      orderByList: orderByList?.call(Floor.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Floor].
  Future<Floor> deleteRow(
    _is.DatabaseSession session,
    Floor row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Floor>(
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
  Future<List<Floor>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FloorTable> where,
    _is.OrderByBuilder<FloorTable>? orderBy,
    _is.OrderByListBuilder<FloorTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Floor>(
      where: where(Floor.t),
      orderBy: orderBy?.call(Floor.t),
      orderByList: orderByList?.call(Floor.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FloorTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Floor>(
      where: where?.call(Floor.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Floor] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FloorTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Floor>(
      where: where(Floor.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
