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
import '../products/product.dart' as _iubf72bi;

/// Precio especial de un producto por un periodo. Las fechas son días de la
/// tienda (America/Lima): [inicio 00:00, día siguiente al fin 00:00).
abstract class Promotion
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  Promotion._({
    this.id,
    required this.promoPriceCents,
    required this.startDate,
    required this.endDate,
    bool? active,
    required this.productId,
    this.product,
  }) : active = active ?? true;

  factory Promotion({
    _is.UuidValue? id,
    required int promoPriceCents,
    required DateTime startDate,
    required DateTime endDate,
    bool? active,
    required _is.UuidValue productId,
    _iubf72bi.Product? product,
  }) = _PromotionImpl;

  factory Promotion.fromJson(Map<String, dynamic> jsonSerialization) {
    return Promotion(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      promoPriceCents: jsonSerialization['promoPriceCents'] as int,
      startDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['startDate'],
      ),
      endDate: _is.DateTimeJsonExtension.fromJson(jsonSerialization['endDate']),
      active: jsonSerialization['active'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['active']),
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

  static final t = PromotionTable();

  static const db = PromotionRepository._();

  @override
  _is.UuidValue? id;

  int promoPriceCents;

  DateTime startDate;

  DateTime endDate;

  bool active;

  _is.UuidValue productId;

  _iubf72bi.Product? product;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Promotion]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Promotion copyWith({
    _is.UuidValue? id,
    int? promoPriceCents,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    _is.UuidValue? productId,
    _iubf72bi.Product? product,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Promotion',
      if (id != null) 'id': id?.toJson(),
      'promoPriceCents': promoPriceCents,
      'startDate': startDate.toJson(),
      'endDate': endDate.toJson(),
      'active': active,
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Promotion',
      if (id != null) 'id': id?.toJson(),
      'promoPriceCents': promoPriceCents,
      'startDate': startDate.toJson(),
      'endDate': endDate.toJson(),
      'active': active,
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJsonForProtocol(),
    };
  }

  static PromotionInclude include({_iubf72bi.ProductInclude? product}) {
    return PromotionInclude._(product: product);
  }

  static PromotionIncludeList includeList({
    _is.WhereExpressionBuilder<PromotionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromotionTable>? orderBy,
    _is.OrderByListBuilder<PromotionTable>? orderByList,
    PromotionInclude? include,
  }) {
    return PromotionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Promotion.t),
      orderByList: orderByList?.call(Promotion.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromotionImpl extends Promotion {
  _PromotionImpl({
    _is.UuidValue? id,
    required int promoPriceCents,
    required DateTime startDate,
    required DateTime endDate,
    bool? active,
    required _is.UuidValue productId,
    _iubf72bi.Product? product,
  }) : super._(
         id: id,
         promoPriceCents: promoPriceCents,
         startDate: startDate,
         endDate: endDate,
         active: active,
         productId: productId,
         product: product,
       );

  /// Returns a shallow copy of this [Promotion]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Promotion copyWith({
    Object? id = _Undefined,
    int? promoPriceCents,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    _is.UuidValue? productId,
    Object? product = _Undefined,
  }) {
    return Promotion(
      id: id is _is.UuidValue? ? id : this.id,
      promoPriceCents: promoPriceCents ?? this.promoPriceCents,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      productId: productId ?? this.productId,
      product: product is _iubf72bi.Product?
          ? product
          : this.product?.copyWith(),
    );
  }
}

class PromotionUpdateTable extends _is.UpdateTable<PromotionTable> {
  PromotionUpdateTable(super.table);

