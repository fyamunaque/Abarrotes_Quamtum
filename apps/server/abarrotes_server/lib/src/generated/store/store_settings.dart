/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:abarrotes_server/src/generated/protocol.dart' as _i1p9jj0z;
import 'package:serverpod/serverpod.dart' as _is;
import '../users/user.dart' as _iqzoui01;

/// Los datos de la tienda que ve el cliente (p. ej. al elegir recojo). Hay
/// un solo registro: singleton es siempre true y su índice único no deja
/// crear otro.
abstract class StoreSettings
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  StoreSettings._({
    this.id,
    bool? singleton,
    required this.name,
    required this.address,
    this.reference,
    this.phone,
    this.openingHours,
    this.pickupInstructions,
    DateTime? updatedAt,
    this.updatedByUserId,
    this.updatedBy,
  }) : singleton = singleton ?? true,
       updatedAt = updatedAt ?? DateTime.now();

  factory StoreSettings({
    _is.UuidValue? id,
    bool? singleton,
    required String name,
    required String address,
    String? reference,
    String? phone,
    String? openingHours,
    String? pickupInstructions,
    DateTime? updatedAt,
    _is.UuidValue? updatedByUserId,
    _iqzoui01.User? updatedBy,
  }) = _StoreSettingsImpl;

  factory StoreSettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return StoreSettings(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      singleton: jsonSerialization['singleton'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['singleton']),
      name: jsonSerialization['name'] as String,
      address: jsonSerialization['address'] as String,
      reference: jsonSerialization['reference'] as String?,
      phone: jsonSerialization['phone'] as String?,
      openingHours: jsonSerialization['openingHours'] as String?,
      pickupInstructions: jsonSerialization['pickupInstructions'] as String?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      updatedByUserId: jsonSerialization['updatedByUserId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['updatedByUserId'],
            ),
      updatedBy: jsonSerialization['updatedBy'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['updatedBy'],
            ),
    );
  }

  static final t = StoreSettingsTable();

  static const db = StoreSettingsRepository._();

  @override
  _is.UuidValue? id;

  bool singleton;

  String name;

  String address;

  /// Cómo llegar ("frente al parque Kennedy").
  String? reference;

  String? phone;

  /// Horario de atención, en texto ("Lun a sáb de 8 a 20 h").
  String? openingHours;

  /// Qué hacer al llegar a recoger un pedido.
  String? pickupInstructions;

  DateTime updatedAt;

  /// Quién lo editó por última vez.
  _is.UuidValue? updatedByUserId;

  _iqzoui01.User? updatedBy;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [StoreSettings]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  StoreSettings copyWith({
    _is.UuidValue? id,
    bool? singleton,
    String? name,
    String? address,
    String? reference,
    String? phone,
    String? openingHours,
    String? pickupInstructions,
    DateTime? updatedAt,
    _is.UuidValue? updatedByUserId,
    _iqzoui01.User? updatedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StoreSettings',
      if (id != null) 'id': id?.toJson(),
      'singleton': singleton,
      'name': name,
      'address': address,
      if (reference != null) 'reference': reference,
      if (phone != null) 'phone': phone,
      if (openingHours != null) 'openingHours': openingHours,
      if (pickupInstructions != null) 'pickupInstructions': pickupInstructions,
      'updatedAt': updatedAt.toJson(),
      if (updatedByUserId != null) 'updatedByUserId': updatedByUserId?.toJson(),
      if (updatedBy != null) 'updatedBy': updatedBy?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StoreSettings',
      if (id != null) 'id': id?.toJson(),
      'singleton': singleton,
      'name': name,
      'address': address,
      if (reference != null) 'reference': reference,
      if (phone != null) 'phone': phone,
      if (openingHours != null) 'openingHours': openingHours,
      if (pickupInstructions != null) 'pickupInstructions': pickupInstructions,
      'updatedAt': updatedAt.toJson(),
      if (updatedByUserId != null) 'updatedByUserId': updatedByUserId?.toJson(),
      if (updatedBy != null) 'updatedBy': updatedBy?.toJsonForProtocol(),
    };
  }

  static StoreSettingsInclude include({_iqzoui01.UserInclude? updatedBy}) {
    return StoreSettingsInclude._(updatedBy: updatedBy);
  }

  static StoreSettingsIncludeList includeList({
    _is.WhereExpressionBuilder<StoreSettingsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StoreSettingsTable>? orderBy,
    _is.OrderByListBuilder<StoreSettingsTable>? orderByList,
    StoreSettingsInclude? include,
  }) {
    return StoreSettingsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StoreSettings.t),
      orderByList: orderByList?.call(StoreSettings.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StoreSettingsImpl extends StoreSettings {
  _StoreSettingsImpl({
    _is.UuidValue? id,
    bool? singleton,
    required String name,
    required String address,
    String? reference,
    String? phone,
    String? openingHours,
    String? pickupInstructions,
    DateTime? updatedAt,
    _is.UuidValue? updatedByUserId,
    _iqzoui01.User? updatedBy,
  }) : super._(
         id: id,
         singleton: singleton,
         name: name,
         address: address,
         reference: reference,
         phone: phone,
         openingHours: openingHours,
         pickupInstructions: pickupInstructions,
         updatedAt: updatedAt,
         updatedByUserId: updatedByUserId,
         updatedBy: updatedBy,
       );

  /// Returns a shallow copy of this [StoreSettings]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  StoreSettings copyWith({
    Object? id = _Undefined,
    bool? singleton,
    String? name,
    String? address,
    Object? reference = _Undefined,
    Object? phone = _Undefined,
    Object? openingHours = _Undefined,
    Object? pickupInstructions = _Undefined,
    DateTime? updatedAt,
    Object? updatedByUserId = _Undefined,
    Object? updatedBy = _Undefined,
  }) {
    return StoreSettings(
      id: id is _is.UuidValue? ? id : this.id,
      singleton: singleton ?? this.singleton,
      name: name ?? this.name,
      address: address ?? this.address,
      reference: reference is String? ? reference : this.reference,
      phone: phone is String? ? phone : this.phone,
      openingHours: openingHours is String? ? openingHours : this.openingHours,
      pickupInstructions: pickupInstructions is String?
          ? pickupInstructions
          : this.pickupInstructions,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByUserId: updatedByUserId is _is.UuidValue?
          ? updatedByUserId
          : this.updatedByUserId,
      updatedBy: updatedBy is _iqzoui01.User?
          ? updatedBy
          : this.updatedBy?.copyWith(),
    );
  }
}

