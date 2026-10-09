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
import '../inventory/movement_type.dart' as _iwxdrlkj;
import '../products/product.dart' as _iubf72bi;
import '../users/user.dart' as _iqzoui01;

abstract class InventoryMovement
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  InventoryMovement._({
    this.id,
    required this.type,
    required this.quantity,
    this.reason,
    DateTime? createdAt,
    required this.productId,
    this.product,
    required this.userId,
    this.user,
  }) : createdAt = createdAt ?? DateTime.now();

  factory InventoryMovement({
    _is.UuidValue? id,
    required _iwxdrlkj.MovementType type,
    required int quantity,
    String? reason,
    DateTime? createdAt,
    required _is.UuidValue productId,
    _iubf72bi.Product? product,
    required _is.UuidValue userId,
    _iqzoui01.User? user,
  }) = _InventoryMovementImpl;

  factory InventoryMovement.fromJson(Map<String, dynamic> jsonSerialization) {
    return InventoryMovement(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      type: _iwxdrlkj.MovementType.fromJson(
        (jsonSerialization['type'] as String),
      ),
      quantity: jsonSerialization['quantity'] as int,
      reason: jsonSerialization['reason'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      productId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['productId'],
      ),
      product: jsonSerialization['product'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_iubf72bi.Product>(
              jsonSerialization['product'],
            ),
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      user: jsonSerialization['user'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['user'],
            ),
    );
  }

  static final t = InventoryMovementTable();

  static const db = InventoryMovementRepository._();

  @override
  _is.UuidValue? id;

  _iwxdrlkj.MovementType type;

  int quantity;

  String? reason;

  DateTime createdAt;

  _is.UuidValue productId;

  _iubf72bi.Product? product;

  _is.UuidValue userId;

  /// Quién lo originó: el cliente que hizo el pedido o el staff que lo canceló.
  _iqzoui01.User? user;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [InventoryMovement]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  InventoryMovement copyWith({
    _is.UuidValue? id,
    _iwxdrlkj.MovementType? type,
    int? quantity,
    String? reason,
    DateTime? createdAt,
    _is.UuidValue? productId,
    _iubf72bi.Product? product,
    _is.UuidValue? userId,
    _iqzoui01.User? user,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InventoryMovement',
      if (id != null) 'id': id?.toJson(),
      'type': type.toJson(),
      'quantity': quantity,
      if (reason != null) 'reason': reason,
      'createdAt': createdAt.toJson(),
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJson(),
      'userId': userId.toJson(),
      if (user != null) 'user': user?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InventoryMovement',
      if (id != null) 'id': id?.toJson(),
      'type': type.toJson(),
      'quantity': quantity,
      if (reason != null) 'reason': reason,
      'createdAt': createdAt.toJson(),
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJsonForProtocol(),
      'userId': userId.toJson(),
      if (user != null) 'user': user?.toJsonForProtocol(),
    };
  }

  static InventoryMovementInclude include({
    _iubf72bi.ProductInclude? product,
    _iqzoui01.UserInclude? user,
  }) {
    return InventoryMovementInclude._(
      product: product,
      user: user,
    );
  }

  static InventoryMovementIncludeList includeList({
    _is.WhereExpressionBuilder<InventoryMovementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InventoryMovementTable>? orderBy,
    _is.OrderByListBuilder<InventoryMovementTable>? orderByList,
    InventoryMovementInclude? include,
  }) {
    return InventoryMovementIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InventoryMovement.t),
      orderByList: orderByList?.call(InventoryMovement.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _InventoryMovementImpl extends InventoryMovement {
  _InventoryMovementImpl({
    _is.UuidValue? id,
    required _iwxdrlkj.MovementType type,
    required int quantity,
    String? reason,
    DateTime? createdAt,
    required _is.UuidValue productId,
    _iubf72bi.Product? product,
    required _is.UuidValue userId,
    _iqzoui01.User? user,
  }) : super._(
         id: id,
         type: type,
         quantity: quantity,
         reason: reason,
         createdAt: createdAt,
         productId: productId,
         product: product,
         userId: userId,
         user: user,
       );

  /// Returns a shallow copy of this [InventoryMovement]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  InventoryMovement copyWith({
    Object? id = _Undefined,
    _iwxdrlkj.MovementType? type,
    int? quantity,
    Object? reason = _Undefined,
    DateTime? createdAt,
    _is.UuidValue? productId,
    Object? product = _Undefined,
    _is.UuidValue? userId,
    Object? user = _Undefined,
  }) {
    return InventoryMovement(
      id: id is _is.UuidValue? ? id : this.id,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason is String? ? reason : this.reason,
      createdAt: createdAt ?? this.createdAt,
      productId: productId ?? this.productId,
      product: product is _iubf72bi.Product?
          ? product
          : this.product?.copyWith(),
      userId: userId ?? this.userId,
      user: user is _iqzoui01.User? ? user : this.user?.copyWith(),
    );
  }
}

