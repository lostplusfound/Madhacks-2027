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
import 'location_category.dart' as _ipivyxsl;
import 'map_entity_status.dart' as _itjn1vsu;

abstract class Locations
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Locations._({
    this.id,
    required this.locationId,
    this.graphId,
    this.floorId,
    required this.floor,
    this.roomNumber,
    this.name,
    _ipivyxsl.LocationCategory? category,
    this.aliases,
    this.routeNodeId,
    this.reviewNote,
    _itjn1vsu.MapEntityStatus? status,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    int? version,
  }) : category = category ?? _ipivyxsl.LocationCategory.other,
       status = status ?? _itjn1vsu.MapEntityStatus.active,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       version = version ?? 1;

  factory Locations({
    int? id,
    required String locationId,
    int? graphId,
    int? floorId,
    required int floor,
    String? roomNumber,
    String? name,
    _ipivyxsl.LocationCategory? category,
    String? aliases,
    String? routeNodeId,
    String? reviewNote,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) = _LocationsImpl;

  factory Locations.fromJson(Map<String, dynamic> jsonSerialization) {
    return Locations(
      id: jsonSerialization['id'] as int?,
      locationId: jsonSerialization['locationId'] as String,
      graphId: jsonSerialization['graphId'] as int?,
      floorId: jsonSerialization['floorId'] as int?,
      floor: jsonSerialization['floor'] as int,
      roomNumber: jsonSerialization['roomNumber'] as String?,
      name: jsonSerialization['name'] as String?,
      category: jsonSerialization['category'] == null
          ? null
          : _ipivyxsl.LocationCategory.fromJson(
              (jsonSerialization['category'] as String),
            ),
      aliases: jsonSerialization['aliases'] as String?,
      routeNodeId: jsonSerialization['routeNodeId'] as String?,
      reviewNote: jsonSerialization['reviewNote'] as String?,
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

  static final t = LocationsTable();

  static const db = LocationsRepository._();

  @override
  int? id;

  String locationId;

  int? graphId;

  int? floorId;

  int floor;

  String? roomNumber;

  String? name;

  _ipivyxsl.LocationCategory? category;

  String? aliases;

  String? routeNodeId;

  String? reviewNote;

  _itjn1vsu.MapEntityStatus status;

  String? createdBy;

  String? updatedBy;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  int version;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Locations]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Locations copyWith({
    int? id,
    String? locationId,
    int? graphId,
    int? floorId,
    int? floor,
    String? roomNumber,
    String? name,
    _ipivyxsl.LocationCategory? category,
    String? aliases,
    String? routeNodeId,
    String? reviewNote,
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
      '__className__': 'Locations',
      if (id != null) 'id': id,
      'locationId': locationId,
      if (graphId != null) 'graphId': graphId,
      if (floorId != null) 'floorId': floorId,
      'floor': floor,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (name != null) 'name': name,
      if (category != null) 'category': category?.toJson(),
      if (aliases != null) 'aliases': aliases,
      if (routeNodeId != null) 'routeNodeId': routeNodeId,
      if (reviewNote != null) 'reviewNote': reviewNote,
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
      '__className__': 'Locations',
      if (id != null) 'id': id,
      'locationId': locationId,
      if (graphId != null) 'graphId': graphId,
      if (floorId != null) 'floorId': floorId,
      'floor': floor,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (name != null) 'name': name,
      if (category != null) 'category': category?.toJson(),
      if (aliases != null) 'aliases': aliases,
      if (routeNodeId != null) 'routeNodeId': routeNodeId,
      if (reviewNote != null) 'reviewNote': reviewNote,
      'status': status.toJson(),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      'version': version,
    };
  }

  static LocationsInclude include() {
    return LocationsInclude._();
  }

  static LocationsIncludeList includeList({
    _is.WhereExpressionBuilder<LocationsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LocationsTable>? orderBy,
    _is.OrderByListBuilder<LocationsTable>? orderByList,
    LocationsInclude? include,
  }) {
    return LocationsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Locations.t),
      orderByList: orderByList?.call(Locations.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LocationsImpl extends Locations {
  _LocationsImpl({
    int? id,
    required String locationId,
    int? graphId,
    int? floorId,
    required int floor,
    String? roomNumber,
    String? name,
    _ipivyxsl.LocationCategory? category,
    String? aliases,
    String? routeNodeId,
    String? reviewNote,
    _itjn1vsu.MapEntityStatus? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) : super._(
         id: id,
         locationId: locationId,
         graphId: graphId,
         floorId: floorId,
         floor: floor,
         roomNumber: roomNumber,
         name: name,
         category: category,
         aliases: aliases,
         routeNodeId: routeNodeId,
         reviewNote: reviewNote,
         status: status,
         createdBy: createdBy,
         updatedBy: updatedBy,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
         version: version,
       );

  /// Returns a shallow copy of this [Locations]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Locations copyWith({
    Object? id = _Undefined,
    String? locationId,
    Object? graphId = _Undefined,
    Object? floorId = _Undefined,
    int? floor,
    Object? roomNumber = _Undefined,
    Object? name = _Undefined,
    Object? category = _Undefined,
    Object? aliases = _Undefined,
    Object? routeNodeId = _Undefined,
    Object? reviewNote = _Undefined,
    _itjn1vsu.MapEntityStatus? status,
    Object? createdBy = _Undefined,
    Object? updatedBy = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt = const _is.$UndefinedDateTime(),
    int? version,
  }) {
    return Locations(
      id: id is int? ? id : this.id,
      locationId: locationId ?? this.locationId,
      graphId: graphId is int? ? graphId : this.graphId,
      floorId: floorId is int? ? floorId : this.floorId,
      floor: floor ?? this.floor,
      roomNumber: roomNumber is String? ? roomNumber : this.roomNumber,
      name: name is String? ? name : this.name,
      category: category is _ipivyxsl.LocationCategory?
          ? category
          : this.category,
      aliases: aliases is String? ? aliases : this.aliases,
      routeNodeId: routeNodeId is String? ? routeNodeId : this.routeNodeId,
      reviewNote: reviewNote is String? ? reviewNote : this.reviewNote,
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

class LocationsUpdateTable extends _is.UpdateTable<LocationsTable> {
  LocationsUpdateTable(super.table);

  _is.ColumnValue<String, String> locationId(String value) => _is.ColumnValue(
    table.locationId,
    value,
  );

  _is.ColumnValue<int, int> graphId(int? value) => _is.ColumnValue(
    table.graphId,
    value,
  );

  _is.ColumnValue<int, int> floorId(int? value) => _is.ColumnValue(
    table.floorId,
    value,
  );

  _is.ColumnValue<int, int> floor(int value) => _is.ColumnValue(
    table.floor,
    value,
  );

  _is.ColumnValue<String, String> roomNumber(String? value) => _is.ColumnValue(
    table.roomNumber,
    value,
  );

  _is.ColumnValue<String, String> name(String? value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<_ipivyxsl.LocationCategory, _ipivyxsl.LocationCategory>
  category(_ipivyxsl.LocationCategory? value) => _is.ColumnValue(
    table.category,
    value,
  );

  _is.ColumnValue<String, String> aliases(String? value) => _is.ColumnValue(
    table.aliases,
    value,
  );

  _is.ColumnValue<String, String> routeNodeId(String? value) => _is.ColumnValue(
    table.routeNodeId,
    value,
  );

  _is.ColumnValue<String, String> reviewNote(String? value) => _is.ColumnValue(
    table.reviewNote,
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

class LocationsTable extends _is.Table<int?> {
  LocationsTable({super.tableRelation}) : super(tableName: 'locations') {
    updateTable = LocationsUpdateTable(this);
    locationId = _is.ColumnString(
      'location_id',
      this,
      fieldName: 'locationId',
    );
    graphId = _is.ColumnInt(
      'graph_id',
      this,
      fieldName: 'graphId',
    );
    floorId = _is.ColumnInt(
      'floor_id',
      this,
      fieldName: 'floorId',
    );
    floor = _is.ColumnInt(
      'floor',
      this,
    );
    roomNumber = _is.ColumnString(
      'room_number',
      this,
      fieldName: 'roomNumber',
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    category = _is.ColumnEnum(
      'category',
      this,
      _is.EnumSerialization.byName,
    );
    aliases = _is.ColumnString(
      'aliases',
      this,
    );
    routeNodeId = _is.ColumnString(
      'route_node_id',
      this,
      fieldName: 'routeNodeId',
    );
    reviewNote = _is.ColumnString(
      'review_note',
      this,
      fieldName: 'reviewNote',
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

  late final LocationsUpdateTable updateTable;

  late final _is.ColumnString locationId;

  late final _is.ColumnInt graphId;

  late final _is.ColumnInt floorId;

  late final _is.ColumnInt floor;

  late final _is.ColumnString roomNumber;

  late final _is.ColumnString name;

  late final _is.ColumnEnum<_ipivyxsl.LocationCategory> category;

  late final _is.ColumnString aliases;

  late final _is.ColumnString routeNodeId;

  late final _is.ColumnString reviewNote;

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
    locationId,
    graphId,
    floorId,
    floor,
    roomNumber,
    name,
    category,
    aliases,
    routeNodeId,
    reviewNote,
    status,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
    deletedAt,
    version,
  ];
}

class LocationsInclude extends _is.IncludeObject {
  LocationsInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Locations.t;
}

class LocationsIncludeList extends _is.IncludeList {
  LocationsIncludeList._({
    _is.WhereExpressionBuilder<LocationsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Locations.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Locations.t;
}

class LocationsRepository {
  const LocationsRepository._();

  /// Returns a list of [Locations]s matching the given query parameters.
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
  Future<List<Locations>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LocationsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LocationsTable>? orderBy,
    _is.OrderByListBuilder<LocationsTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Locations>(
      where: where?.call(Locations.t),
      orderBy: orderBy?.call(Locations.t),
      orderByList: orderByList?.call(Locations.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Locations]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Locations.t`.
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
  _ida.Stream<List<Locations>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LocationsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LocationsTable>? orderBy,
    _is.OrderByListBuilder<LocationsTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Locations>(
      where: where?.call(Locations.t),
      orderBy: orderBy?.call(Locations.t),
      orderByList: orderByList?.call(Locations.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Locations] matching the given query parameters.
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
  Future<Locations?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LocationsTable>? where,
    int? offset,
    _is.OrderByBuilder<LocationsTable>? orderBy,
    _is.OrderByListBuilder<LocationsTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Locations>(
      where: where?.call(Locations.t),
      orderBy: orderBy?.call(Locations.t),
      orderByList: orderByList?.call(Locations.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Locations] by its [id] or null if no such row exists.
  Future<Locations?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Locations>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Locations]s in the list and returns the inserted rows.
  ///
  /// The returned [Locations]s will have their `id` fields set.
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
  Future<List<Locations>> insert(
    _is.DatabaseSession session,
    List<Locations> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Locations>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Locations] and returns the inserted row.
  ///
  /// The returned [Locations] will have its `id` field set.
  Future<Locations> insertRow(
    _is.DatabaseSession session,
    Locations row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Locations>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Locations]s in the list and returns the resulting rows.
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
  /// The returned [Locations]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Locations>> upsert(
    _is.DatabaseSession session,
    List<Locations> rows, {
    required _is.ColumnSelections<LocationsTable> conflictColumns,
    _is.ColumnSelections<LocationsTable>? updateColumns,
    _is.WhereExpressionBuilder<LocationsTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Locations>(
      rows,
      conflictColumns: conflictColumns(Locations.t),
      updateColumns: updateColumns?.call(Locations.t),
      updateWhere: updateWhere?.call(Locations.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Locations] and returns the resulting row.
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
  /// The returned [Locations] will have its `id` field set.
  Future<Locations?> upsertRow(
    _is.DatabaseSession session,
    Locations row, {
    required _is.ColumnSelections<LocationsTable> conflictColumns,
    _is.ColumnSelections<LocationsTable>? updateColumns,
    _is.WhereExpressionBuilder<LocationsTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Locations>(
      row,
      conflictColumns: conflictColumns(Locations.t),
      updateColumns: updateColumns?.call(Locations.t),
      updateWhere: updateWhere?.call(Locations.t),
      transaction: transaction,
    );
  }

  /// Updates all [Locations]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Locations>> update(
    _is.DatabaseSession session,
    List<Locations> rows, {
    _is.ColumnSelections<LocationsTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Locations>(
      rows,
      columns: columns?.call(Locations.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Locations]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Locations> updateRow(
    _is.DatabaseSession session,
    Locations row, {
    _is.ColumnSelections<LocationsTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Locations>(
      row,
      columns: columns?.call(Locations.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Locations] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Locations?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LocationsUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Locations>(
      id,
      columnValues: columnValues(Locations.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Locations]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Locations>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LocationsUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<LocationsTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LocationsTable>? orderBy,
    _is.OrderByListBuilder<LocationsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Locations>(
      columnValues: columnValues(Locations.t.updateTable),
      where: where(Locations.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Locations.t),
      orderByList: orderByList?.call(Locations.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Locations]s in the list and returns the deleted rows.
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
  Future<List<Locations>> delete(
    _is.DatabaseSession session,
    List<Locations> rows, {
    _is.OrderByBuilder<LocationsTable>? orderBy,
    _is.OrderByListBuilder<LocationsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Locations>(
      rows,
      orderBy: orderBy?.call(Locations.t),
      orderByList: orderByList?.call(Locations.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Locations].
  Future<Locations> deleteRow(
    _is.DatabaseSession session,
    Locations row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Locations>(
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
  Future<List<Locations>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LocationsTable> where,
    _is.OrderByBuilder<LocationsTable>? orderBy,
    _is.OrderByListBuilder<LocationsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Locations>(
      where: where(Locations.t),
      orderBy: orderBy?.call(Locations.t),
      orderByList: orderByList?.call(Locations.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LocationsTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Locations>(
      where: where?.call(Locations.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Locations] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LocationsTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Locations>(
      where: where(Locations.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