class StoreSettingsUpdateTable extends _is.UpdateTable<StoreSettingsTable> {
  StoreSettingsUpdateTable(super.table);

  _is.ColumnValue<bool, bool> singleton(bool value) => _is.ColumnValue(
    table.singleton,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> address(String value) => _is.ColumnValue(
    table.address,
    value,
  );

  _is.ColumnValue<String, String> reference(String? value) => _is.ColumnValue(
    table.reference,
    value,
  );

  _is.ColumnValue<String, String> phone(String? value) => _is.ColumnValue(
    table.phone,
    value,
  );

  _is.ColumnValue<String, String> openingHours(String? value) =>
      _is.ColumnValue(
        table.openingHours,
        value,
      );

  _is.ColumnValue<String, String> pickupInstructions(String? value) =>
      _is.ColumnValue(
        table.pickupInstructions,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> updatedByUserId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.updatedByUserId,
    value,
  );
}

class StoreSettingsTable extends _is.Table<_is.UuidValue?> {
  StoreSettingsTable({super.tableRelation})
    : super(tableName: 'store_settings') {
    updateTable = StoreSettingsUpdateTable(this);
    singleton = _is.ColumnBool(
      'singleton',
      this,
      hasDefault: true,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    address = _is.ColumnString(
      'address',
      this,
    );
    reference = _is.ColumnString(
      'reference',
      this,
    );
    phone = _is.ColumnString(
      'phone',
      this,
    );
    openingHours = _is.ColumnString(
      'openingHours',
      this,
    );
    pickupInstructions = _is.ColumnString(
      'pickupInstructions',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
    updatedByUserId = _is.ColumnUuid(
      'updatedByUserId',
      this,
    );
  }

  late final StoreSettingsUpdateTable updateTable;

  late final _is.ColumnBool singleton;

  late final _is.ColumnString name;

  late final _is.ColumnString address;

  /// Cómo llegar ("frente al parque Kennedy").
  late final _is.ColumnString reference;

  late final _is.ColumnString phone;

  /// Horario de atención, en texto ("Lun a sáb de 8 a 20 h").
  late final _is.ColumnString openingHours;

  /// Qué hacer al llegar a recoger un pedido.
  late final _is.ColumnString pickupInstructions;

  late final _is.ColumnDateTime updatedAt;

  /// Quién lo editó por última vez.
  late final _is.ColumnUuid updatedByUserId;

  _iqzoui01.UserTable? _updatedBy;

  _iqzoui01.UserTable get updatedBy {
    if (_updatedBy != null) return _updatedBy!;
    _updatedBy = _is.createRelationTable(
      relationFieldName: 'updatedBy',
      field: StoreSettings.t.updatedByUserId,
      foreignField: _iqzoui01.User.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iqzoui01.UserTable(tableRelation: foreignTableRelation),
    );
    return _updatedBy!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    singleton,
    name,
    address,
    reference,
    phone,
    openingHours,
    pickupInstructions,
    updatedAt,
    updatedByUserId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'updatedBy') {
      return updatedBy;
    }
    return null;
  }
}

class StoreSettingsInclude extends _is.IncludeObject {
  StoreSettingsInclude._({_iqzoui01.UserInclude? updatedBy}) {
    _updatedBy = updatedBy;
  }