class InventoryMovementUpdateTable
    extends _is.UpdateTable<InventoryMovementTable> {
  InventoryMovementUpdateTable(super.table);

  _is.ColumnValue<_iwxdrlkj.MovementType, _iwxdrlkj.MovementType> type(
    _iwxdrlkj.MovementType value,
  ) => _is.ColumnValue(
    table.type,
    value,
  );

  _is.ColumnValue<int, int> quantity(int value) => _is.ColumnValue(
    table.quantity,
    value,
  );

  _is.ColumnValue<String, String> reason(String? value) => _is.ColumnValue(
    table.reason,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> productId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.productId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );
}

class InventoryMovementTable extends _is.Table<_is.UuidValue?> {
  InventoryMovementTable({super.tableRelation})
    : super(tableName: 'inventory_movements') {
    updateTable = InventoryMovementUpdateTable(this);
    type = _is.ColumnEnum(
      'type',
      this,
      _is.EnumSerialization.byName,
    );
    quantity = _is.ColumnInt(
      'quantity',
      this,
    );
    reason = _is.ColumnString(
      'reason',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    productId = _is.ColumnUuid(
      'productId',
      this,
    );
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
  }

  late final InventoryMovementUpdateTable updateTable;

  late final _is.ColumnEnum<_iwxdrlkj.MovementType> type;

  late final _is.ColumnInt quantity;

  late final _is.ColumnString reason;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnUuid productId;

  _iubf72bi.ProductTable? _product;

  late final _is.ColumnUuid userId;

  /// Quién lo originó: el cliente que hizo el pedido o el staff que lo canceló.
  _iqzoui01.UserTable? _user;

  _iubf72bi.ProductTable get product {
    if (_product != null) return _product!;
    _product = _is.createRelationTable(
      relationFieldName: 'product',
      field: InventoryMovement.t.productId,
      foreignField: _iubf72bi.Product.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iubf72bi.ProductTable(tableRelation: foreignTableRelation),
    );
    return _product!;
  }

  _iqzoui01.UserTable get user {
    if (_user != null) return _user!;
    _user = _is.createRelationTable(
      relationFieldName: 'user',
      field: InventoryMovement.t.userId,
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
    type,
    quantity,
    reason,
    createdAt,
    productId,
    userId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'product') {
      return product;
    }
    if (relationField == 'user') {
      return user;
    }
    return null;
  }
}

class InventoryMovementInclude extends _is.IncludeObject {
  InventoryMovementInclude._({
    _iubf72bi.ProductInclude? product,
    _iqzoui01.UserInclude? user,
  }) {
    _product = product;
    _user = user;
  }

  _iubf72bi.ProductInclude? _product;

  _iqzoui01.UserInclude? _user;

  @override
  Map<String, _is.Include?> get includes => {
    'product': _product,
    'user': _user,
  };

