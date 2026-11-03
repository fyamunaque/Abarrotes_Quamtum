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
import '../promo_codes/promo_code.dart' as _ijnkkha9;
import '../users/user.dart' as _iqzoui01;

/// Un código activado por un cliente: sus promociones le valen hasta
/// `expiresAt` (exclusivo) y mientras le queden usos. Uno por cliente y
/// código.
abstract class PromoCodeRedemption
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  PromoCodeRedemption._({
    this.id,
    required this.promoCodeId,
    this.promoCode,
    required this.userId,
    this.user,
    required this.activatedAt,
    required this.expiresAt,
  });

  factory PromoCodeRedemption({
    _is.UuidValue? id,
    required _is.UuidValue promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    required _is.UuidValue userId,
    _iqzoui01.User? user,
    required DateTime activatedAt,
    required DateTime expiresAt,
  }) = _PromoCodeRedemptionImpl;

  factory PromoCodeRedemption.fromJson(Map<String, dynamic> jsonSerialization) {
    return PromoCodeRedemption(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      promoCodeId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['promoCodeId'],
      ),
      promoCode: jsonSerialization['promoCode'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_ijnkkha9.PromoCode>(
              jsonSerialization['promoCode'],
            ),
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      user: jsonSerialization['user'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['user'],
            ),
      activatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['activatedAt'],
      ),
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  static final t = PromoCodeRedemptionTable();

  static const db = PromoCodeRedemptionRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue promoCodeId;

  _ijnkkha9.PromoCode? promoCode;

  _is.UuidValue userId;

  _iqzoui01.User? user;

  DateTime activatedAt;

  DateTime expiresAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [PromoCodeRedemption]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PromoCodeRedemption copyWith({
    _is.UuidValue? id,
    _is.UuidValue? promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    _is.UuidValue? userId,
    _iqzoui01.User? user,
    DateTime? activatedAt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PromoCodeRedemption',
      if (id != null) 'id': id?.toJson(),
      'promoCodeId': promoCodeId.toJson(),
      if (promoCode != null) 'promoCode': promoCode?.toJson(),
      'userId': userId.toJson(),
      if (user != null) 'user': user?.toJson(),
      'activatedAt': activatedAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PromoCodeRedemption',
      if (id != null) 'id': id?.toJson(),
      'promoCodeId': promoCodeId.toJson(),
      if (promoCode != null) 'promoCode': promoCode?.toJsonForProtocol(),
      'userId': userId.toJson(),
      if (user != null) 'user': user?.toJsonForProtocol(),
      'activatedAt': activatedAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  static PromoCodeRedemptionInclude include({
    _ijnkkha9.PromoCodeInclude? promoCode,
    _iqzoui01.UserInclude? user,
  }) {
    return PromoCodeRedemptionInclude._(
      promoCode: promoCode,
      user: user,
    );
  }

  static PromoCodeRedemptionIncludeList includeList({
    _is.WhereExpressionBuilder<PromoCodeRedemptionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromoCodeRedemptionTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeRedemptionTable>? orderByList,
    PromoCodeRedemptionInclude? include,
  }) {
    return PromoCodeRedemptionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PromoCodeRedemption.t),
      orderByList: orderByList?.call(PromoCodeRedemption.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromoCodeRedemptionImpl extends PromoCodeRedemption {
  _PromoCodeRedemptionImpl({
    _is.UuidValue? id,
    required _is.UuidValue promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    required _is.UuidValue userId,
    _iqzoui01.User? user,
    required DateTime activatedAt,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         promoCodeId: promoCodeId,
         promoCode: promoCode,
         userId: userId,
         user: user,
         activatedAt: activatedAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [PromoCodeRedemption]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PromoCodeRedemption copyWith({
    Object? id = _Undefined,
    _is.UuidValue? promoCodeId,
    Object? promoCode = _Undefined,
    _is.UuidValue? userId,
    Object? user = _Undefined,
    DateTime? activatedAt,
    DateTime? expiresAt,
  }) {
    return PromoCodeRedemption(
      id: id is _is.UuidValue? ? id : this.id,
      promoCodeId: promoCodeId ?? this.promoCodeId,
      promoCode: promoCode is _ijnkkha9.PromoCode?
          ? promoCode
          : this.promoCode?.copyWith(),
      userId: userId ?? this.userId,
      user: user is _iqzoui01.User? ? user : this.user?.copyWith(),
      activatedAt: activatedAt ?? this.activatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class PromoCodeRedemptionUpdateTable
    extends _is.UpdateTable<PromoCodeRedemptionTable> {
  PromoCodeRedemptionUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> promoCodeId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.promoCodeId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> activatedAt(DateTime value) =>
      _is.ColumnValue(
        table.activatedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );
}

class PromoCodeRedemptionTable extends _is.Table<_is.UuidValue?> {
  PromoCodeRedemptionTable({super.tableRelation})
    : super(tableName: 'promo_code_redemptions') {
    updateTable = PromoCodeRedemptionUpdateTable(this);
    promoCodeId = _is.ColumnUuid(
      'promoCodeId',
      this,
    );
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    activatedAt = _is.ColumnDateTime(
      'activatedAt',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
  }

  late final PromoCodeRedemptionUpdateTable updateTable;

  late final _is.ColumnUuid promoCodeId;

  _ijnkkha9.PromoCodeTable? _promoCode;

  late final _is.ColumnUuid userId;

  _iqzoui01.UserTable? _user;

  late final _is.ColumnDateTime activatedAt;

  late final _is.ColumnDateTime expiresAt;

  _ijnkkha9.PromoCodeTable get promoCode {
    if (_promoCode != null) return _promoCode!;
    _promoCode = _is.createRelationTable(
      relationFieldName: 'promoCode',
      field: PromoCodeRedemption.t.promoCodeId,
      foreignField: _ijnkkha9.PromoCode.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ijnkkha9.PromoCodeTable(tableRelation: foreignTableRelation),
    );
    return _promoCode!;
  }

  _iqzoui01.UserTable get user {
    if (_user != null) return _user!;
    _user = _is.createRelationTable(
      relationFieldName: 'user',
      field: PromoCodeRedemption.t.userId,
      foreignField: _iqzoui01.User.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iqzoui01.UserTable(tableRelation: foreignTableRelation),
    );
    return _user!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    promoCodeId,
    userId,
    activatedAt,
    expiresAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'promoCode') {
      return promoCode;
    }
    if (relationField == 'user') {
      return user;
    }
    return null;
  }
}

class PromoCodeRedemptionInclude extends _is.IncludeObject {
  PromoCodeRedemptionInclude._({
    _ijnkkha9.PromoCodeInclude? promoCode,
    _iqzoui01.UserInclude? user,
  }) {
    _promoCode = promoCode;
    _user = user;
  }

  _ijnkkha9.PromoCodeInclude? _promoCode;

  _iqzoui01.UserInclude? _user;

  @override
  Map<String, _is.Include?> get includes => {
    'promoCode': _promoCode,
    'user': _user,
  };

  @override
  _is.Table<_is.UuidValue?> get table => PromoCodeRedemption.t;
}

class PromoCodeRedemptionIncludeList extends _is.IncludeList {
  PromoCodeRedemptionIncludeList._({
    _is.WhereExpressionBuilder<PromoCodeRedemptionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PromoCodeRedemption.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => PromoCodeRedemption.t;
}

class PromoCodeRedemptionRepository {
  const PromoCodeRedemptionRepository._();

  final attachRow = const PromoCodeRedemptionAttachRowRepository._();

  /// Returns a list of [PromoCodeRedemption]s matching the given query parameters.
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
  Future<List<PromoCodeRedemption>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromoCodeRedemptionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromoCodeRedemptionTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeRedemptionTable>? orderByList,
    _is.Transaction? transaction,
    PromoCodeRedemptionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PromoCodeRedemption>(
      where: where?.call(PromoCodeRedemption.t),
      orderBy: orderBy?.call(PromoCodeRedemption.t),
      orderByList: orderByList?.call(PromoCodeRedemption.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PromoCodeRedemption] matching the given query parameters.
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
  Future<PromoCodeRedemption?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromoCodeRedemptionTable>? where,
    int? offset,
    _is.OrderByBuilder<PromoCodeRedemptionTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeRedemptionTable>? orderByList,
    _is.Transaction? transaction,
    PromoCodeRedemptionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PromoCodeRedemption>(
      where: where?.call(PromoCodeRedemption.t),
      orderBy: orderBy?.call(PromoCodeRedemption.t),
      orderByList: orderByList?.call(PromoCodeRedemption.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PromoCodeRedemption] by its [id] or null if no such row exists.
  Future<PromoCodeRedemption?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    PromoCodeRedemptionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PromoCodeRedemption>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PromoCodeRedemption]s in the list and returns the inserted rows.
  ///
  /// The returned [PromoCodeRedemption]s will have their `id` fields set.
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
  Future<List<PromoCodeRedemption>> insert(
    _is.DatabaseSession session,
    List<PromoCodeRedemption> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PromoCodeRedemption>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PromoCodeRedemption] and returns the inserted row.
  ///
  /// The returned [PromoCodeRedemption] will have its `id` field set.
  Future<PromoCodeRedemption> insertRow(
    _is.DatabaseSession session,
    PromoCodeRedemption row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PromoCodeRedemption>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PromoCodeRedemption]s in the list and returns the resulting rows.
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
  /// The returned [PromoCodeRedemption]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromoCodeRedemption>> upsert(
    _is.DatabaseSession session,
    List<PromoCodeRedemption> rows, {
    required _is.ColumnSelections<PromoCodeRedemptionTable> conflictColumns,
    _is.ColumnSelections<PromoCodeRedemptionTable>? updateColumns,
    _is.WhereExpressionBuilder<PromoCodeRedemptionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PromoCodeRedemption>(
      rows,
      conflictColumns: conflictColumns(PromoCodeRedemption.t),
      updateColumns: updateColumns?.call(PromoCodeRedemption.t),
      updateWhere: updateWhere?.call(PromoCodeRedemption.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PromoCodeRedemption] and returns the resulting row.
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
  /// The returned [PromoCodeRedemption] will have its `id` field set.
  Future<PromoCodeRedemption?> upsertRow(
    _is.DatabaseSession session,
    PromoCodeRedemption row, {
    required _is.ColumnSelections<PromoCodeRedemptionTable> conflictColumns,
    _is.ColumnSelections<PromoCodeRedemptionTable>? updateColumns,
    _is.WhereExpressionBuilder<PromoCodeRedemptionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PromoCodeRedemption>(
      row,
      conflictColumns: conflictColumns(PromoCodeRedemption.t),
      updateColumns: updateColumns?.call(PromoCodeRedemption.t),
      updateWhere: updateWhere?.call(PromoCodeRedemption.t),
      transaction: transaction,
    );
  }

  /// Updates all [PromoCodeRedemption]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromoCodeRedemption>> update(
    _is.DatabaseSession session,
    List<PromoCodeRedemption> rows, {
    _is.ColumnSelections<PromoCodeRedemptionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PromoCodeRedemption>(
      rows,
      columns: columns?.call(PromoCodeRedemption.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PromoCodeRedemption]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PromoCodeRedemption> updateRow(
    _is.DatabaseSession session,
    PromoCodeRedemption row, {
    _is.ColumnSelections<PromoCodeRedemptionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PromoCodeRedemption>(
      row,
      columns: columns?.call(PromoCodeRedemption.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PromoCodeRedemption] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PromoCodeRedemption?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<PromoCodeRedemptionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PromoCodeRedemption>(
      id,
      columnValues: columnValues(PromoCodeRedemption.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PromoCodeRedemption]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromoCodeRedemption>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PromoCodeRedemptionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<PromoCodeRedemptionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromoCodeRedemptionTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeRedemptionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PromoCodeRedemption>(
      columnValues: columnValues(PromoCodeRedemption.t.updateTable),
      where: where(PromoCodeRedemption.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PromoCodeRedemption.t),
      orderByList: orderByList?.call(PromoCodeRedemption.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PromoCodeRedemption]s in the list and returns the deleted rows.
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
  Future<List<PromoCodeRedemption>> delete(
    _is.DatabaseSession session,
    List<PromoCodeRedemption> rows, {
    _is.OrderByBuilder<PromoCodeRedemptionTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeRedemptionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PromoCodeRedemption>(
      rows,
      orderBy: orderBy?.call(PromoCodeRedemption.t),
      orderByList: orderByList?.call(PromoCodeRedemption.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PromoCodeRedemption].
  Future<PromoCodeRedemption> deleteRow(
    _is.DatabaseSession session,
    PromoCodeRedemption row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PromoCodeRedemption>(
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
  Future<List<PromoCodeRedemption>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PromoCodeRedemptionTable> where,
    _is.OrderByBuilder<PromoCodeRedemptionTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeRedemptionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PromoCodeRedemption>(
      where: where(PromoCodeRedemption.t),
      orderBy: orderBy?.call(PromoCodeRedemption.t),
      orderByList: orderByList?.call(PromoCodeRedemption.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromoCodeRedemptionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PromoCodeRedemption>(
      where: where?.call(PromoCodeRedemption.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PromoCodeRedemption] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PromoCodeRedemptionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PromoCodeRedemption>(
      where: where(PromoCodeRedemption.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PromoCodeRedemptionAttachRowRepository {
  const PromoCodeRedemptionAttachRowRepository._();

  /// Creates a relation between the given [PromoCodeRedemption] and [PromoCode]
  /// by setting the [PromoCodeRedemption]'s foreign key `promoCodeId` to refer to the [PromoCode].
  Future<void> promoCode(
    _is.DatabaseSession session,
    PromoCodeRedemption promoCodeRedemption,
    _ijnkkha9.PromoCode promoCode, {
    _is.Transaction? transaction,
  }) async {
    if (promoCodeRedemption.id == null) {
      throw ArgumentError.notNull('promoCodeRedemption.id');
    }
    if (promoCode.id == null) {
      throw ArgumentError.notNull('promoCode.id');
    }

    var $promoCodeRedemption = promoCodeRedemption.copyWith(
      promoCodeId: promoCode.id,
    );
    await session.db.updateRow<PromoCodeRedemption>(
      $promoCodeRedemption,
      columns: [PromoCodeRedemption.t.promoCodeId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [PromoCodeRedemption] and [User]
  /// by setting the [PromoCodeRedemption]'s foreign key `userId` to refer to the [User].
  Future<void> user(
    _is.DatabaseSession session,
    PromoCodeRedemption promoCodeRedemption,
    _iqzoui01.User user, {
    _is.Transaction? transaction,
  }) async {
    if (promoCodeRedemption.id == null) {
      throw ArgumentError.notNull('promoCodeRedemption.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $promoCodeRedemption = promoCodeRedemption.copyWith(userId: user.id);
    await session.db.updateRow<PromoCodeRedemption>(
      $promoCodeRedemption,
      columns: [PromoCodeRedemption.t.userId],
      transaction: transaction,
    );
  }
}
