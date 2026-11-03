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

/// Un correo (en minúsculas y sin espacios) que puede activar un código con
/// `eligibility` en `listed`.
abstract class PromoCodeAllowedEmail
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  PromoCodeAllowedEmail._({
    this.id,
    required this.promoCodeId,
    this.promoCode,
    required this.email,
  });

  factory PromoCodeAllowedEmail({
    _is.UuidValue? id,
    required _is.UuidValue promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    required String email,
  }) = _PromoCodeAllowedEmailImpl;

  factory PromoCodeAllowedEmail.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PromoCodeAllowedEmail(
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
      email: jsonSerialization['email'] as String,
    );
  }

  static final t = PromoCodeAllowedEmailTable();

  static const db = PromoCodeAllowedEmailRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue promoCodeId;

  _ijnkkha9.PromoCode? promoCode;

  String email;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [PromoCodeAllowedEmail]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PromoCodeAllowedEmail copyWith({
    _is.UuidValue? id,
    _is.UuidValue? promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    String? email,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PromoCodeAllowedEmail',
      if (id != null) 'id': id?.toJson(),
      'promoCodeId': promoCodeId.toJson(),
      if (promoCode != null) 'promoCode': promoCode?.toJson(),
      'email': email,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PromoCodeAllowedEmail',
      if (id != null) 'id': id?.toJson(),
      'promoCodeId': promoCodeId.toJson(),
      if (promoCode != null) 'promoCode': promoCode?.toJsonForProtocol(),
      'email': email,
    };
  }

  static PromoCodeAllowedEmailInclude include({
    _ijnkkha9.PromoCodeInclude? promoCode,
  }) {
    return PromoCodeAllowedEmailInclude._(promoCode: promoCode);
  }

  static PromoCodeAllowedEmailIncludeList includeList({
    _is.WhereExpressionBuilder<PromoCodeAllowedEmailTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromoCodeAllowedEmailTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeAllowedEmailTable>? orderByList,
    PromoCodeAllowedEmailInclude? include,
  }) {
    return PromoCodeAllowedEmailIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PromoCodeAllowedEmail.t),
      orderByList: orderByList?.call(PromoCodeAllowedEmail.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromoCodeAllowedEmailImpl extends PromoCodeAllowedEmail {
  _PromoCodeAllowedEmailImpl({
    _is.UuidValue? id,
    required _is.UuidValue promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    required String email,
  }) : super._(
         id: id,
         promoCodeId: promoCodeId,
         promoCode: promoCode,
         email: email,
       );

  /// Returns a shallow copy of this [PromoCodeAllowedEmail]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PromoCodeAllowedEmail copyWith({
    Object? id = _Undefined,
    _is.UuidValue? promoCodeId,
    Object? promoCode = _Undefined,
    String? email,
  }) {
    return PromoCodeAllowedEmail(
      id: id is _is.UuidValue? ? id : this.id,
      promoCodeId: promoCodeId ?? this.promoCodeId,
      promoCode: promoCode is _ijnkkha9.PromoCode?
          ? promoCode
          : this.promoCode?.copyWith(),
      email: email ?? this.email,
    );
  }
}

class PromoCodeAllowedEmailUpdateTable
    extends _is.UpdateTable<PromoCodeAllowedEmailTable> {
  PromoCodeAllowedEmailUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> promoCodeId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.promoCodeId,
    value,
  );

  _is.ColumnValue<String, String> email(String value) => _is.ColumnValue(
    table.email,
    value,
  );
}

class PromoCodeAllowedEmailTable extends _is.Table<_is.UuidValue?> {
  PromoCodeAllowedEmailTable({super.tableRelation})
    : super(tableName: 'promo_code_allowed_emails') {
    updateTable = PromoCodeAllowedEmailUpdateTable(this);
    promoCodeId = _is.ColumnUuid(
      'promoCodeId',
      this,
    );
    email = _is.ColumnString(
      'email',
      this,
    );
  }

  late final PromoCodeAllowedEmailUpdateTable updateTable;

  late final _is.ColumnUuid promoCodeId;

  _ijnkkha9.PromoCodeTable? _promoCode;

  late final _is.ColumnString email;

  _ijnkkha9.PromoCodeTable get promoCode {
    if (_promoCode != null) return _promoCode!;
    _promoCode = _is.createRelationTable(
      relationFieldName: 'promoCode',
      field: PromoCodeAllowedEmail.t.promoCodeId,
      foreignField: _ijnkkha9.PromoCode.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ijnkkha9.PromoCodeTable(tableRelation: foreignTableRelation),
    );
    return _promoCode!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    promoCodeId,
    email,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'promoCode') {
      return promoCode;
    }
    return null;
  }
}

