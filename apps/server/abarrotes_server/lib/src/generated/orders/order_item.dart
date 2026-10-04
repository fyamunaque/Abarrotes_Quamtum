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
import '../products/product.dart' as _iubf72bi;

abstract class OrderItem
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  OrderItem._({
    this.id,
    required this.quantity,
    required this.unitPriceCents,
    required this.orderId,
    this.order,
    required this.productId,
    this.product,
  });

  factory OrderItem({
    _is.UuidValue? id,
    required int quantity,
    required int unitPriceCents,
    required _is.UuidValue orderId,
    _ij3i88ow.Order? order,
    required _is.UuidValue productId,
    _iubf72bi.Product? product,
  }) = _OrderItemImpl;

  factory OrderItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return OrderItem(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      quantity: jsonSerialization['quantity'] as int,
      unitPriceCents: jsonSerialization['unitPriceCents'] as int,
      orderId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['orderId'],
      ),
      order: jsonSerialization['order'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_ij3i88ow.Order>(
              jsonSerialization['order'],
            ),
      productId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['productId'],
      ),
      product: jsonSerialization['product'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_iubf72bi.Product>(
              jsonSerialization['product'],
            ),
    );
  }

  static final t = OrderItemTable();

  static const db = OrderItemRepository._();

  @override
  _is.UuidValue? id;

  int quantity;

  /// Precio unitario cobrado, en céntimos (el promocional si había promoción).
  int unitPriceCents;

  _is.UuidValue orderId;

  _ij3i88ow.Order? order;

  _is.UuidValue productId;

  _iubf72bi.Product? product;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [OrderItem]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  OrderItem copyWith({
    _is.UuidValue? id,
    int? quantity,
    int? unitPriceCents,
    _is.UuidValue? orderId,
    _ij3i88ow.Order? order,
    _is.UuidValue? productId,
    _iubf72bi.Product? product,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OrderItem',
      if (id != null) 'id': id?.toJson(),
      'quantity': quantity,
      'unitPriceCents': unitPriceCents,
      'orderId': orderId.toJson(),
      if (order != null) 'order': order?.toJson(),
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OrderItem',
      if (id != null) 'id': id?.toJson(),
      'quantity': quantity,
      'unitPriceCents': unitPriceCents,
      'orderId': orderId.toJson(),
      if (order != null) 'order': order?.toJsonForProtocol(),
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJsonForProtocol(),
    };
  }

  static OrderItemInclude include({
    _ij3i88ow.OrderInclude? order,
    _iubf72bi.ProductInclude? product,
  }) {
    return OrderItemInclude._(
      order: order,
      product: product,
    );
  }

  static OrderItemIncludeList includeList({
    _is.WhereExpressionBuilder<OrderItemTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OrderItemTable>? orderBy,
    _is.OrderByListBuilder<OrderItemTable>? orderByList,
    OrderItemInclude? include,
  }) {
    return OrderItemIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OrderItem.t),
      orderByList: orderByList?.call(OrderItem.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrderItemImpl extends OrderItem {
  _OrderItemImpl({
    _is.UuidValue? id,
    required int quantity,
    required int unitPriceCents,
    required _is.UuidValue orderId,
    _ij3i88ow.Order? order,
    required _is.UuidValue productId,
    _iubf72bi.Product? product,
  }) : super._(
         id: id,
         quantity: quantity,
         unitPriceCents: unitPriceCents,
         orderId: orderId,
         order: order,
         productId: productId,
         product: product,
       );

  /// Returns a shallow copy of this [OrderItem]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  OrderItem copyWith({
    Object? id = _Undefined,
    int? quantity,
    int? unitPriceCents,
    _is.UuidValue? orderId,
    Object? order = _Undefined,
    _is.UuidValue? productId,
    Object? product = _Undefined,
  }) {
    return OrderItem(
      id: id is _is.UuidValue? ? id : this.id,
      quantity: quantity ?? this.quantity,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      orderId: orderId ?? this.orderId,
      order: order is _ij3i88ow.Order? ? order : this.order?.copyWith(),
      productId: productId ?? this.productId,
      product: product is _iubf72bi.Product?
          ? product
          : this.product?.copyWith(),
    );
  }
}

class OrderItemUpdateTable extends _is.UpdateTable<OrderItemTable> {
  OrderItemUpdateTable(super.table);

  _is.ColumnValue<int, int> quantity(int value) => _is.ColumnValue(
    table.quantity,
    value,
  );

