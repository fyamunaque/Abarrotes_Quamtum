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
import '../promotions/promotion.dart' as _irk6gnzq;
import '../vip/vip_customer.dart' as _icy1qtyi;

/// Un cliente VIP elegido para una promoción de clientes elegidos (audiencia
/// `selected`). Le vale mientras siga siendo VIP: si lo dan de baja, deja de
/// valerle aunque la fila siga.
abstract class PromotionRecipient
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  PromotionRecipient._({
    this.id,
    required this.promotionId,
    this.promotion,
    required this.vipCustomerId,
    this.vipCustomer,
  });

  factory PromotionRecipient({
    _is.UuidValue? id,
    required _is.UuidValue promotionId,
    _irk6gnzq.Promotion? promotion,
    required _is.UuidValue vipCustomerId,
    _icy1qtyi.VipCustomer? vipCustomer,
  }) = _PromotionRecipientImpl;

  factory PromotionRecipient.fromJson(Map<String, dynamic> jsonSerialization) {
    return PromotionRecipient(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      promotionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['promotionId'],
      ),
      promotion: jsonSerialization['promotion'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_irk6gnzq.Promotion>(
              jsonSerialization['promotion'],
            ),
      vipCustomerId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['vipCustomerId'],
      ),
      vipCustomer: jsonSerialization['vipCustomer'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_icy1qtyi.VipCustomer>(
              jsonSerialization['vipCustomer'],
            ),
    );
  }

  static final t = PromotionRecipientTable();

  static const db = PromotionRecipientRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue promotionId;

  _irk6gnzq.Promotion? promotion;

  _is.UuidValue vipCustomerId;

  _icy1qtyi.VipCustomer? vipCustomer;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [PromotionRecipient]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PromotionRecipient copyWith({
    _is.UuidValue? id,
    _is.UuidValue? promotionId,
    _irk6gnzq.Promotion? promotion,
    _is.UuidValue? vipCustomerId,
    _icy1qtyi.VipCustomer? vipCustomer,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PromotionRecipient',
      if (id != null) 'id': id?.toJson(),
      'promotionId': promotionId.toJson(),
      if (promotion != null) 'promotion': promotion?.toJson(),
      'vipCustomerId': vipCustomerId.toJson(),
      if (vipCustomer != null) 'vipCustomer': vipCustomer?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PromotionRecipient',
      if (id != null) 'id': id?.toJson(),
      'promotionId': promotionId.toJson(),
      if (promotion != null) 'promotion': promotion?.toJsonForProtocol(),
      'vipCustomerId': vipCustomerId.toJson(),
      if (vipCustomer != null) 'vipCustomer': vipCustomer?.toJsonForProtocol(),
    };
  }

  static PromotionRecipientInclude include({
    _irk6gnzq.PromotionInclude? promotion,
    _icy1qtyi.VipCustomerInclude? vipCustomer,
  }) {
    return PromotionRecipientInclude._(
      promotion: promotion,
      vipCustomer: vipCustomer,
    );
  }

  static PromotionRecipientIncludeList includeList({
    _is.WhereExpressionBuilder<PromotionRecipientTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromotionRecipientTable>? orderBy,
    _is.OrderByListBuilder<PromotionRecipientTable>? orderByList,
    PromotionRecipientInclude? include,
  }) {
    return PromotionRecipientIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PromotionRecipient.t),
      orderByList: orderByList?.call(PromotionRecipient.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromotionRecipientImpl extends PromotionRecipient {
  _PromotionRecipientImpl({
    _is.UuidValue? id,
    required _is.UuidValue promotionId,
    _irk6gnzq.Promotion? promotion,
    required _is.UuidValue vipCustomerId,
    _icy1qtyi.VipCustomer? vipCustomer,
  }) : super._(
         id: id,
         promotionId: promotionId,
         promotion: promotion,
         vipCustomerId: vipCustomerId,
         vipCustomer: vipCustomer,
       );

  /// Returns a shallow copy of this [PromotionRecipient]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PromotionRecipient copyWith({
    Object? id = _Undefined,
    _is.UuidValue? promotionId,
    Object? promotion = _Undefined,
    _is.UuidValue? vipCustomerId,
    Object? vipCustomer = _Undefined,
  }) {
    return PromotionRecipient(
      id: id is _is.UuidValue? ? id : this.id,
      promotionId: promotionId ?? this.promotionId,
      promotion: promotion is _irk6gnzq.Promotion?
          ? promotion
          : this.promotion?.copyWith(),
      vipCustomerId: vipCustomerId ?? this.vipCustomerId,
      vipCustomer: vipCustomer is _icy1qtyi.VipCustomer?
          ? vipCustomer
          : this.vipCustomer?.copyWith(),
    );
  }
}

class PromotionRecipientUpdateTable
    extends _is.UpdateTable<PromotionRecipientTable> {
  PromotionRecipientUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> promotionId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.promotionId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> vipCustomerId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.vipCustomerId,
    value,
  );
}

