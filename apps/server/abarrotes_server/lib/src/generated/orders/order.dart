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
import '../orders/fulfillment_type.dart' as _icim3nyh;
import '../orders/order_item.dart' as _iuzd2jqp;
import '../orders/order_status.dart' as _i2b33p21;
import '../users/user.dart' as _iqzoui01;

abstract class Order
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  Order._({
    this.id,
    _i2b33p21.OrderStatus? status,
    _icim3nyh.FulfillmentType? fulfillmentType,
    required this.totalCents,
    this.deliveryAddress,
    this.pickupCode,
    this.readyForPickupAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.customerId,
    this.customer,
    this.items,
  }) : status = status ?? _i2b33p21.OrderStatus.pendingConfirmation,
       fulfillmentType = fulfillmentType ?? _icim3nyh.FulfillmentType.delivery,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Order({
    _is.UuidValue? id,
    _i2b33p21.OrderStatus? status,
    _icim3nyh.FulfillmentType? fulfillmentType,
    required int totalCents,
    String? deliveryAddress,
    String? pickupCode,
    DateTime? readyForPickupAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    required _is.UuidValue customerId,
    _iqzoui01.User? customer,
    List<_iuzd2jqp.OrderItem>? items,
  }) = _OrderImpl;

  factory Order.fromJson(Map<String, dynamic> jsonSerialization) {
    return Order(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      status: jsonSerialization['status'] == null
          ? null
          : _i2b33p21.OrderStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      fulfillmentType: jsonSerialization['fulfillmentType'] == null
          ? null
          : _icim3nyh.FulfillmentType.fromJson(
              (jsonSerialization['fulfillmentType'] as String),
            ),
      totalCents: jsonSerialization['totalCents'] as int,
      deliveryAddress: jsonSerialization['deliveryAddress'] as String?,
      pickupCode: jsonSerialization['pickupCode'] as String?,
      readyForPickupAt: jsonSerialization['readyForPickupAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['readyForPickupAt'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      customerId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['customerId'],
      ),
      customer: jsonSerialization['customer'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['customer'],
            ),
      items: jsonSerialization['items'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_iuzd2jqp.OrderItem>>(
              jsonSerialization['items'],
            ),
    );
  }

  static final t = OrderTable();

  static const db = OrderRepository._();

  @override
  _is.UuidValue? id;

  _i2b33p21.OrderStatus status;

  /// A domicilio (por defecto, como todos los pedidos de antes) o recojo en
  /// tienda.
  _icim3nyh.FulfillmentType fulfillmentType;

  /// Total en céntimos.
  int totalCents;

  /// Solo a domicilio: el servidor la exige ahí; en recojo va null.
  String? deliveryAddress;

  /// Solo en recojo: 6 caracteres sin 0/O/1/I, que el cliente muestra en caja.
  /// Lo genera el servidor; único en toda la tabla.
  String? pickupCode;

  /// Cuándo quedó listo para recoger.
  DateTime? readyForPickupAt;

  DateTime createdAt;

  /// Serverpod no tiene @updatedAt: lo actualiza quien modifica el pedido.
  DateTime updatedAt;

  _is.UuidValue customerId;

  _iqzoui01.User? customer;

  List<_iuzd2jqp.OrderItem>? items;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Order]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Order copyWith({
    _is.UuidValue? id,
    _i2b33p21.OrderStatus? status,
    _icim3nyh.FulfillmentType? fulfillmentType,
    int? totalCents,
    String? deliveryAddress,
    String? pickupCode,
    DateTime? readyForPickupAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    _is.UuidValue? customerId,
    _iqzoui01.User? customer,
    List<_iuzd2jqp.OrderItem>? items,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Order',
      if (id != null) 'id': id?.toJson(),
      'status': status.toJson(),
      'fulfillmentType': fulfillmentType.toJson(),
      'totalCents': totalCents,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (pickupCode != null) 'pickupCode': pickupCode,
      if (readyForPickupAt != null)
        'readyForPickupAt': readyForPickupAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'customerId': customerId.toJson(),
      if (customer != null) 'customer': customer?.toJson(),
      if (items != null) 'items': items?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Order',
      if (id != null) 'id': id?.toJson(),
      'status': status.toJson(),
      'fulfillmentType': fulfillmentType.toJson(),
      'totalCents': totalCents,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (pickupCode != null) 'pickupCode': pickupCode,
      if (readyForPickupAt != null)
        'readyForPickupAt': readyForPickupAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'customerId': customerId.toJson(),
      if (customer != null) 'customer': customer?.toJsonForProtocol(),
      if (items != null)
        'items': items?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  static OrderInclude include({
    _iqzoui01.UserInclude? customer,
    _iuzd2jqp.OrderItemIncludeList? items,
  }) {
    return OrderInclude._(
      customer: customer,
      items: items,
    );
  }

  static OrderIncludeList includeList({
    _is.WhereExpressionBuilder<OrderTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OrderTable>? orderBy,
    _is.OrderByListBuilder<OrderTable>? orderByList,
    OrderInclude? include,
  }) {
    return OrderIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Order.t),
      orderByList: orderByList?.call(Order.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrderImpl extends Order {
  _OrderImpl({
    _is.UuidValue? id,
    _i2b33p21.OrderStatus? status,
    _icim3nyh.FulfillmentType? fulfillmentType,
    required int totalCents,
    String? deliveryAddress,
    String? pickupCode,
    DateTime? readyForPickupAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    required _is.UuidValue customerId,
    _iqzoui01.User? customer,
    List<_iuzd2jqp.OrderItem>? items,
  }) : super._(
         id: id,
         status: status,
         fulfillmentType: fulfillmentType,
         totalCents: totalCents,
         deliveryAddress: deliveryAddress,
         pickupCode: pickupCode,
         readyForPickupAt: readyForPickupAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
         customerId: customerId,
         customer: customer,
         items: items,
       );

  /// Returns a shallow copy of this [Order]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Order copyWith({
    Object? id = _Undefined,
    _i2b33p21.OrderStatus? status,
    _icim3nyh.FulfillmentType? fulfillmentType,
    int? totalCents,
    Object? deliveryAddress = _Undefined,
    Object? pickupCode = _Undefined,
    Object? readyForPickupAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    _is.UuidValue? customerId,
    Object? customer = _Undefined,
    Object? items = _Undefined,
  }) {
    return Order(
      id: id is _is.UuidValue? ? id : this.id,
      status: status ?? this.status,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      totalCents: totalCents ?? this.totalCents,
      deliveryAddress: deliveryAddress is String?
          ? deliveryAddress
          : this.deliveryAddress,
      pickupCode: pickupCode is String? ? pickupCode : this.pickupCode,
      readyForPickupAt: readyForPickupAt is DateTime?
          ? readyForPickupAt
          : this.readyForPickupAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerId: customerId ?? this.customerId,
      customer: customer is _iqzoui01.User?
          ? customer
          : this.customer?.copyWith(),
      items: items is List<_iuzd2jqp.OrderItem>?
          ? items
          : this.items?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class OrderUpdateTable extends _is.UpdateTable<OrderTable> {
  OrderUpdateTable(super.table);

  _is.ColumnValue<_i2b33p21.OrderStatus, _i2b33p21.OrderStatus> status(
    _i2b33p21.OrderStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<_icim3nyh.FulfillmentType, _icim3nyh.FulfillmentType>
  fulfillmentType(_icim3nyh.FulfillmentType value) => _is.ColumnValue(
    table.fulfillmentType,
    value,
  );

  _is.ColumnValue<int, int> totalCents(int value) => _is.ColumnValue(
    table.totalCents,
    value,
  );

  _is.ColumnValue<String, String> deliveryAddress(String? value) =>
      _is.ColumnValue(
        table.deliveryAddress,
        value,
      );

  _is.ColumnValue<String, String> pickupCode(String? value) => _is.ColumnValue(
    table.pickupCode,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> readyForPickupAt(DateTime? value) =>
      _is.ColumnValue(
        table.readyForPickupAt,
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

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> customerId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.customerId,
    value,
  );
}

class OrderTable extends _is.Table<_is.UuidValue?> {
  OrderTable({super.tableRelation}) : super(tableName: 'orders') {
    updateTable = OrderUpdateTable(this);
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    fulfillmentType = _is.ColumnEnum(
      'fulfillmentType',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    totalCents = _is.ColumnInt(
      'totalCents',
      this,
    );
    deliveryAddress = _is.ColumnString(
      'deliveryAddress',
      this,
    );
    pickupCode = _is.ColumnString(
      'pickupCode',
      this,
    );
    readyForPickupAt = _is.ColumnDateTime(
      'readyForPickupAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
    customerId = _is.ColumnUuid(
      'customerId',
      this,
    );
  }

  late final OrderUpdateTable updateTable;

  late final _is.ColumnEnum<_i2b33p21.OrderStatus> status;

  /// A domicilio (por defecto, como todos los pedidos de antes) o recojo en
  /// tienda.
  late final _is.ColumnEnum<_icim3nyh.FulfillmentType> fulfillmentType;

  /// Total en céntimos.
  late final _is.ColumnInt totalCents;

  /// Solo a domicilio: el servidor la exige ahí; en recojo va null.
  late final _is.ColumnString deliveryAddress;

  /// Solo en recojo: 6 caracteres sin 0/O/1/I, que el cliente muestra en caja.
  /// Lo genera el servidor; único en toda la tabla.
  late final _is.ColumnString pickupCode;

  /// Cuándo quedó listo para recoger.
  late final _is.ColumnDateTime readyForPickupAt;

  late final _is.ColumnDateTime createdAt;

  /// Serverpod no tiene @updatedAt: lo actualiza quien modifica el pedido.
  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnUuid customerId;

  _iqzoui01.UserTable? _customer;

  _iuzd2jqp.OrderItemTable? ___items;

  _is.ManyRelation<_iuzd2jqp.OrderItemTable>? _items;

  _iqzoui01.UserTable get customer {
    if (_customer != null) return _customer!;
    _customer = _is.createRelationTable(
      relationFieldName: 'customer',
      field: Order.t.customerId,
      foreignField: _iqzoui01.User.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iqzoui01.UserTable(tableRelation: foreignTableRelation),
    );
    return _customer!;
  }

  _iuzd2jqp.OrderItemTable get __items {
    if (___items != null) return ___items!;
    ___items = _is.createRelationTable(
      relationFieldName: '__items',
      field: Order.t.id,
      foreignField: _iuzd2jqp.OrderItem.t.orderId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iuzd2jqp.OrderItemTable(tableRelation: foreignTableRelation),
    );
    return ___items!;
  }

  _is.ManyRelation<_iuzd2jqp.OrderItemTable> get items {
    if (_items != null) return _items!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'items',
      field: Order.t.id,
      foreignField: _iuzd2jqp.OrderItem.t.orderId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iuzd2jqp.OrderItemTable(tableRelation: foreignTableRelation),
    );
    _items = _is.ManyRelation<_iuzd2jqp.OrderItemTable>(
      tableWithRelations: relationTable,
      table: _iuzd2jqp.OrderItemTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _items!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    status,
    fulfillmentType,
    totalCents,
    deliveryAddress,
    pickupCode,
    readyForPickupAt,
    createdAt,
    updatedAt,
    customerId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'customer') {
      return customer;
    }
    if (relationField == 'items') {
      return __items;
    }
    return null;
  }
}

class OrderInclude extends _is.IncludeObject {
  OrderInclude._({
    _iqzoui01.UserInclude? customer,
    _iuzd2jqp.OrderItemIncludeList? items,
  }) {
    _customer = customer;
    _items = items;
  }

  _iqzoui01.UserInclude? _customer;

  _iuzd2jqp.OrderItemIncludeList? _items;

  @override
  Map<String, _is.Include?> get includes => {
    'customer': _customer,
    'items': _items,
  };

  @override
  _is.Table<_is.UuidValue?> get table => Order.t;
}

class OrderIncludeList extends _is.IncludeList {
  OrderIncludeList._({
    _is.WhereExpressionBuilder<OrderTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Order.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => Order.t;
}

class OrderRepository {
  const OrderRepository._();

  final attach = const OrderAttachRepository._();

  final attachRow = const OrderAttachRowRepository._();

  /// Returns a list of [Order]s matching the given query parameters.
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
  Future<List<Order>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OrderTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OrderTable>? orderBy,
    _is.OrderByListBuilder<OrderTable>? orderByList,
    _is.Transaction? transaction,
    OrderInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Order>(
      where: where?.call(Order.t),
      orderBy: orderBy?.call(Order.t),
      orderByList: orderByList?.call(Order.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Order] matching the given query parameters.
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
  Future<Order?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OrderTable>? where,
    int? offset,
    _is.OrderByBuilder<OrderTable>? orderBy,
    _is.OrderByListBuilder<OrderTable>? orderByList,
    _is.Transaction? transaction,
    OrderInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Order>(
      where: where?.call(Order.t),
      orderBy: orderBy?.call(Order.t),
      orderByList: orderByList?.call(Order.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Order] by its [id] or null if no such row exists.
  Future<Order?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    OrderInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Order>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Order]s in the list and returns the inserted rows.
  ///
  /// The returned [Order]s will have their `id` fields set.
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
  Future<List<Order>> insert(
    _is.DatabaseSession session,
    List<Order> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Order>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Order] and returns the inserted row.
  ///
  /// The returned [Order] will have its `id` field set.
  Future<Order> insertRow(
    _is.DatabaseSession session,
    Order row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Order>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Order]s in the list and returns the resulting rows.
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
  /// The returned [Order]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Order>> upsert(
    _is.DatabaseSession session,
    List<Order> rows, {
    required _is.ColumnSelections<OrderTable> conflictColumns,
    _is.ColumnSelections<OrderTable>? updateColumns,
    _is.WhereExpressionBuilder<OrderTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Order>(
      rows,
      conflictColumns: conflictColumns(Order.t),
      updateColumns: updateColumns?.call(Order.t),
      updateWhere: updateWhere?.call(Order.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Order] and returns the resulting row.
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
  /// The returned [Order] will have its `id` field set.
  Future<Order?> upsertRow(
    _is.DatabaseSession session,
    Order row, {
    required _is.ColumnSelections<OrderTable> conflictColumns,
    _is.ColumnSelections<OrderTable>? updateColumns,
    _is.WhereExpressionBuilder<OrderTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Order>(
      row,
      conflictColumns: conflictColumns(Order.t),
      updateColumns: updateColumns?.call(Order.t),
      updateWhere: updateWhere?.call(Order.t),
      transaction: transaction,
    );
  }

  /// Updates all [Order]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Order>> update(
    _is.DatabaseSession session,
    List<Order> rows, {
    _is.ColumnSelections<OrderTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Order>(
      rows,
      columns: columns?.call(Order.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Order]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Order> updateRow(
    _is.DatabaseSession session,
    Order row, {
    _is.ColumnSelections<OrderTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Order>(
      row,
      columns: columns?.call(Order.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Order] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Order?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<OrderUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Order>(
      id,
      columnValues: columnValues(Order.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Order]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Order>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<OrderUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<OrderTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OrderTable>? orderBy,
    _is.OrderByListBuilder<OrderTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Order>(
      columnValues: columnValues(Order.t.updateTable),
      where: where(Order.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Order.t),
      orderByList: orderByList?.call(Order.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Order]s in the list and returns the deleted rows.
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
  Future<List<Order>> delete(
    _is.DatabaseSession session,
    List<Order> rows, {
    _is.OrderByBuilder<OrderTable>? orderBy,
    _is.OrderByListBuilder<OrderTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Order>(
      rows,
      orderBy: orderBy?.call(Order.t),
      orderByList: orderByList?.call(Order.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Order].
  Future<Order> deleteRow(
    _is.DatabaseSession session,
    Order row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Order>(
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
  Future<List<Order>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OrderTable> where,
    _is.OrderByBuilder<OrderTable>? orderBy,
    _is.OrderByListBuilder<OrderTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Order>(
      where: where(Order.t),
      orderBy: orderBy?.call(Order.t),
      orderByList: orderByList?.call(Order.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OrderTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Order>(
      where: where?.call(Order.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Order] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OrderTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Order>(
      where: where(Order.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class OrderAttachRepository {
  const OrderAttachRepository._();

  /// Creates a relation between this [Order] and the given [OrderItem]s
  /// by setting each [OrderItem]'s foreign key `orderId` to refer to this [Order].
  Future<void> items(
    _is.DatabaseSession session,
    Order order,
    List<_iuzd2jqp.OrderItem> orderItem, {
    _is.Transaction? transaction,
  }) async {
    if (orderItem.any((e) => e.id == null)) {
      throw ArgumentError.notNull('orderItem.id');
    }
    if (order.id == null) {
      throw ArgumentError.notNull('order.id');
    }

    var $orderItem = orderItem
        .map((e) => e.copyWith(orderId: order.id))
        .toList();
    await session.db.update<_iuzd2jqp.OrderItem>(
      $orderItem,
      columns: [_iuzd2jqp.OrderItem.t.orderId],
      transaction: transaction,
    );
  }
}

class OrderAttachRowRepository {
  const OrderAttachRowRepository._();

  /// Creates a relation between the given [Order] and [User]
  /// by setting the [Order]'s foreign key `customerId` to refer to the [User].
  Future<void> customer(
    _is.DatabaseSession session,
    Order order,
    _iqzoui01.User customer, {
    _is.Transaction? transaction,
  }) async {
    if (order.id == null) {
      throw ArgumentError.notNull('order.id');
    }
    if (customer.id == null) {
      throw ArgumentError.notNull('customer.id');
    }

    var $order = order.copyWith(customerId: customer.id);
    await session.db.updateRow<Order>(
      $order,
      columns: [Order.t.customerId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Order] and the given [OrderItem]
  /// by setting the [OrderItem]'s foreign key `orderId` to refer to this [Order].
  Future<void> items(
    _is.DatabaseSession session,
    Order order,
    _iuzd2jqp.OrderItem orderItem, {
    _is.Transaction? transaction,
  }) async {
    if (orderItem.id == null) {
      throw ArgumentError.notNull('orderItem.id');
    }
    if (order.id == null) {
      throw ArgumentError.notNull('order.id');
    }

    var $orderItem = orderItem.copyWith(orderId: order.id);
    await session.db.updateRow<_iuzd2jqp.OrderItem>(
      $orderItem,
      columns: [_iuzd2jqp.OrderItem.t.orderId],
      transaction: transaction,
    );
  }
}
