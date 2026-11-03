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
import '../orders/order.dart' as _ij3i88ow;
import '../promo_codes/promo_code_redemption.dart' as _iwmivuof;

/// Un pedido que usó un código activado (le ahorró algo una de sus
/// promociones). Los usos de un cliente son sus pedidos no cancelados:
/// cancelar un pedido devuelve el uso.
abstract class OrderPromoCodeUse
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  OrderPromoCodeUse._({
    this.id,
    required this.orderId,
    this.order,
    required this.redemptionId,
    this.redemption,
  });

  factory OrderPromoCodeUse({
    _is.UuidValue? id,
    required _is.UuidValue orderId,
    _ij3i88ow.Order? order,
    required _is.UuidValue redemptionId,
    _iwmivuof.PromoCodeRedemption? redemption,
  }) = _OrderPromoCodeUseImpl;

  factory OrderPromoCodeUse.fromJson(Map<String, dynamic> jsonSerialization) {
    return OrderPromoCodeUse(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      orderId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['orderId'],
      ),
      order: jsonSerialization['order'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_ij3i88ow.Order>(
              jsonSerialization['order'],
            ),
      redemptionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['redemptionId'],
      ),
      redemption: jsonSerialization['redemption'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_iwmivuof.PromoCodeRedemption>(
              jsonSerialization['redemption'],
            ),
    );
  }

  static final t = OrderPromoCodeUseTable();

  static const db = OrderPromoCodeUseRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue orderId;

  _ij3i88ow.Order? order;

  _is.UuidValue redemptionId;

  _iwmivuof.PromoCodeRedemption? redemption;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [OrderPromoCodeUse]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  OrderPromoCodeUse copyWith({
    _is.UuidValue? id,
    _is.UuidValue? orderId,
    _ij3i88ow.Order? order,
    _is.UuidValue? redemptionId,
    _iwmivuof.PromoCodeRedemption? redemption,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OrderPromoCodeUse',
      if (id != null) 'id': id?.toJson(),
      'orderId': orderId.toJson(),
      if (order != null) 'order': order?.toJson(),
      'redemptionId': redemptionId.toJson(),
      if (redemption != null) 'redemption': redemption?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OrderPromoCodeUse',
      if (id != null) 'id': id?.toJson(),
      'orderId': orderId.toJson(),
      if (order != null) 'order': order?.toJsonForProtocol(),
      'redemptionId': redemptionId.toJson(),
      if (redemption != null) 'redemption': redemption?.toJsonForProtocol(),
    };
  }

  static OrderPromoCodeUseInclude include({
    _ij3i88ow.OrderInclude? order,
    _iwmivuof.PromoCodeRedemptionInclude? redemption,
  }) {
    return OrderPromoCodeUseInclude._(
      order: order,
      redemption: redemption,
    );
  }

  static OrderPromoCodeUseIncludeList includeList({
    _is.WhereExpressionBuilder<OrderPromoCodeUseTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OrderPromoCodeUseTable>? orderBy,
    _is.OrderByListBuilder<OrderPromoCodeUseTable>? orderByList,
    OrderPromoCodeUseInclude? include,
  }) {
    return OrderPromoCodeUseIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OrderPromoCodeUse.t),
      orderByList: orderByList?.call(OrderPromoCodeUse.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrderPromoCodeUseImpl extends OrderPromoCodeUse {
  _OrderPromoCodeUseImpl({
    _is.UuidValue? id,
    required _is.UuidValue orderId,
    _ij3i88ow.Order? order,
    required _is.UuidValue redemptionId,
    _iwmivuof.PromoCodeRedemption? redemption,
  }) : super._(
         id: id,
         orderId: orderId,
         order: order,
         redemptionId: redemptionId,
         redemption: redemption,
       );

  /// Returns a shallow copy of this [OrderPromoCodeUse]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  OrderPromoCodeUse copyWith({
    Object? id = _Undefined,
    _is.UuidValue? orderId,
    Object? order = _Undefined,
    _is.UuidValue? redemptionId,
    Object? redemption = _Undefined,
  }) {
    return OrderPromoCodeUse(
      id: id is _is.UuidValue? ? id : this.id,
      orderId: orderId ?? this.orderId,
      order: order is _ij3i88ow.Order? ? order : this.order?.copyWith(),
      redemptionId: redemptionId ?? this.redemptionId,
      redemption: redemption is _iwmivuof.PromoCodeRedemption?
          ? redemption
          : this.redemption?.copyWith(),
    );
  }
}