  _is.ColumnValue<int, int> unitPriceCents(int value) => _is.ColumnValue(
    table.unitPriceCents,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> orderId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.orderId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> productId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.productId,
    value,
  );
}

class OrderItemTable extends _is.Table<_is.UuidValue?> {
  OrderItemTable({super.tableRelation}) : super(tableName: 'order_items') {
    updateTable = OrderItemUpdateTable(this);
    quantity = _is.ColumnInt(
      'quantity',
      this,
    );
    unitPriceCents = _is.ColumnInt(
      'unitPriceCents',
      this,
    );
    orderId = _is.ColumnUuid(
      'orderId',
      this,
    );
    productId = _is.ColumnUuid(
      'productId',
      this,
    );
  }

  late final OrderItemUpdateTable updateTable;

  late final _is.ColumnInt quantity;

  /// Precio unitario cobrado, en céntimos (el promocional si había promoción).
  late final _is.ColumnInt unitPriceCents;

  late final _is.ColumnUuid orderId;

  _ij3i88ow.OrderTable? _order;

  late final _is.ColumnUuid productId;

  _iubf72bi.ProductTable? _product;

  _ij3i88ow.OrderTable get order {
    if (_order != null) return _order!;
    _order = _is.createRelationTable(
      relationFieldName: 'order',
      field: OrderItem.t.orderId,
      foreignField: _ij3i88ow.Order.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ij3i88ow.OrderTable(tableRelation: foreignTableRelation),
    );
    return _order!;
  }

  _iubf72bi.ProductTable get product {
    if (_product != null) return _product!;
    _product = _is.createRelationTable(
      relationFieldName: 'product',
      field: OrderItem.t.productId,
      foreignField: _iubf72bi.Product.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iubf72bi.ProductTable(tableRelation: foreignTableRelation),
    );
    return _product!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    quantity,
    unitPriceCents,
    orderId,
    productId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'order') {
      return order;
    }
    if (relationField == 'product') {
      return product;
    }
    return null;
  }
}

class OrderItemInclude extends _is.IncludeObject {
  OrderItemInclude._({
    _ij3i88ow.OrderInclude? order,
    _iubf72bi.ProductInclude? product,
  }) {
    _order = order;
    _product = product;
  }

  _ij3i88ow.OrderInclude? _order;

  _iubf72bi.ProductInclude? _product;

  @override
  Map<String, _is.Include?> get includes => {
    'order': _order,
    'product': _product,
  };

  @override
  _is.Table<_is.UuidValue?> get table => OrderItem.t;
}