  @override
  _is.Table<_is.UuidValue?> get table => InventoryMovement.t;
}

class InventoryMovementIncludeList extends _is.IncludeList {
  InventoryMovementIncludeList._({
    _is.WhereExpressionBuilder<InventoryMovementTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(InventoryMovement.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => InventoryMovement.t;
}

class InventoryMovementRepository {
  const InventoryMovementRepository._();

  final attachRow = const InventoryMovementAttachRowRepository._();

  /// Returns a list of [InventoryMovement]s matching the given query parameters.
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
  Future<List<InventoryMovement>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InventoryMovementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InventoryMovementTable>? orderBy,
    _is.OrderByListBuilder<InventoryMovementTable>? orderByList,
    _is.Transaction? transaction,
    InventoryMovementInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<InventoryMovement>(
      where: where?.call(InventoryMovement.t),
      orderBy: orderBy?.call(InventoryMovement.t),
      orderByList: orderByList?.call(InventoryMovement.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [InventoryMovement] matching the given query parameters.
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
  Future<InventoryMovement?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InventoryMovementTable>? where,
    int? offset,
    _is.OrderByBuilder<InventoryMovementTable>? orderBy,
    _is.OrderByListBuilder<InventoryMovementTable>? orderByList,
    _is.Transaction? transaction,
    InventoryMovementInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<InventoryMovement>(
      where: where?.call(InventoryMovement.t),
      orderBy: orderBy?.call(InventoryMovement.t),
      orderByList: orderByList?.call(InventoryMovement.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [InventoryMovement] by its [id] or null if no such row exists.
  Future<InventoryMovement?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    InventoryMovementInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<InventoryMovement>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [InventoryMovement]s in the list and returns the inserted rows.
  ///
  /// The returned [InventoryMovement]s will have their `id` fields set.
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
  Future<List<InventoryMovement>> insert(
    _is.DatabaseSession session,
    List<InventoryMovement> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<InventoryMovement>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [InventoryMovement] and returns the inserted row.
  ///
  /// The returned [InventoryMovement] will have its `id` field set.
  Future<InventoryMovement> insertRow(
    _is.DatabaseSession session,
    InventoryMovement row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<InventoryMovement>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [InventoryMovement]s in the list and returns the resulting rows.
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
  /// The returned [InventoryMovement]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InventoryMovement>> upsert(
    _is.DatabaseSession session,
    List<InventoryMovement> rows, {
    required _is.ColumnSelections<InventoryMovementTable> conflictColumns,
    _is.ColumnSelections<InventoryMovementTable>? updateColumns,
    _is.WhereExpressionBuilder<InventoryMovementTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<InventoryMovement>(
      rows,
      conflictColumns: conflictColumns(InventoryMovement.t),
      updateColumns: updateColumns?.call(InventoryMovement.t),
      updateWhere: updateWhere?.call(InventoryMovement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [InventoryMovement] and returns the resulting row.
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
  /// The returned [InventoryMovement] will have its `id` field set.
  Future<InventoryMovement?> upsertRow(
    _is.DatabaseSession session,
    InventoryMovement row, {
    required _is.ColumnSelections<InventoryMovementTable> conflictColumns,
    _is.ColumnSelections<InventoryMovementTable>? updateColumns,
    _is.WhereExpressionBuilder<InventoryMovementTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<InventoryMovement>(
      row,
      conflictColumns: conflictColumns(InventoryMovement.t),
      updateColumns: updateColumns?.call(InventoryMovement.t),
      updateWhere: updateWhere?.call(InventoryMovement.t),
      transaction: transaction,
    );
  }

  /// Updates all [InventoryMovement]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InventoryMovement>> update(
    _is.DatabaseSession session,
    List<InventoryMovement> rows, {
    _is.ColumnSelections<InventoryMovementTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<InventoryMovement>(
      rows,
      columns: columns?.call(InventoryMovement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [InventoryMovement]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<InventoryMovement> updateRow(
    _is.DatabaseSession session,
    InventoryMovement row, {
    _is.ColumnSelections<InventoryMovementTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<InventoryMovement>(
      row,
      columns: columns?.call(InventoryMovement.t),
      transaction: transaction,
    );
  }

  /// Updates a single [InventoryMovement] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<InventoryMovement?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<InventoryMovementUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<InventoryMovement>(
      id,
      columnValues: columnValues(InventoryMovement.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [InventoryMovement]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InventoryMovement>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<InventoryMovementUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<InventoryMovementTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InventoryMovementTable>? orderBy,
    _is.OrderByListBuilder<InventoryMovementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<InventoryMovement>(
      columnValues: columnValues(InventoryMovement.t.updateTable),
      where: where(InventoryMovement.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InventoryMovement.t),
      orderByList: orderByList?.call(InventoryMovement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [InventoryMovement]s in the list and returns the deleted rows.
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
  Future<List<InventoryMovement>> delete(
    _is.DatabaseSession session,
    List<InventoryMovement> rows, {
    _is.OrderByBuilder<InventoryMovementTable>? orderBy,
    _is.OrderByListBuilder<InventoryMovementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<InventoryMovement>(
      rows,
      orderBy: orderBy?.call(InventoryMovement.t),
      orderByList: orderByList?.call(InventoryMovement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [InventoryMovement].
  Future<InventoryMovement> deleteRow(
    _is.DatabaseSession session,
    InventoryMovement row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<InventoryMovement>(
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
  Future<List<InventoryMovement>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<InventoryMovementTable> where,
    _is.OrderByBuilder<InventoryMovementTable>? orderBy,
    _is.OrderByListBuilder<InventoryMovementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<InventoryMovement>(
      where: where(InventoryMovement.t),
      orderBy: orderBy?.call(InventoryMovement.t),
      orderByList: orderByList?.call(InventoryMovement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InventoryMovementTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<InventoryMovement>(
      where: where?.call(InventoryMovement.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [InventoryMovement] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<InventoryMovementTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<InventoryMovement>(
      where: where(InventoryMovement.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class InventoryMovementAttachRowRepository {
  const InventoryMovementAttachRowRepository._();

  /// Creates a relation between the given [InventoryMovement] and [Product]
  /// by setting the [InventoryMovement]'s foreign key `productId` to refer to the [Product].
  Future<void> product(
    _is.DatabaseSession session,
    InventoryMovement inventoryMovement,
    _iubf72bi.Product product, {
    _is.Transaction? transaction,
  }) async {
    if (inventoryMovement.id == null) {
      throw ArgumentError.notNull('inventoryMovement.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $inventoryMovement = inventoryMovement.copyWith(productId: product.id);
    await session.db.updateRow<InventoryMovement>(
      $inventoryMovement,
      columns: [InventoryMovement.t.productId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [InventoryMovement] and [User]
  /// by setting the [InventoryMovement]'s foreign key `userId` to refer to the [User].
  Future<void> user(
    _is.DatabaseSession session,
    InventoryMovement inventoryMovement,
    _iqzoui01.User user, {
    _is.Transaction? transaction,
  }) async {
    if (inventoryMovement.id == null) {
      throw ArgumentError.notNull('inventoryMovement.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $inventoryMovement = inventoryMovement.copyWith(userId: user.id);
    await session.db.updateRow<InventoryMovement>(
      $inventoryMovement,
      columns: [InventoryMovement.t.userId],
      transaction: transaction,
    );
  }
}