class OrderPromoCodeUseUpdateTable
    extends _is.UpdateTable<OrderPromoCodeUseTable> {
  OrderPromoCodeUseUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> orderId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.orderId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> redemptionId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.redemptionId,
    value,
  );
}

class OrderPromoCodeUseTable extends _is.Table<_is.UuidValue?> {
  OrderPromoCodeUseTable({super.tableRelation})
    : super(tableName: 'order_promo_code_uses') {
    updateTable = OrderPromoCodeUseUpdateTable(this);
    orderId = _is.ColumnUuid(
      'orderId',
      this,
    );
    redemptionId = _is.ColumnUuid(
      'redemptionId',
      this,
    );
  }

  late final OrderPromoCodeUseUpdateTable updateTable;

  late final _is.ColumnUuid orderId;

  _ij3i88ow.OrderTable? _order;

  late final _is.ColumnUuid redemptionId;

  _iwmivuof.PromoCodeRedemptionTable? _redemption;

  _ij3i88ow.OrderTable get order {
    if (_order != null) return _order!;
    _order = _is.createRelationTable(
      relationFieldName: 'order',
      field: OrderPromoCodeUse.t.orderId,
      foreignField: _ij3i88ow.Order.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ij3i88ow.OrderTable(tableRelation: foreignTableRelation),
    );
    return _order!;
  }

  _iwmivuof.PromoCodeRedemptionTable get redemption {
    if (_redemption != null) return _redemption!;
    _redemption = _is.createRelationTable(
      relationFieldName: 'redemption',
      field: OrderPromoCodeUse.t.redemptionId,
      foreignField: _iwmivuof.PromoCodeRedemption.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) => _iwmivuof.PromoCodeRedemptionTable(
        tableRelation: foreignTableRelation,
      ),
    );
    return _redemption!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    orderId,
    redemptionId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'order') {
      return order;
    }
    if (relationField == 'redemption') {
      return redemption;
    }
    return null;
  }
}

class OrderPromoCodeUseInclude extends _is.IncludeObject {
  OrderPromoCodeUseInclude._({
    _ij3i88ow.OrderInclude? order,
    _iwmivuof.PromoCodeRedemptionInclude? redemption,
  }) {
    _order = order;
    _redemption = redemption;
  }

  _ij3i88ow.OrderInclude? _order;

  _iwmivuof.PromoCodeRedemptionInclude? _redemption;

  @override
  Map<String, _is.Include?> get includes => {
    'order': _order,
    'redemption': _redemption,
  };

  @override
  _is.Table<_is.UuidValue?> get table => OrderPromoCodeUse.t;
}