class OrderItemIncludeList extends _is.IncludeList {
  OrderItemIncludeList._({
    _is.WhereExpressionBuilder<OrderItemTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OrderItem.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => OrderItem.t;
}

class OrderItemRepository {
  const OrderItemRepository._();

  final attachRow = const OrderItemAttachRowRepository._();

  /// Returns a list of [OrderItem]s matching the given query parameters.
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
  Future<List<OrderItem>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OrderItemTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OrderItemTable>? orderBy,
    _is.OrderByListBuilder<OrderItemTable>? orderByList,
    _is.Transaction? transaction,
    OrderItemInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<OrderItem>(
      where: where?.call(OrderItem.t),
      orderBy: orderBy?.call(OrderItem.t),
      orderByList: orderByList?.call(OrderItem.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [OrderItem] matching the given query parameters.
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
  Future<OrderItem?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OrderItemTable>? where,
    int? offset,
    _is.OrderByBuilder<OrderItemTable>? orderBy,
    _is.OrderByListBuilder<OrderItemTable>? orderByList,
    _is.Transaction? transaction,
    OrderItemInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<OrderItem>(
      where: where?.call(OrderItem.t),
      orderBy: orderBy?.call(OrderItem.t),
      orderByList: orderByList?.call(OrderItem.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [OrderItem] by its [id] or null if no such row exists.
  Future<OrderItem?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    OrderItemInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<OrderItem>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [OrderItem]s in the list and returns the inserted rows.
  ///
  /// The returned [OrderItem]s will have their `id` fields set.
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
  Future<List<OrderItem>> insert(
    _is.DatabaseSession session,
    List<OrderItem> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<OrderItem>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [OrderItem] and returns the inserted row.
  ///
  /// The returned [OrderItem] will have its `id` field set.
  Future<OrderItem> insertRow(
    _is.DatabaseSession session,
    OrderItem row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<OrderItem>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [OrderItem]s in the list and returns the resulting rows.
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
  /// The returned [OrderItem]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OrderItem>> upsert(
    _is.DatabaseSession session,
    List<OrderItem> rows, {
    required _is.ColumnSelections<OrderItemTable> conflictColumns,
    _is.ColumnSelections<OrderItemTable>? updateColumns,
    _is.WhereExpressionBuilder<OrderItemTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<OrderItem>(
      rows,
      conflictColumns: conflictColumns(OrderItem.t),
      updateColumns: updateColumns?.call(OrderItem.t),
      updateWhere: updateWhere?.call(OrderItem.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [OrderItem] and returns the resulting row.
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
  /// The returned [OrderItem] will have its `id` field set.
  Future<OrderItem?> upsertRow(
    _is.DatabaseSession session,
    OrderItem row, {
    required _is.ColumnSelections<OrderItemTable> conflictColumns,
    _is.ColumnSelections<OrderItemTable>? updateColumns,
    _is.WhereExpressionBuilder<OrderItemTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<OrderItem>(
      row,
      conflictColumns: conflictColumns(OrderItem.t),
      updateColumns: updateColumns?.call(OrderItem.t),
      updateWhere: updateWhere?.call(OrderItem.t),
      transaction: transaction,
    );
  }

  /// Updates all [OrderItem]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OrderItem>> update(
    _is.DatabaseSession session,
    List<OrderItem> rows, {
    _is.ColumnSelections<OrderItemTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<OrderItem>(
      rows,
      columns: columns?.call(OrderItem.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [OrderItem]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OrderItem> updateRow(
    _is.DatabaseSession session,
    OrderItem row, {
    _is.ColumnSelections<OrderItemTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<OrderItem>(
      row,
      columns: columns?.call(OrderItem.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OrderItem] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<OrderItem?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<OrderItemUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<OrderItem>(
      id,
      columnValues: columnValues(OrderItem.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [OrderItem]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OrderItem>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<OrderItemUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<OrderItemTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OrderItemTable>? orderBy,
    _is.OrderByListBuilder<OrderItemTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<OrderItem>(
      columnValues: columnValues(OrderItem.t.updateTable),
      where: where(OrderItem.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OrderItem.t),
      orderByList: orderByList?.call(OrderItem.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [OrderItem]s in the list and returns the deleted rows.
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
  Future<List<OrderItem>> delete(
    _is.DatabaseSession session,
    List<OrderItem> rows, {
    _is.OrderByBuilder<OrderItemTable>? orderBy,
    _is.OrderByListBuilder<OrderItemTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<OrderItem>(
      rows,
      orderBy: orderBy?.call(OrderItem.t),
      orderByList: orderByList?.call(OrderItem.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [OrderItem].
  Future<OrderItem> deleteRow(
    _is.DatabaseSession session,
    OrderItem row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OrderItem>(
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
  Future<List<OrderItem>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OrderItemTable> where,
    _is.OrderByBuilder<OrderItemTable>? orderBy,
    _is.OrderByListBuilder<OrderItemTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<OrderItem>(
      where: where(OrderItem.t),
      orderBy: orderBy?.call(OrderItem.t),
      orderByList: orderByList?.call(OrderItem.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OrderItemTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<OrderItem>(
      where: where?.call(OrderItem.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [OrderItem] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OrderItemTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<OrderItem>(
      where: where(OrderItem.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class OrderItemAttachRowRepository {
  const OrderItemAttachRowRepository._();

  /// Creates a relation between the given [OrderItem] and [Order]
  /// by setting the [OrderItem]'s foreign key `orderId` to refer to the [Order].
  Future<void> order(
    _is.DatabaseSession session,
    OrderItem orderItem,
    _ij3i88ow.Order order, {
    _is.Transaction? transaction,
  }) async {
    if (orderItem.id == null) {
      throw ArgumentError.notNull('orderItem.id');
    }
    if (order.id == null) {
      throw ArgumentError.notNull('order.id');
    }

    var $orderItem = orderItem.copyWith(orderId: order.id);
    await session.db.updateRow<OrderItem>(
      $orderItem,
      columns: [OrderItem.t.orderId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [OrderItem] and [Product]
  /// by setting the [OrderItem]'s foreign key `productId` to refer to the [Product].
  Future<void> product(
    _is.DatabaseSession session,
    OrderItem orderItem,
    _iubf72bi.Product product, {
    _is.Transaction? transaction,
  }) async {
    if (orderItem.id == null) {
      throw ArgumentError.notNull('orderItem.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $orderItem = orderItem.copyWith(productId: product.id);
    await session.db.updateRow<OrderItem>(
      $orderItem,
      columns: [OrderItem.t.productId],
      transaction: transaction,
    );
  }
}
