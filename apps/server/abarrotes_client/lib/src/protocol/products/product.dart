/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:abarrotes_client/src/protocol/protocol.dart' as _iv4mbvnl;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../categories/category.dart' as _igagfyw0;
import '../inventory/inventory_movement.dart' as _i4yp9mtd;
import '../orders/order_item.dart' as _iuzd2jqp;
import '../promotions/promotion.dart' as _irk6gnzq;

/// Producto del catálogo. Los montos se guardan en céntimos enteros.
abstract class Product
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
    _isc.UuidValue? id,
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
    required _isc.UuidValue categoryId,
    _igagfyw0.Category? category,
    List<_iuzd2jqp.OrderItem>? orderItems,
    List<_i4yp9mtd.InventoryMovement>? inventoryMovements,
    List<_irk6gnzq.Promotion>? promotions,
  }) = _ProductImpl;

  factory Product.fromJson(Map<String, dynamic> jsonSerialization) {
    return Product(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      sku: jsonSerialization['sku'] as String,
      priceCents: jsonSerialization['priceCents'] as int,
      imageUrl: jsonSerialization['imageUrl'] as String?,
      active: jsonSerialization['active'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['active']),
      currentStock: jsonSerialization['currentStock'] as int?,
      minStock: jsonSerialization['minStock'] as int?,
      expirationDate: jsonSerialization['expirationDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['expirationDate'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      categoryId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['categoryId'],
      ),
      category: jsonSerialization['category'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_igagfyw0.Category>(
              jsonSerialization['category'],
            ),
      orderItems: jsonSerialization['orderItems'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<List<_iuzd2jqp.OrderItem>>(
              jsonSerialization['orderItems'],
            ),
      inventoryMovements: jsonSerialization['inventoryMovements'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<List<_i4yp9mtd.InventoryMovement>>(
              jsonSerialization['inventoryMovements'],
            ),
      promotions: jsonSerialization['promotions'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<List<_irk6gnzq.Promotion>>(
              jsonSerialization['promotions'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

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

  _isc.UuidValue categoryId;

  _igagfyw0.Category? category;

  List<_iuzd2jqp.OrderItem>? orderItems;

  List<_i4yp9mtd.InventoryMovement>? inventoryMovements;

  List<_irk6gnzq.Promotion>? promotions;

  /// Returns a shallow copy of this [Product]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Product copyWith({
    _isc.UuidValue? id,
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
    _isc.UuidValue? categoryId,
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProductImpl extends Product {
  _ProductImpl({
    _isc.UuidValue? id,
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
    required _isc.UuidValue categoryId,
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
  @_isc.useResult
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
    _isc.UuidValue? categoryId,
    Object? category = _Undefined,
    Object? orderItems = _Undefined,
    Object? inventoryMovements = _Undefined,
    Object? promotions = _Undefined,
  }) {
    return Product(
      id: id is _isc.UuidValue? ? id : this.id,
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