class OrderPromoCodeUseIncludeList extends _is.IncludeList {
  OrderPromoCodeUseIncludeList._({
    _is.WhereExpressionBuilder<OrderPromoCodeUseTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OrderPromoCodeUse.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => OrderPromoCodeUse.t;
}

class OrderPromoCodeUseRepository {
  const OrderPromoCodeUseRepository._();

  final attachRow = const OrderPromoCodeUseAttachRowRepository._();

  /// Returns a list of [OrderPromoCodeUse]s matching the given query parameters.
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
  Future<List<OrderPromoCodeUse>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OrderPromoCodeUseTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OrderPromoCodeUseTable>? orderBy,
    _is.OrderByListBuilder<OrderPromoCodeUseTable>? orderByList,
    _is.Transaction? transaction,
    OrderPromoCodeUseInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<OrderPromoCodeUse>(
      where: where?.call(OrderPromoCodeUse.t),
      orderBy: orderBy?.call(OrderPromoCodeUse.t),
      orderByList: orderByList?.call(OrderPromoCodeUse.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [OrderPromoCodeUse] matching the given query parameters.
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
  Future<OrderPromoCodeUse?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OrderPromoCodeUseTable>? where,
    int? offset,
    _is.OrderByBuilder<OrderPromoCodeUseTable>? orderBy,
    _is.OrderByListBuilder<OrderPromoCodeUseTable>? orderByList,
    _is.Transaction? transaction,
    OrderPromoCodeUseInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<OrderPromoCodeUse>(
      where: where?.call(OrderPromoCodeUse.t),
      orderBy: orderBy?.call(OrderPromoCodeUse.t),
      orderByList: orderByList?.call(OrderPromoCodeUse.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [OrderPromoCodeUse] by its [id] or null if no such row exists.
  Future<OrderPromoCodeUse?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    OrderPromoCodeUseInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<OrderPromoCodeUse>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [OrderPromoCodeUse]s in the list and returns the inserted rows.
  ///
  /// The returned [OrderPromoCodeUse]s will have their `id` fields set.
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
  Future<List<OrderPromoCodeUse>> insert(
    _is.DatabaseSession session,
    List<OrderPromoCodeUse> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<OrderPromoCodeUse>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [OrderPromoCodeUse] and returns the inserted row.
  ///
  /// The returned [OrderPromoCodeUse] will have its `id` field set.
  Future<OrderPromoCodeUse> insertRow(
    _is.DatabaseSession session,
    OrderPromoCodeUse row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<OrderPromoCodeUse>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [OrderPromoCodeUse]s in the list and returns the resulting rows.
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
  /// The returned [OrderPromoCodeUse]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OrderPromoCodeUse>> upsert(
    _is.DatabaseSession session,
    List<OrderPromoCodeUse> rows, {
    required _is.ColumnSelections<OrderPromoCodeUseTable> conflictColumns,
    _is.ColumnSelections<OrderPromoCodeUseTable>? updateColumns,
    _is.WhereExpressionBuilder<OrderPromoCodeUseTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<OrderPromoCodeUse>(
      rows,
      conflictColumns: conflictColumns(OrderPromoCodeUse.t),
      updateColumns: updateColumns?.call(OrderPromoCodeUse.t),
      updateWhere: updateWhere?.call(OrderPromoCodeUse.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [OrderPromoCodeUse] and returns the resulting row.
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
  /// The returned [OrderPromoCodeUse] will have its `id` field set.
  Future<OrderPromoCodeUse?> upsertRow(
    _is.DatabaseSession session,
    OrderPromoCodeUse row, {
    required _is.ColumnSelections<OrderPromoCodeUseTable> conflictColumns,
    _is.ColumnSelections<OrderPromoCodeUseTable>? updateColumns,
    _is.WhereExpressionBuilder<OrderPromoCodeUseTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<OrderPromoCodeUse>(
      row,
      conflictColumns: conflictColumns(OrderPromoCodeUse.t),
      updateColumns: updateColumns?.call(OrderPromoCodeUse.t),
      updateWhere: updateWhere?.call(OrderPromoCodeUse.t),
      transaction: transaction,
    );
  }

  /// Updates all [OrderPromoCodeUse]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OrderPromoCodeUse>> update(
    _is.DatabaseSession session,
    List<OrderPromoCodeUse> rows, {
    _is.ColumnSelections<OrderPromoCodeUseTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<OrderPromoCodeUse>(
      rows,
      columns: columns?.call(OrderPromoCodeUse.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [OrderPromoCodeUse]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OrderPromoCodeUse> updateRow(
    _is.DatabaseSession session,
    OrderPromoCodeUse row, {
    _is.ColumnSelections<OrderPromoCodeUseTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<OrderPromoCodeUse>(
      row,
      columns: columns?.call(OrderPromoCodeUse.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OrderPromoCodeUse] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<OrderPromoCodeUse?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<OrderPromoCodeUseUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<OrderPromoCodeUse>(
      id,
      columnValues: columnValues(OrderPromoCodeUse.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [OrderPromoCodeUse]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OrderPromoCodeUse>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<OrderPromoCodeUseUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<OrderPromoCodeUseTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OrderPromoCodeUseTable>? orderBy,
    _is.OrderByListBuilder<OrderPromoCodeUseTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<OrderPromoCodeUse>(
      columnValues: columnValues(OrderPromoCodeUse.t.updateTable),
      where: where(OrderPromoCodeUse.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OrderPromoCodeUse.t),
      orderByList: orderByList?.call(OrderPromoCodeUse.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [OrderPromoCodeUse]s in the list and returns the deleted rows.
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
  Future<List<OrderPromoCodeUse>> delete(
    _is.DatabaseSession session,
    List<OrderPromoCodeUse> rows, {
    _is.OrderByBuilder<OrderPromoCodeUseTable>? orderBy,
    _is.OrderByListBuilder<OrderPromoCodeUseTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<OrderPromoCodeUse>(
      rows,
      orderBy: orderBy?.call(OrderPromoCodeUse.t),
      orderByList: orderByList?.call(OrderPromoCodeUse.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [OrderPromoCodeUse].
  Future<OrderPromoCodeUse> deleteRow(
    _is.DatabaseSession session,
    OrderPromoCodeUse row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OrderPromoCodeUse>(
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
  Future<List<OrderPromoCodeUse>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OrderPromoCodeUseTable> where,
    _is.OrderByBuilder<OrderPromoCodeUseTable>? orderBy,
    _is.OrderByListBuilder<OrderPromoCodeUseTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<OrderPromoCodeUse>(
      where: where(OrderPromoCodeUse.t),
      orderBy: orderBy?.call(OrderPromoCodeUse.t),
      orderByList: orderByList?.call(OrderPromoCodeUse.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OrderPromoCodeUseTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<OrderPromoCodeUse>(
      where: where?.call(OrderPromoCodeUse.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [OrderPromoCodeUse] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OrderPromoCodeUseTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<OrderPromoCodeUse>(
      where: where(OrderPromoCodeUse.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class OrderPromoCodeUseAttachRowRepository {
  const OrderPromoCodeUseAttachRowRepository._();

  /// Creates a relation between the given [OrderPromoCodeUse] and [Order]
  /// by setting the [OrderPromoCodeUse]'s foreign key `orderId` to refer to the [Order].
  Future<void> order(
    _is.DatabaseSession session,
    OrderPromoCodeUse orderPromoCodeUse,
    _ij3i88ow.Order order, {
    _is.Transaction? transaction,
  }) async {
    if (orderPromoCodeUse.id == null) {
      throw ArgumentError.notNull('orderPromoCodeUse.id');
    }
    if (order.id == null) {
      throw ArgumentError.notNull('order.id');
    }

    var $orderPromoCodeUse = orderPromoCodeUse.copyWith(orderId: order.id);
    await session.db.updateRow<OrderPromoCodeUse>(
      $orderPromoCodeUse,
      columns: [OrderPromoCodeUse.t.orderId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [OrderPromoCodeUse] and [PromoCodeRedemption]
  /// by setting the [OrderPromoCodeUse]'s foreign key `redemptionId` to refer to the [PromoCodeRedemption].
  Future<void> redemption(
    _is.DatabaseSession session,
    OrderPromoCodeUse orderPromoCodeUse,
    _iwmivuof.PromoCodeRedemption redemption, {
    _is.Transaction? transaction,
  }) async {
    if (orderPromoCodeUse.id == null) {
      throw ArgumentError.notNull('orderPromoCodeUse.id');
    }
    if (redemption.id == null) {
      throw ArgumentError.notNull('redemption.id');
    }

    var $orderPromoCodeUse = orderPromoCodeUse.copyWith(
      redemptionId: redemption.id,
    );
    await session.db.updateRow<OrderPromoCodeUse>(
      $orderPromoCodeUse,
      columns: [OrderPromoCodeUse.t.redemptionId],
      transaction: transaction,
    );
  }
}