class PromotionRecipientTable extends _is.Table<_is.UuidValue?> {
  PromotionRecipientTable({super.tableRelation})
    : super(tableName: 'promotion_recipients') {
    updateTable = PromotionRecipientUpdateTable(this);
    promotionId = _is.ColumnUuid(
      'promotionId',
      this,
    );
    vipCustomerId = _is.ColumnUuid(
      'vipCustomerId',
      this,
    );
  }

  late final PromotionRecipientUpdateTable updateTable;

  late final _is.ColumnUuid promotionId;

  _irk6gnzq.PromotionTable? _promotion;

  late final _is.ColumnUuid vipCustomerId;

  _icy1qtyi.VipCustomerTable? _vipCustomer;

  _irk6gnzq.PromotionTable get promotion {
    if (_promotion != null) return _promotion!;
    _promotion = _is.createRelationTable(
      relationFieldName: 'promotion',
      field: PromotionRecipient.t.promotionId,
      foreignField: _irk6gnzq.Promotion.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _irk6gnzq.PromotionTable(tableRelation: foreignTableRelation),
    );
    return _promotion!;
  }

  _icy1qtyi.VipCustomerTable get vipCustomer {
    if (_vipCustomer != null) return _vipCustomer!;
    _vipCustomer = _is.createRelationTable(
      relationFieldName: 'vipCustomer',
      field: PromotionRecipient.t.vipCustomerId,
      foreignField: _icy1qtyi.VipCustomer.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _icy1qtyi.VipCustomerTable(tableRelation: foreignTableRelation),
    );
    return _vipCustomer!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    promotionId,
    vipCustomerId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'promotion') {
      return promotion;
    }
    if (relationField == 'vipCustomer') {
      return vipCustomer;
    }
    return null;
  }
}

class PromotionRecipientInclude extends _is.IncludeObject {
  PromotionRecipientInclude._({
    _irk6gnzq.PromotionInclude? promotion,
    _icy1qtyi.VipCustomerInclude? vipCustomer,
  }) {
    _promotion = promotion;
    _vipCustomer = vipCustomer;
  }

  _irk6gnzq.PromotionInclude? _promotion;

  _icy1qtyi.VipCustomerInclude? _vipCustomer;

  @override
  Map<String, _is.Include?> get includes => {
    'promotion': _promotion,
    'vipCustomer': _vipCustomer,
  };

  @override
  _is.Table<_is.UuidValue?> get table => PromotionRecipient.t;
}

