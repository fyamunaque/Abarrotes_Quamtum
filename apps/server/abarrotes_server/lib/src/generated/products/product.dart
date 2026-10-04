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
import '../categories/category.dart' as _igagfyw0;
import '../inventory/inventory_movement.dart' as _i4yp9mtd;
import '../orders/order_item.dart' as _iuzd2jqp;
import '../promotions/promotion.dart' as _irk6gnzq;

/// Producto del catálogo. Los montos se guardan en céntimos enteros.
abstract class Product
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  Product._({
    this.id,
    required this.name,
    this.description,
    required this.sku,
    required this.priceCents,
    this.imageUrl,
    bool? active,
    int? currentStock,
    int? minStock,
    this.expirationDate,
    DateTime? createdAt,
    required this.categoryId,
    this.category,
    this.orderItems,
    this.inventoryMovements,
    this.promotions,
  }) : active = active ?? true,
       currentStock = currentStock ?? 0,
       minStock = minStock ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory Product({
    _is.UuidValue? id,
    required String name,
    String? description,
    required String sku,
    required int priceCents,
    String? imageUrl,
    bool? active,
    int? currentStock,
    int? minStock,
    DateTime? expirationDate,
    DateTime? createdAt,
    required _is.UuidValue categoryId,
    _igagfyw0.Category? category,
    List<_iuzd2jqp.OrderItem>? orderItems,
    List<_i4yp9mtd.InventoryMovement>? inventoryMovements,
    List<_irk6gnzq.Promotion>? promotions,
  }) = _ProductImpl;

  factory Product.fromJson(Map<String, dynamic> jsonSerialization) {
    return Product(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      sku: jsonSerialization['sku'] as String,
      priceCents: jsonSerialization['priceCents'] as int,
      imageUrl: jsonSerialization['imageUrl'] as String?,
      active: jsonSerialization['active'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['active']),
      currentStock: jsonSerialization['currentStock'] as int?,
      minStock: jsonSerialization['minStock'] as int?,
      expirationDate: jsonSerialization['expirationDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['expirationDate'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      categoryId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['categoryId'],
      ),
      category: jsonSerialization['category'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_igagfyw0.Category>(
              jsonSerialization['category'],
            ),
      orderItems: jsonSerialization['orderItems'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_iuzd2jqp.OrderItem>>(
              jsonSerialization['orderItems'],
            ),
      inventoryMovements: jsonSerialization['inventoryMovements'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_i4yp9mtd.InventoryMovement>>(
              jsonSerialization['inventoryMovements'],
            ),
      promotions: jsonSerialization['promotions'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_irk6gnzq.Promotion>>(
              jsonSerialization['promotions'],
            ),
    );
  }

  static final t = ProductTable();

  static const db = ProductRepository._();

  @override
  _is.UuidValue? id;

  String name;

  String? description;

  String sku;

  /// Precio en céntimos: 450 = S/ 4.50.
  int priceCents;

  String? imageUrl;

  bool active;

  int currentStock;

  int minStock;

  DateTime? expirationDate;

  DateTime createdAt;

  _is.UuidValue categoryId;

  _igagfyw0.Category? category;

  List<_iuzd2jqp.OrderItem>? orderItems;

  List<_i4yp9mtd.InventoryMovement>? inventoryMovements;

  List<_irk6gnzq.Promotion>? promotions;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Product]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Product copyWith({
    _is.UuidValue? id,
    String? name,
    String? description,
    String? sku,
    int? priceCents,
    String? imageUrl,
    bool? active,
    int? currentStock,
    int? minStock,
    DateTime? expirationDate,
    DateTime? createdAt,
    _is.UuidValue? categoryId,
    _igagfyw0.Category? category,
    List<_iuzd2jqp.OrderItem>? orderItems,
    List<_i4yp9mtd.InventoryMovement>? inventoryMovements,
    List<_irk6gnzq.Promotion>? promotions,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Product',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      if (description != null) 'description': description,
      'sku': sku,
      'priceCents': priceCents,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'active': active,
      'currentStock': currentStock,
      'minStock': minStock,
      if (expirationDate != null) 'expirationDate': expirationDate?.toJson(),
      'createdAt': createdAt.toJson(),
      'categoryId': categoryId.toJson(),
      if (category != null) 'category': category?.toJson(),
      if (orderItems != null)
        'orderItems': orderItems?.toJson(valueToJson: (v) => v.toJson()),
      if (inventoryMovements != null)
        'inventoryMovements': inventoryMovements?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      if (promotions != null)
        'promotions': promotions?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Product',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      if (description != null) 'description': description,
      'sku': sku,
      'priceCents': priceCents,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'active': active,
      'currentStock': currentStock,
      'minStock': minStock,
      if (expirationDate != null) 'expirationDate': expirationDate?.toJson(),
      'createdAt': createdAt.toJson(),
      'categoryId': categoryId.toJson(),
      if (category != null) 'category': category?.toJsonForProtocol(),
      if (orderItems != null)
        'orderItems': orderItems?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (inventoryMovements != null)
        'inventoryMovements': inventoryMovements?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (promotions != null)
        'promotions': promotions?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
    };
  }

  static ProductInclude include({
    _igagfyw0.CategoryInclude? category,
    _iuzd2jqp.OrderItemIncludeList? orderItems,
    _i4yp9mtd.InventoryMovementIncludeList? inventoryMovements,
    _irk6gnzq.PromotionIncludeList? promotions,
  }) {
    return ProductInclude._(
      category: category,
      orderItems: orderItems,
      inventoryMovements: inventoryMovements,
      promotions: promotions,
    );
  }

  static ProductIncludeList includeList({
    _is.WhereExpressionBuilder<ProductTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProductTable>? orderBy,
    _is.OrderByListBuilder<ProductTable>? orderByList,
    ProductInclude? include,
  }) {
    return ProductIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Product.t),
      orderByList: orderByList?.call(Product.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProductImpl extends Product {
  _ProductImpl({
    _is.UuidValue? id,
    required String name,
    String? description,
    required String sku,
    required int priceCents,
    String? imageUrl,
    bool? active,
    int? currentStock,
    int? minStock,
    DateTime? expirationDate,
    DateTime? createdAt,
    required _is.UuidValue categoryId,
    _igagfyw0.Category? category,
    List<_iuzd2jqp.OrderItem>? orderItems,
    List<_i4yp9mtd.InventoryMovement>? inventoryMovements,
    List<_irk6gnzq.Promotion>? promotions,
  }) : super._(
         id: id,
         name: name,
         description: description,
         sku: sku,
         priceCents: priceCents,
         imageUrl: imageUrl,
         active: active,
         currentStock: currentStock,
         minStock: minStock,
         expirationDate: expirationDate,
         createdAt: createdAt,
         categoryId: categoryId,
         category: category,
         orderItems: orderItems,
         inventoryMovements: inventoryMovements,
         promotions: promotions,
       );

  /// Returns a shallow copy of this [Product]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Product copyWith({
    Object? id = _Undefined,
    String? name,
    Object? description = _Undefined,
    String? sku,
    int? priceCents,
    Object? imageUrl = _Undefined,
    bool? active,
    int? currentStock,
    int? minStock,
    Object? expirationDate = _Undefined,
    DateTime? createdAt,
    _is.UuidValue? categoryId,
    Object? category = _Undefined,
    Object? orderItems = _Undefined,
    Object? inventoryMovements = _Undefined,
    Object? promotions = _Undefined,
  }) {
    return Product(
      id: id is _is.UuidValue? ? id : this.id,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      sku: sku ?? this.sku,
      priceCents: priceCents ?? this.priceCents,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
      active: active ?? this.active,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      expirationDate: expirationDate is DateTime?
          ? expirationDate
          : this.expirationDate,
      createdAt: createdAt ?? this.createdAt,
      categoryId: categoryId ?? this.categoryId,
      category: category is _igagfyw0.Category?
          ? category
          : this.category?.copyWith(),
      orderItems: orderItems is List<_iuzd2jqp.OrderItem>?
          ? orderItems
          : this.orderItems?.map((e0) => e0.copyWith()).toList(),
      inventoryMovements:
          inventoryMovements is List<_i4yp9mtd.InventoryMovement>?
          ? inventoryMovements
          : this.inventoryMovements?.map((e0) => e0.copyWith()).toList(),
      promotions: promotions is List<_irk6gnzq.Promotion>?
          ? promotions
          : this.promotions?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class ProductUpdateTable extends _is.UpdateTable<ProductTable> {
  ProductUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> description(String? value) => _is.ColumnValue(
    table.description,
    value,
  );

  _is.ColumnValue<String, String> sku(String value) => _is.ColumnValue(
    table.sku,
    value,
  );

  _is.ColumnValue<int, int> priceCents(int value) => _is.ColumnValue(
    table.priceCents,
    value,
  );

  _is.ColumnValue<String, String> imageUrl(String? value) => _is.ColumnValue(
    table.imageUrl,
    value,
  );

  _is.ColumnValue<bool, bool> active(bool value) => _is.ColumnValue(
    table.active,
    value,
  );

  _is.ColumnValue<int, int> currentStock(int value) => _is.ColumnValue(
    table.currentStock,
    value,
  );

  _is.ColumnValue<int, int> minStock(int value) => _is.ColumnValue(
    table.minStock,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> expirationDate(DateTime? value) =>
      _is.ColumnValue(
        table.expirationDate,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> categoryId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.categoryId,
    value,
  );
}

class ProductTable extends _is.Table<_is.UuidValue?> {
  ProductTable({super.tableRelation}) : super(tableName: 'products') {
    updateTable = ProductUpdateTable(this);
    name = _is.ColumnString(
      'name',
      this,
    );
    description = _is.ColumnString(
      'description',
      this,
    );
    sku = _is.ColumnString(
      'sku',
      this,
    );
    priceCents = _is.ColumnInt(
      'priceCents',
      this,
    );
    imageUrl = _is.ColumnString(
      'imageUrl',
      this,
    );
    active = _is.ColumnBool(
      'active',
      this,
      hasDefault: true,
    );
    currentStock = _is.ColumnInt(
      'currentStock',
      this,
      hasDefault: true,
    );
    minStock = _is.ColumnInt(
      'minStock',
      this,
      hasDefault: true,
    );
    expirationDate = _is.ColumnDateTime(
      'expirationDate',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    categoryId = _is.ColumnUuid(
      'categoryId',
      this,
    );
  }

  late final ProductUpdateTable updateTable;

  late final _is.ColumnString name;

  late final _is.ColumnString description;

  late final _is.ColumnString sku;

  /// Precio en céntimos: 450 = S/ 4.50.
  late final _is.ColumnInt priceCents;

  late final _is.ColumnString imageUrl;

  late final _is.ColumnBool active;

  late final _is.ColumnInt currentStock;

  late final _is.ColumnInt minStock;

  late final _is.ColumnDateTime expirationDate;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnUuid categoryId;

  _igagfyw0.CategoryTable? _category;

  _iuzd2jqp.OrderItemTable? ___orderItems;

  _is.ManyRelation<_iuzd2jqp.OrderItemTable>? _orderItems;

  _i4yp9mtd.InventoryMovementTable? ___inventoryMovements;

  _is.ManyRelation<_i4yp9mtd.InventoryMovementTable>? _inventoryMovements;

  _irk6gnzq.PromotionTable? ___promotions;

  _is.ManyRelation<_irk6gnzq.PromotionTable>? _promotions;

  _igagfyw0.CategoryTable get category {
    if (_category != null) return _category!;
    _category = _is.createRelationTable(
      relationFieldName: 'category',
      field: Product.t.categoryId,
      foreignField: _igagfyw0.Category.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _igagfyw0.CategoryTable(tableRelation: foreignTableRelation),
    );
    return _category!;
  }

  _iuzd2jqp.OrderItemTable get __orderItems {
    if (___orderItems != null) return ___orderItems!;
    ___orderItems = _is.createRelationTable(
      relationFieldName: '__orderItems',
      field: Product.t.id,
      foreignField: _iuzd2jqp.OrderItem.t.productId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iuzd2jqp.OrderItemTable(tableRelation: foreignTableRelation),
    );
    return ___orderItems!;
  }

  _i4yp9mtd.InventoryMovementTable get __inventoryMovements {
    if (___inventoryMovements != null) return ___inventoryMovements!;
    ___inventoryMovements = _is.createRelationTable(
      relationFieldName: '__inventoryMovements',
      field: Product.t.id,
      foreignField: _i4yp9mtd.InventoryMovement.t.productId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4yp9mtd.InventoryMovementTable(tableRelation: foreignTableRelation),
    );
    return ___inventoryMovements!;
  }

  _irk6gnzq.PromotionTable get __promotions {
    if (___promotions != null) return ___promotions!;
    ___promotions = _is.createRelationTable(
      relationFieldName: '__promotions',
      field: Product.t.id,
      foreignField: _irk6gnzq.Promotion.t.productId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _irk6gnzq.PromotionTable(tableRelation: foreignTableRelation),
    );
    return ___promotions!;
  }

  _is.ManyRelation<_iuzd2jqp.OrderItemTable> get orderItems {
    if (_orderItems != null) return _orderItems!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'orderItems',
      field: Product.t.id,
      foreignField: _iuzd2jqp.OrderItem.t.productId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iuzd2jqp.OrderItemTable(tableRelation: foreignTableRelation),
    );
    _orderItems = _is.ManyRelation<_iuzd2jqp.OrderItemTable>(
      tableWithRelations: relationTable,
      table: _iuzd2jqp.OrderItemTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _orderItems!;
  }

  _is.ManyRelation<_i4yp9mtd.InventoryMovementTable> get inventoryMovements {
    if (_inventoryMovements != null) return _inventoryMovements!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'inventoryMovements',
      field: Product.t.id,
      foreignField: _i4yp9mtd.InventoryMovement.t.productId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4yp9mtd.InventoryMovementTable(tableRelation: foreignTableRelation),
    );
    _inventoryMovements = _is.ManyRelation<_i4yp9mtd.InventoryMovementTable>(
      tableWithRelations: relationTable,
      table: _i4yp9mtd.InventoryMovementTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _inventoryMovements!;
  }

  _is.ManyRelation<_irk6gnzq.PromotionTable> get promotions {
    if (_promotions != null) return _promotions!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'promotions',
      field: Product.t.id,
      foreignField: _irk6gnzq.Promotion.t.productId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _irk6gnzq.PromotionTable(tableRelation: foreignTableRelation),
    );
    _promotions = _is.ManyRelation<_irk6gnzq.PromotionTable>(
      tableWithRelations: relationTable,
      table: _irk6gnzq.PromotionTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _promotions!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    name,
    description,
    sku,
    priceCents,
    imageUrl,
    active,
    currentStock,
    minStock,
    expirationDate,
    createdAt,
    categoryId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'category') {
      return category;
    }
    if (relationField == 'orderItems') {
      return __orderItems;
    }
    if (relationField == 'inventoryMovements') {
      return __inventoryMovements;
    }
    if (relationField == 'promotions') {
      return __promotions;
    }
    return null;
  }
}

class ProductInclude extends _is.IncludeObject {
  ProductInclude._({
    _igagfyw0.CategoryInclude? category,
    _iuzd2jqp.OrderItemIncludeList? orderItems,
    _i4yp9mtd.InventoryMovementIncludeList? inventoryMovements,
    _irk6gnzq.PromotionIncludeList? promotions,
  }) {
    _category = category;
    _orderItems = orderItems;
    _inventoryMovements = inventoryMovements;
    _promotions = promotions;
  }

  _igagfyw0.CategoryInclude? _category;

  _iuzd2jqp.OrderItemIncludeList? _orderItems;

  _i4yp9mtd.InventoryMovementIncludeList? _inventoryMovements;

  _irk6gnzq.PromotionIncludeList? _promotions;

  @override
  Map<String, _is.Include?> get includes => {
    'category': _category,
    'orderItems': _orderItems,
    'inventoryMovements': _inventoryMovements,
    'promotions': _promotions,
  };

  @override
  _is.Table<_is.UuidValue?> get table => Product.t;
}

class ProductIncludeList extends _is.IncludeList {
  ProductIncludeList._({
    _is.WhereExpressionBuilder<ProductTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Product.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => Product.t;
}

class ProductRepository {
  const ProductRepository._();

  final attach = const ProductAttachRepository._();

  final attachRow = const ProductAttachRowRepository._();

  /// Returns a list of [Product]s matching the given query parameters.
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
  Future<List<Product>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProductTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProductTable>? orderBy,
    _is.OrderByListBuilder<ProductTable>? orderByList,
    _is.Transaction? transaction,
    ProductInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Product>(
      where: where?.call(Product.t),
      orderBy: orderBy?.call(Product.t),
      orderByList: orderByList?.call(Product.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Product] matching the given query parameters.
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
  Future<Product?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProductTable>? where,
    int? offset,
    _is.OrderByBuilder<ProductTable>? orderBy,
    _is.OrderByListBuilder<ProductTable>? orderByList,
    _is.Transaction? transaction,
    ProductInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Product>(
      where: where?.call(Product.t),
      orderBy: orderBy?.call(Product.t),
      orderByList: orderByList?.call(Product.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Product] by its [id] or null if no such row exists.
  Future<Product?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ProductInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Product>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Product]s in the list and returns the inserted rows.
  ///
  /// The returned [Product]s will have their `id` fields set.
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
  Future<List<Product>> insert(
    _is.DatabaseSession session,
    List<Product> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Product>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Product] and returns the inserted row.
  ///
  /// The returned [Product] will have its `id` field set.
  Future<Product> insertRow(
    _is.DatabaseSession session,
    Product row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Product>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Product]s in the list and returns the resulting rows.
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
  /// The returned [Product]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Product>> upsert(
    _is.DatabaseSession session,
    List<Product> rows, {
    required _is.ColumnSelections<ProductTable> conflictColumns,
    _is.ColumnSelections<ProductTable>? updateColumns,
    _is.WhereExpressionBuilder<ProductTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Product>(
      rows,
      conflictColumns: conflictColumns(Product.t),
      updateColumns: updateColumns?.call(Product.t),
      updateWhere: updateWhere?.call(Product.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Product] and returns the resulting row.
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
  /// The returned [Product] will have its `id` field set.
  Future<Product?> upsertRow(
    _is.DatabaseSession session,
    Product row, {
    required _is.ColumnSelections<ProductTable> conflictColumns,
    _is.ColumnSelections<ProductTable>? updateColumns,
    _is.WhereExpressionBuilder<ProductTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Product>(
      row,
      conflictColumns: conflictColumns(Product.t),
      updateColumns: updateColumns?.call(Product.t),
      updateWhere: updateWhere?.call(Product.t),
      transaction: transaction,
    );
  }

  /// Updates all [Product]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Product>> update(
    _is.DatabaseSession session,
    List<Product> rows, {
    _is.ColumnSelections<ProductTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Product>(
      rows,
      columns: columns?.call(Product.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Product]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Product> updateRow(
    _is.DatabaseSession session,
    Product row, {
    _is.ColumnSelections<ProductTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Product>(
      row,
      columns: columns?.call(Product.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Product] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Product?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ProductUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Product>(
      id,
      columnValues: columnValues(Product.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Product]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Product>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ProductUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ProductTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProductTable>? orderBy,
    _is.OrderByListBuilder<ProductTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Product>(
      columnValues: columnValues(Product.t.updateTable),
      where: where(Product.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Product.t),
      orderByList: orderByList?.call(Product.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Product]s in the list and returns the deleted rows.
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
  Future<List<Product>> delete(
    _is.DatabaseSession session,
    List<Product> rows, {
    _is.OrderByBuilder<ProductTable>? orderBy,
    _is.OrderByListBuilder<ProductTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Product>(
      rows,
      orderBy: orderBy?.call(Product.t),
      orderByList: orderByList?.call(Product.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Product].
  Future<Product> deleteRow(
    _is.DatabaseSession session,
    Product row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Product>(
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
  Future<List<Product>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProductTable> where,
    _is.OrderByBuilder<ProductTable>? orderBy,
    _is.OrderByListBuilder<ProductTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Product>(
      where: where(Product.t),
      orderBy: orderBy?.call(Product.t),
      orderByList: orderByList?.call(Product.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProductTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Product>(
      where: where?.call(Product.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Product] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProductTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Product>(
      where: where(Product.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ProductAttachRepository {
  const ProductAttachRepository._();

  /// Creates a relation between this [Product] and the given [OrderItem]s
  /// by setting each [OrderItem]'s foreign key `productId` to refer to this [Product].
  Future<void> orderItems(
    _is.DatabaseSession session,
    Product product,
    List<_iuzd2jqp.OrderItem> orderItem, {
    _is.Transaction? transaction,
  }) async {
    if (orderItem.any((e) => e.id == null)) {
      throw ArgumentError.notNull('orderItem.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $orderItem = orderItem
        .map((e) => e.copyWith(productId: product.id))
        .toList();
    await session.db.update<_iuzd2jqp.OrderItem>(
      $orderItem,
      columns: [_iuzd2jqp.OrderItem.t.productId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Product] and the given [InventoryMovement]s
  /// by setting each [InventoryMovement]'s foreign key `productId` to refer to this [Product].
  Future<void> inventoryMovements(
    _is.DatabaseSession session,
    Product product,
    List<_i4yp9mtd.InventoryMovement> inventoryMovement, {
    _is.Transaction? transaction,
  }) async {
    if (inventoryMovement.any((e) => e.id == null)) {
      throw ArgumentError.notNull('inventoryMovement.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $inventoryMovement = inventoryMovement
        .map((e) => e.copyWith(productId: product.id))
        .toList();
    await session.db.update<_i4yp9mtd.InventoryMovement>(
      $inventoryMovement,
      columns: [_i4yp9mtd.InventoryMovement.t.productId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Product] and the given [Promotion]s
  /// by setting each [Promotion]'s foreign key `productId` to refer to this [Product].
  Future<void> promotions(
    _is.DatabaseSession session,
    Product product,
    List<_irk6gnzq.Promotion> promotion, {
    _is.Transaction? transaction,
  }) async {
    if (promotion.any((e) => e.id == null)) {
      throw ArgumentError.notNull('promotion.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $promotion = promotion
        .map((e) => e.copyWith(productId: product.id))
        .toList();
    await session.db.update<_irk6gnzq.Promotion>(
      $promotion,
      columns: [_irk6gnzq.Promotion.t.productId],
      transaction: transaction,
    );
  }
}

class ProductAttachRowRepository {
  const ProductAttachRowRepository._();

  /// Creates a relation between the given [Product] and [Category]
  /// by setting the [Product]'s foreign key `categoryId` to refer to the [Category].
  Future<void> category(
    _is.DatabaseSession session,
    Product product,
    _igagfyw0.Category category, {
    _is.Transaction? transaction,
  }) async {
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }
    if (category.id == null) {
      throw ArgumentError.notNull('category.id');
    }

    var $product = product.copyWith(categoryId: category.id);
    await session.db.updateRow<Product>(
      $product,
      columns: [Product.t.categoryId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Product] and the given [OrderItem]
  /// by setting the [OrderItem]'s foreign key `productId` to refer to this [Product].
  Future<void> orderItems(
    _is.DatabaseSession session,
    Product product,
    _iuzd2jqp.OrderItem orderItem, {
    _is.Transaction? transaction,
  }) async {
    if (orderItem.id == null) {
      throw ArgumentError.notNull('orderItem.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $orderItem = orderItem.copyWith(productId: product.id);
    await session.db.updateRow<_iuzd2jqp.OrderItem>(
      $orderItem,
      columns: [_iuzd2jqp.OrderItem.t.productId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Product] and the given [InventoryMovement]
  /// by setting the [InventoryMovement]'s foreign key `productId` to refer to this [Product].
  Future<void> inventoryMovements(
    _is.DatabaseSession session,
    Product product,
    _i4yp9mtd.InventoryMovement inventoryMovement, {
    _is.Transaction? transaction,
  }) async {
    if (inventoryMovement.id == null) {
      throw ArgumentError.notNull('inventoryMovement.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $inventoryMovement = inventoryMovement.copyWith(productId: product.id);
    await session.db.updateRow<_i4yp9mtd.InventoryMovement>(
      $inventoryMovement,
      columns: [_i4yp9mtd.InventoryMovement.t.productId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Product] and the given [Promotion]
  /// by setting the [Promotion]'s foreign key `productId` to refer to this [Product].
  Future<void> promotions(
    _is.DatabaseSession session,
    Product product,
    _irk6gnzq.Promotion promotion, {
    _is.Transaction? transaction,
  }) async {
    if (promotion.id == null) {
      throw ArgumentError.notNull('promotion.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $promotion = promotion.copyWith(productId: product.id);
    await session.db.updateRow<_irk6gnzq.Promotion>(
      $promotion,
      columns: [_irk6gnzq.Promotion.t.productId],
      transaction: transaction,
    );
  }
}