  _iqzoui01.UserInclude? _updatedBy;

  @override
  Map<String, _is.Include?> get includes => {'updatedBy': _updatedBy};

  @override
  _is.Table<_is.UuidValue?> get table => StoreSettings.t;
}

class StoreSettingsIncludeList extends _is.IncludeList {
  StoreSettingsIncludeList._({
    _is.WhereExpressionBuilder<StoreSettingsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(StoreSettings.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => StoreSettings.t;
}

class StoreSettingsRepository {
  const StoreSettingsRepository._();

  final attachRow = const StoreSettingsAttachRowRepository._();

  final detachRow = const StoreSettingsDetachRowRepository._();

  /// Returns a list of [StoreSettings]s matching the given query parameters.
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
  Future<List<StoreSettings>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StoreSettingsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StoreSettingsTable>? orderBy,
    _is.OrderByListBuilder<StoreSettingsTable>? orderByList,
    _is.Transaction? transaction,
    StoreSettingsInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<StoreSettings>(
      where: where?.call(StoreSettings.t),
      orderBy: orderBy?.call(StoreSettings.t),
      orderByList: orderByList?.call(StoreSettings.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [StoreSettings] matching the given query parameters.
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
  Future<StoreSettings?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StoreSettingsTable>? where,
    int? offset,
    _is.OrderByBuilder<StoreSettingsTable>? orderBy,
    _is.OrderByListBuilder<StoreSettingsTable>? orderByList,
    _is.Transaction? transaction,
    StoreSettingsInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<StoreSettings>(
      where: where?.call(StoreSettings.t),
      orderBy: orderBy?.call(StoreSettings.t),
      orderByList: orderByList?.call(StoreSettings.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [StoreSettings] by its [id] or null if no such row exists.
  Future<StoreSettings?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    StoreSettingsInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<StoreSettings>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [StoreSettings]s in the list and returns the inserted rows.
  ///
  /// The returned [StoreSettings]s will have their `id` fields set.
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
  Future<List<StoreSettings>> insert(
    _is.DatabaseSession session,
    List<StoreSettings> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<StoreSettings>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [StoreSettings] and returns the inserted row.
  ///
  /// The returned [StoreSettings] will have its `id` field set.
  Future<StoreSettings> insertRow(
    _is.DatabaseSession session,
    StoreSettings row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<StoreSettings>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [StoreSettings]s in the list and returns the resulting rows.
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
  /// The returned [StoreSettings]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoreSettings>> upsert(
    _is.DatabaseSession session,
    List<StoreSettings> rows, {
    required _is.ColumnSelections<StoreSettingsTable> conflictColumns,
    _is.ColumnSelections<StoreSettingsTable>? updateColumns,
    _is.WhereExpressionBuilder<StoreSettingsTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<StoreSettings>(
      rows,
      conflictColumns: conflictColumns(StoreSettings.t),
      updateColumns: updateColumns?.call(StoreSettings.t),
      updateWhere: updateWhere?.call(StoreSettings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [StoreSettings] and returns the resulting row.
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
  /// The returned [StoreSettings] will have its `id` field set.
  Future<StoreSettings?> upsertRow(
    _is.DatabaseSession session,
    StoreSettings row, {
    required _is.ColumnSelections<StoreSettingsTable> conflictColumns,
    _is.ColumnSelections<StoreSettingsTable>? updateColumns,
    _is.WhereExpressionBuilder<StoreSettingsTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<StoreSettings>(
      row,
      conflictColumns: conflictColumns(StoreSettings.t),
      updateColumns: updateColumns?.call(StoreSettings.t),
      updateWhere: updateWhere?.call(StoreSettings.t),
      transaction: transaction,
    );
  }

  /// Updates all [StoreSettings]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoreSettings>> update(
    _is.DatabaseSession session,
    List<StoreSettings> rows, {
    _is.ColumnSelections<StoreSettingsTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<StoreSettings>(
      rows,
      columns: columns?.call(StoreSettings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [StoreSettings]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<StoreSettings> updateRow(
    _is.DatabaseSession session,
    StoreSettings row, {
    _is.ColumnSelections<StoreSettingsTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<StoreSettings>(
      row,
      columns: columns?.call(StoreSettings.t),
      transaction: transaction,
    );
  }

  /// Updates a single [StoreSettings] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<StoreSettings?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<StoreSettingsUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<StoreSettings>(
      id,
      columnValues: columnValues(StoreSettings.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [StoreSettings]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoreSettings>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<StoreSettingsUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<StoreSettingsTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StoreSettingsTable>? orderBy,
    _is.OrderByListBuilder<StoreSettingsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<StoreSettings>(
      columnValues: columnValues(StoreSettings.t.updateTable),
      where: where(StoreSettings.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StoreSettings.t),
      orderByList: orderByList?.call(StoreSettings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [StoreSettings]s in the list and returns the deleted rows.
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
  Future<List<StoreSettings>> delete(
    _is.DatabaseSession session,
    List<StoreSettings> rows, {
    _is.OrderByBuilder<StoreSettingsTable>? orderBy,
    _is.OrderByListBuilder<StoreSettingsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<StoreSettings>(
      rows,
      orderBy: orderBy?.call(StoreSettings.t),
      orderByList: orderByList?.call(StoreSettings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [StoreSettings].
  Future<StoreSettings> deleteRow(
    _is.DatabaseSession session,
    StoreSettings row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<StoreSettings>(
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
  Future<List<StoreSettings>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StoreSettingsTable> where,
    _is.OrderByBuilder<StoreSettingsTable>? orderBy,
    _is.OrderByListBuilder<StoreSettingsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<StoreSettings>(
      where: where(StoreSettings.t),
      orderBy: orderBy?.call(StoreSettings.t),
      orderByList: orderByList?.call(StoreSettings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StoreSettingsTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<StoreSettings>(
      where: where?.call(StoreSettings.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [StoreSettings] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StoreSettingsTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<StoreSettings>(
      where: where(StoreSettings.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class StoreSettingsAttachRowRepository {
  const StoreSettingsAttachRowRepository._();

  /// Creates a relation between the given [StoreSettings] and [User]
  /// by setting the [StoreSettings]'s foreign key `updatedByUserId` to refer to the [User].
  Future<void> updatedBy(
    _is.DatabaseSession session,
    StoreSettings storeSettings,
    _iqzoui01.User updatedBy, {
    _is.Transaction? transaction,
  }) async {
    if (storeSettings.id == null) {
      throw ArgumentError.notNull('storeSettings.id');
    }
    if (updatedBy.id == null) {
      throw ArgumentError.notNull('updatedBy.id');
    }

    var $storeSettings = storeSettings.copyWith(updatedByUserId: updatedBy.id);
    await session.db.updateRow<StoreSettings>(
      $storeSettings,
      columns: [StoreSettings.t.updatedByUserId],
      transaction: transaction,
    );
  }
}

class StoreSettingsDetachRowRepository {
  const StoreSettingsDetachRowRepository._();

  /// Detaches the relation between this [StoreSettings] and the [User] set in `updatedBy`
  /// by setting the [StoreSettings]'s foreign key `updatedByUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> updatedBy(
    _is.DatabaseSession session,
    StoreSettings storeSettings, {
    _is.Transaction? transaction,
  }) async {
    if (storeSettings.id == null) {
      throw ArgumentError.notNull('storeSettings.id');
    }

    var $storeSettings = storeSettings.copyWith(updatedByUserId: null);
    await session.db.updateRow<StoreSettings>(
      $storeSettings,
      columns: [StoreSettings.t.updatedByUserId],
      transaction: transaction,
    );
  }
}