class PromoCodeAllowedEmailInclude extends _is.IncludeObject {
  PromoCodeAllowedEmailInclude._({_ijnkkha9.PromoCodeInclude? promoCode}) {
    _promoCode = promoCode;
  }

  _ijnkkha9.PromoCodeInclude? _promoCode;

  @override
  Map<String, _is.Include?> get includes => {'promoCode': _promoCode};

  @override
  _is.Table<_is.UuidValue?> get table => PromoCodeAllowedEmail.t;
}

class PromoCodeAllowedEmailIncludeList extends _is.IncludeList {
  PromoCodeAllowedEmailIncludeList._({
    _is.WhereExpressionBuilder<PromoCodeAllowedEmailTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PromoCodeAllowedEmail.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => PromoCodeAllowedEmail.t;
}

class PromoCodeAllowedEmailRepository {
  const PromoCodeAllowedEmailRepository._();

  final attachRow = const PromoCodeAllowedEmailAttachRowRepository._();

  /// Returns a list of [PromoCodeAllowedEmail]s matching the given query parameters.
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
  Future<List<PromoCodeAllowedEmail>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromoCodeAllowedEmailTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromoCodeAllowedEmailTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeAllowedEmailTable>? orderByList,
    _is.Transaction? transaction,
    PromoCodeAllowedEmailInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PromoCodeAllowedEmail>(
      where: where?.call(PromoCodeAllowedEmail.t),
      orderBy: orderBy?.call(PromoCodeAllowedEmail.t),
      orderByList: orderByList?.call(PromoCodeAllowedEmail.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PromoCodeAllowedEmail] matching the given query parameters.
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
  Future<PromoCodeAllowedEmail?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromoCodeAllowedEmailTable>? where,
    int? offset,
    _is.OrderByBuilder<PromoCodeAllowedEmailTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeAllowedEmailTable>? orderByList,
    _is.Transaction? transaction,
    PromoCodeAllowedEmailInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PromoCodeAllowedEmail>(
      where: where?.call(PromoCodeAllowedEmail.t),
      orderBy: orderBy?.call(PromoCodeAllowedEmail.t),
      orderByList: orderByList?.call(PromoCodeAllowedEmail.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PromoCodeAllowedEmail] by its [id] or null if no such row exists.
  Future<PromoCodeAllowedEmail?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    PromoCodeAllowedEmailInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PromoCodeAllowedEmail>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PromoCodeAllowedEmail]s in the list and returns the inserted rows.
  ///
  /// The returned [PromoCodeAllowedEmail]s will have their `id` fields set.
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
  Future<List<PromoCodeAllowedEmail>> insert(
    _is.DatabaseSession session,
    List<PromoCodeAllowedEmail> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PromoCodeAllowedEmail>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PromoCodeAllowedEmail] and returns the inserted row.
  ///
  /// The returned [PromoCodeAllowedEmail] will have its `id` field set.
  Future<PromoCodeAllowedEmail> insertRow(
    _is.DatabaseSession session,
    PromoCodeAllowedEmail row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PromoCodeAllowedEmail>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PromoCodeAllowedEmail]s in the list and returns the resulting rows.
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
  /// The returned [PromoCodeAllowedEmail]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromoCodeAllowedEmail>> upsert(
    _is.DatabaseSession session,
    List<PromoCodeAllowedEmail> rows, {
    required _is.ColumnSelections<PromoCodeAllowedEmailTable> conflictColumns,
    _is.ColumnSelections<PromoCodeAllowedEmailTable>? updateColumns,
    _is.WhereExpressionBuilder<PromoCodeAllowedEmailTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PromoCodeAllowedEmail>(
      rows,
      conflictColumns: conflictColumns(PromoCodeAllowedEmail.t),
      updateColumns: updateColumns?.call(PromoCodeAllowedEmail.t),
      updateWhere: updateWhere?.call(PromoCodeAllowedEmail.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PromoCodeAllowedEmail] and returns the resulting row.
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
  /// The returned [PromoCodeAllowedEmail] will have its `id` field set.
  Future<PromoCodeAllowedEmail?> upsertRow(
    _is.DatabaseSession session,
    PromoCodeAllowedEmail row, {
    required _is.ColumnSelections<PromoCodeAllowedEmailTable> conflictColumns,
    _is.ColumnSelections<PromoCodeAllowedEmailTable>? updateColumns,
    _is.WhereExpressionBuilder<PromoCodeAllowedEmailTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PromoCodeAllowedEmail>(
      row,
      conflictColumns: conflictColumns(PromoCodeAllowedEmail.t),
      updateColumns: updateColumns?.call(PromoCodeAllowedEmail.t),
      updateWhere: updateWhere?.call(PromoCodeAllowedEmail.t),
      transaction: transaction,
    );
  }

  /// Updates all [PromoCodeAllowedEmail]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromoCodeAllowedEmail>> update(
    _is.DatabaseSession session,
    List<PromoCodeAllowedEmail> rows, {
    _is.ColumnSelections<PromoCodeAllowedEmailTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PromoCodeAllowedEmail>(
      rows,
      columns: columns?.call(PromoCodeAllowedEmail.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PromoCodeAllowedEmail]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PromoCodeAllowedEmail> updateRow(
    _is.DatabaseSession session,
    PromoCodeAllowedEmail row, {
    _is.ColumnSelections<PromoCodeAllowedEmailTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PromoCodeAllowedEmail>(
      row,
      columns: columns?.call(PromoCodeAllowedEmail.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PromoCodeAllowedEmail] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PromoCodeAllowedEmail?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<PromoCodeAllowedEmailUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PromoCodeAllowedEmail>(
      id,
      columnValues: columnValues(PromoCodeAllowedEmail.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PromoCodeAllowedEmail]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromoCodeAllowedEmail>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PromoCodeAllowedEmailUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<PromoCodeAllowedEmailTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromoCodeAllowedEmailTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeAllowedEmailTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PromoCodeAllowedEmail>(
      columnValues: columnValues(PromoCodeAllowedEmail.t.updateTable),
      where: where(PromoCodeAllowedEmail.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PromoCodeAllowedEmail.t),
      orderByList: orderByList?.call(PromoCodeAllowedEmail.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PromoCodeAllowedEmail]s in the list and returns the deleted rows.
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
  Future<List<PromoCodeAllowedEmail>> delete(
    _is.DatabaseSession session,
    List<PromoCodeAllowedEmail> rows, {
    _is.OrderByBuilder<PromoCodeAllowedEmailTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeAllowedEmailTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PromoCodeAllowedEmail>(
      rows,
      orderBy: orderBy?.call(PromoCodeAllowedEmail.t),
      orderByList: orderByList?.call(PromoCodeAllowedEmail.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PromoCodeAllowedEmail].
  Future<PromoCodeAllowedEmail> deleteRow(
    _is.DatabaseSession session,
    PromoCodeAllowedEmail row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PromoCodeAllowedEmail>(
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
  Future<List<PromoCodeAllowedEmail>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PromoCodeAllowedEmailTable> where,
    _is.OrderByBuilder<PromoCodeAllowedEmailTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeAllowedEmailTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PromoCodeAllowedEmail>(
      where: where(PromoCodeAllowedEmail.t),
      orderBy: orderBy?.call(PromoCodeAllowedEmail.t),
      orderByList: orderByList?.call(PromoCodeAllowedEmail.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromoCodeAllowedEmailTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PromoCodeAllowedEmail>(
      where: where?.call(PromoCodeAllowedEmail.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PromoCodeAllowedEmail] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PromoCodeAllowedEmailTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PromoCodeAllowedEmail>(
      where: where(PromoCodeAllowedEmail.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PromoCodeAllowedEmailAttachRowRepository {
  const PromoCodeAllowedEmailAttachRowRepository._();

  /// Creates a relation between the given [PromoCodeAllowedEmail] and [PromoCode]
  /// by setting the [PromoCodeAllowedEmail]'s foreign key `promoCodeId` to refer to the [PromoCode].
  Future<void> promoCode(
    _is.DatabaseSession session,
    PromoCodeAllowedEmail promoCodeAllowedEmail,
    _ijnkkha9.PromoCode promoCode, {
    _is.Transaction? transaction,
  }) async {
    if (promoCodeAllowedEmail.id == null) {
      throw ArgumentError.notNull('promoCodeAllowedEmail.id');
    }
    if (promoCode.id == null) {
      throw ArgumentError.notNull('promoCode.id');
    }

    var $promoCodeAllowedEmail = promoCodeAllowedEmail.copyWith(
      promoCodeId: promoCode.id,
    );
    await session.db.updateRow<PromoCodeAllowedEmail>(
      $promoCodeAllowedEmail,
      columns: [PromoCodeAllowedEmail.t.promoCodeId],
      transaction: transaction,
    );
  }
}