class PromotionRecipientIncludeList extends _is.IncludeList {
  PromotionRecipientIncludeList._({
    _is.WhereExpressionBuilder<PromotionRecipientTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PromotionRecipient.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => PromotionRecipient.t;
}

class PromotionRecipientRepository {
  const PromotionRecipientRepository._();

  final attachRow = const PromotionRecipientAttachRowRepository._();

  /// Returns a list of [PromotionRecipient]s matching the given query parameters.
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
  Future<List<PromotionRecipient>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromotionRecipientTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromotionRecipientTable>? orderBy,
    _is.OrderByListBuilder<PromotionRecipientTable>? orderByList,
    _is.Transaction? transaction,
    PromotionRecipientInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PromotionRecipient>(
      where: where?.call(PromotionRecipient.t),
      orderBy: orderBy?.call(PromotionRecipient.t),
      orderByList: orderByList?.call(PromotionRecipient.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PromotionRecipient] matching the given query parameters.
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
  Future<PromotionRecipient?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromotionRecipientTable>? where,
    int? offset,
    _is.OrderByBuilder<PromotionRecipientTable>? orderBy,
    _is.OrderByListBuilder<PromotionRecipientTable>? orderByList,
    _is.Transaction? transaction,
    PromotionRecipientInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PromotionRecipient>(
      where: where?.call(PromotionRecipient.t),
      orderBy: orderBy?.call(PromotionRecipient.t),
      orderByList: orderByList?.call(PromotionRecipient.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PromotionRecipient] by its [id] or null if no such row exists.
  Future<PromotionRecipient?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    PromotionRecipientInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PromotionRecipient>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PromotionRecipient]s in the list and returns the inserted rows.
  ///
  /// The returned [PromotionRecipient]s will have their `id` fields set.
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
  Future<List<PromotionRecipient>> insert(
    _is.DatabaseSession session,
    List<PromotionRecipient> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PromotionRecipient>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PromotionRecipient] and returns the inserted row.
  ///
  /// The returned [PromotionRecipient] will have its `id` field set.
  Future<PromotionRecipient> insertRow(
    _is.DatabaseSession session,
    PromotionRecipient row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PromotionRecipient>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PromotionRecipient]s in the list and returns the resulting rows.
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
  /// The returned [PromotionRecipient]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromotionRecipient>> upsert(
    _is.DatabaseSession session,
    List<PromotionRecipient> rows, {
    required _is.ColumnSelections<PromotionRecipientTable> conflictColumns,
    _is.ColumnSelections<PromotionRecipientTable>? updateColumns,
    _is.WhereExpressionBuilder<PromotionRecipientTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PromotionRecipient>(
      rows,
      conflictColumns: conflictColumns(PromotionRecipient.t),
      updateColumns: updateColumns?.call(PromotionRecipient.t),
      updateWhere: updateWhere?.call(PromotionRecipient.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PromotionRecipient] and returns the resulting row.
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
  /// The returned [PromotionRecipient] will have its `id` field set.
  Future<PromotionRecipient?> upsertRow(
    _is.DatabaseSession session,
    PromotionRecipient row, {
    required _is.ColumnSelections<PromotionRecipientTable> conflictColumns,
    _is.ColumnSelections<PromotionRecipientTable>? updateColumns,
    _is.WhereExpressionBuilder<PromotionRecipientTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PromotionRecipient>(
      row,
      conflictColumns: conflictColumns(PromotionRecipient.t),
      updateColumns: updateColumns?.call(PromotionRecipient.t),
      updateWhere: updateWhere?.call(PromotionRecipient.t),
      transaction: transaction,
    );
  }

  /// Updates all [PromotionRecipient]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromotionRecipient>> update(
    _is.DatabaseSession session,
    List<PromotionRecipient> rows, {
    _is.ColumnSelections<PromotionRecipientTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PromotionRecipient>(
      rows,
      columns: columns?.call(PromotionRecipient.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PromotionRecipient]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PromotionRecipient> updateRow(
    _is.DatabaseSession session,
    PromotionRecipient row, {
    _is.ColumnSelections<PromotionRecipientTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PromotionRecipient>(
      row,
      columns: columns?.call(PromotionRecipient.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PromotionRecipient] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PromotionRecipient?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<PromotionRecipientUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PromotionRecipient>(
      id,
      columnValues: columnValues(PromotionRecipient.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PromotionRecipient]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromotionRecipient>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PromotionRecipientUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<PromotionRecipientTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromotionRecipientTable>? orderBy,
    _is.OrderByListBuilder<PromotionRecipientTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PromotionRecipient>(
      columnValues: columnValues(PromotionRecipient.t.updateTable),
      where: where(PromotionRecipient.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PromotionRecipient.t),
      orderByList: orderByList?.call(PromotionRecipient.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PromotionRecipient]s in the list and returns the deleted rows.
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
  Future<List<PromotionRecipient>> delete(
    _is.DatabaseSession session,
    List<PromotionRecipient> rows, {
    _is.OrderByBuilder<PromotionRecipientTable>? orderBy,
    _is.OrderByListBuilder<PromotionRecipientTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PromotionRecipient>(
      rows,
      orderBy: orderBy?.call(PromotionRecipient.t),
      orderByList: orderByList?.call(PromotionRecipient.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PromotionRecipient].
  Future<PromotionRecipient> deleteRow(
    _is.DatabaseSession session,
    PromotionRecipient row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PromotionRecipient>(
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
  Future<List<PromotionRecipient>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PromotionRecipientTable> where,
    _is.OrderByBuilder<PromotionRecipientTable>? orderBy,
    _is.OrderByListBuilder<PromotionRecipientTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PromotionRecipient>(
      where: where(PromotionRecipient.t),
      orderBy: orderBy?.call(PromotionRecipient.t),
      orderByList: orderByList?.call(PromotionRecipient.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromotionRecipientTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PromotionRecipient>(
      where: where?.call(PromotionRecipient.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PromotionRecipient] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PromotionRecipientTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PromotionRecipient>(
      where: where(PromotionRecipient.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PromotionRecipientAttachRowRepository {
  const PromotionRecipientAttachRowRepository._();

  /// Creates a relation between the given [PromotionRecipient] and [Promotion]
  /// by setting the [PromotionRecipient]'s foreign key `promotionId` to refer to the [Promotion].
  Future<void> promotion(
    _is.DatabaseSession session,
    PromotionRecipient promotionRecipient,
    _irk6gnzq.Promotion promotion, {
    _is.Transaction? transaction,
  }) async {
    if (promotionRecipient.id == null) {
      throw ArgumentError.notNull('promotionRecipient.id');
    }
    if (promotion.id == null) {
      throw ArgumentError.notNull('promotion.id');
    }

    var $promotionRecipient = promotionRecipient.copyWith(
      promotionId: promotion.id,
    );
    await session.db.updateRow<PromotionRecipient>(
      $promotionRecipient,
      columns: [PromotionRecipient.t.promotionId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [PromotionRecipient] and [VipCustomer]
  /// by setting the [PromotionRecipient]'s foreign key `vipCustomerId` to refer to the [VipCustomer].
  Future<void> vipCustomer(
    _is.DatabaseSession session,
    PromotionRecipient promotionRecipient,
    _icy1qtyi.VipCustomer vipCustomer, {
    _is.Transaction? transaction,
  }) async {
    if (promotionRecipient.id == null) {
      throw ArgumentError.notNull('promotionRecipient.id');
    }
    if (vipCustomer.id == null) {
      throw ArgumentError.notNull('vipCustomer.id');
    }

    var $promotionRecipient = promotionRecipient.copyWith(
      vipCustomerId: vipCustomer.id,
    );
    await session.db.updateRow<PromotionRecipient>(
      $promotionRecipient,
      columns: [PromotionRecipient.t.vipCustomerId],
      transaction: transaction,
    );
  }
}