  _is.ColumnValue<int, int> promoPriceCents(int value) => _is.ColumnValue(
    table.promoPriceCents,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> startDate(DateTime value) =>
      _is.ColumnValue(
        table.startDate,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> endDate(DateTime value) =>
      _is.ColumnValue(
        table.endDate,
        value,
      );

  _is.ColumnValue<bool, bool> active(bool value) => _is.ColumnValue(
    table.active,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> productId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.productId,
    value,
  );
}

class PromotionTable extends _is.Table<_is.UuidValue?> {
  PromotionTable({super.tableRelation}) : super(tableName: 'promotions') {
    updateTable = PromotionUpdateTable(this);
    promoPriceCents = _is.ColumnInt(
      'promoPriceCents',
      this,
    );
    startDate = _is.ColumnDateTime(
      'startDate',
      this,
    );
    endDate = _is.ColumnDateTime(
      'endDate',
      this,
    );
    active = _is.ColumnBool(
      'active',
      this,
      hasDefault: true,
    );
    productId = _is.ColumnUuid(
      'productId',
      this,
    );
  }

  late final PromotionUpdateTable updateTable;

  late final _is.ColumnInt promoPriceCents;

  late final _is.ColumnDateTime startDate;

  late final _is.ColumnDateTime endDate;

  late final _is.ColumnBool active;

  late final _is.ColumnUuid productId;

  _iubf72bi.ProductTable? _product;

  _iubf72bi.ProductTable get product {
    if (_product != null) return _product!;
    _product = _is.createRelationTable(
      relationFieldName: 'product',
      field: Promotion.t.productId,
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
    promoPriceCents,
    startDate,
    endDate,
    active,
    productId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'product') {
      return product;
    }
    return null;
  }
}

class PromotionInclude extends _is.IncludeObject {
  PromotionInclude._({_iubf72bi.ProductInclude? product}) {
    _product = product;
  }

  _iubf72bi.ProductInclude? _product;

  @override
  Map<String, _is.Include?> get includes => {'product': _product};

  @override
  _is.Table<_is.UuidValue?> get table => Promotion.t;
}

class PromotionIncludeList extends _is.IncludeList {
  PromotionIncludeList._({
    _is.WhereExpressionBuilder<PromotionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Promotion.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => Promotion.t;
}

class PromotionRepository {
  const PromotionRepository._();

  final attachRow = const PromotionAttachRowRepository._();

  /// Returns a list of [Promotion]s matching the given query parameters.
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
  Future<List<Promotion>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromotionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromotionTable>? orderBy,
    _is.OrderByListBuilder<PromotionTable>? orderByList,
    _is.Transaction? transaction,
    PromotionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Promotion>(
      where: where?.call(Promotion.t),
      orderBy: orderBy?.call(Promotion.t),
      orderByList: orderByList?.call(Promotion.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Promotion] matching the given query parameters.
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
  Future<Promotion?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromotionTable>? where,
    int? offset,
    _is.OrderByBuilder<PromotionTable>? orderBy,
    _is.OrderByListBuilder<PromotionTable>? orderByList,
    _is.Transaction? transaction,
    PromotionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Promotion>(
      where: where?.call(Promotion.t),
      orderBy: orderBy?.call(Promotion.t),
      orderByList: orderByList?.call(Promotion.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Promotion] by its [id] or null if no such row exists.
  Future<Promotion?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    PromotionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Promotion>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Promotion]s in the list and returns the inserted rows.
  ///
  /// The returned [Promotion]s will have their `id` fields set.
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
  Future<List<Promotion>> insert(
    _is.DatabaseSession session,
    List<Promotion> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Promotion>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Promotion] and returns the inserted row.
  ///
  /// The returned [Promotion] will have its `id` field set.
  Future<Promotion> insertRow(
    _is.DatabaseSession session,
    Promotion row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Promotion>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Promotion]s in the list and returns the resulting rows.
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
  /// The returned [Promotion]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Promotion>> upsert(
    _is.DatabaseSession session,
    List<Promotion> rows, {
    required _is.ColumnSelections<PromotionTable> conflictColumns,
    _is.ColumnSelections<PromotionTable>? updateColumns,
    _is.WhereExpressionBuilder<PromotionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Promotion>(
      rows,
      conflictColumns: conflictColumns(Promotion.t),
      updateColumns: updateColumns?.call(Promotion.t),
      updateWhere: updateWhere?.call(Promotion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Promotion] and returns the resulting row.
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
  /// The returned [Promotion] will have its `id` field set.
  Future<Promotion?> upsertRow(
    _is.DatabaseSession session,
    Promotion row, {
    required _is.ColumnSelections<PromotionTable> conflictColumns,
    _is.ColumnSelections<PromotionTable>? updateColumns,
    _is.WhereExpressionBuilder<PromotionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Promotion>(
      row,
      conflictColumns: conflictColumns(Promotion.t),
      updateColumns: updateColumns?.call(Promotion.t),
      updateWhere: updateWhere?.call(Promotion.t),
      transaction: transaction,
    );
  }

  /// Updates all [Promotion]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Promotion>> update(
    _is.DatabaseSession session,
    List<Promotion> rows, {
    _is.ColumnSelections<PromotionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Promotion>(
      rows,
      columns: columns?.call(Promotion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Promotion]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Promotion> updateRow(
    _is.DatabaseSession session,
    Promotion row, {
    _is.ColumnSelections<PromotionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Promotion>(
      row,
      columns: columns?.call(Promotion.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Promotion] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Promotion?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<PromotionUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Promotion>(
      id,
      columnValues: columnValues(Promotion.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Promotion]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Promotion>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PromotionUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PromotionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromotionTable>? orderBy,
    _is.OrderByListBuilder<PromotionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Promotion>(
      columnValues: columnValues(Promotion.t.updateTable),
      where: where(Promotion.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Promotion.t),
      orderByList: orderByList?.call(Promotion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Promotion]s in the list and returns the deleted rows.
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
  Future<List<Promotion>> delete(
    _is.DatabaseSession session,
    List<Promotion> rows, {
    _is.OrderByBuilder<PromotionTable>? orderBy,
    _is.OrderByListBuilder<PromotionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Promotion>(
      rows,
      orderBy: orderBy?.call(Promotion.t),
      orderByList: orderByList?.call(Promotion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Promotion].
  Future<Promotion> deleteRow(
    _is.DatabaseSession session,
    Promotion row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Promotion>(
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
  Future<List<Promotion>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PromotionTable> where,
    _is.OrderByBuilder<PromotionTable>? orderBy,
    _is.OrderByListBuilder<PromotionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Promotion>(
      where: where(Promotion.t),
      orderBy: orderBy?.call(Promotion.t),
      orderByList: orderByList?.call(Promotion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromotionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Promotion>(
      where: where?.call(Promotion.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Promotion] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PromotionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Promotion>(
      where: where(Promotion.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PromotionAttachRowRepository {
  const PromotionAttachRowRepository._();

  /// Creates a relation between the given [Promotion] and [Product]
  /// by setting the [Promotion]'s foreign key `productId` to refer to the [Product].
  Future<void> product(
    _is.DatabaseSession session,
    Promotion promotion,
    _iubf72bi.Product product, {
    _is.Transaction? transaction,
  }) async {
    if (promotion.id == null) {
      throw ArgumentError.notNull('promotion.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $promotion = promotion.copyWith(productId: product.id);
    await session.db.updateRow<Promotion>(
      $promotion,
      columns: [Promotion.t.productId],
      transaction: transaction,
    );
  }
}
