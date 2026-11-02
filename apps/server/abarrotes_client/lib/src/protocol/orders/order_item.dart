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
import '../orders/order.dart' as _ij3i88ow;
import '../products/product.dart' as _iubf72bi;
import '../promotions/applied_promotion.dart' as _iey7x119;

abstract class OrderItem
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  OrderItem._({
    this.id,
    required this.quantity,
    required this.unitPriceCents,
    int? listUnitPriceCents,
    int? lineTotalCents,
    bool? isGift,
    this.promotions,
    required this.orderId,
    this.order,
    required this.productId,
    this.product,
  }) : listUnitPriceCents = listUnitPriceCents ?? 0,
       lineTotalCents = lineTotalCents ?? 0,
       isGift = isGift ?? false;

  factory OrderItem({
    _isc.UuidValue? id,
    required int quantity,
    required int unitPriceCents,
    int? listUnitPriceCents,
    int? lineTotalCents,
    bool? isGift,
    List<_iey7x119.AppliedPromotion>? promotions,
    required _isc.UuidValue orderId,
    _ij3i88ow.Order? order,
    required _isc.UuidValue productId,
    _iubf72bi.Product? product,
  }) = _OrderItemImpl;

  factory OrderItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return OrderItem(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      quantity: jsonSerialization['quantity'] as int,
      unitPriceCents: jsonSerialization['unitPriceCents'] as int,
      listUnitPriceCents: jsonSerialization['listUnitPriceCents'] as int?,
      lineTotalCents: jsonSerialization['lineTotalCents'] as int?,
      isGift: jsonSerialization['isGift'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['isGift']),
      promotions: jsonSerialization['promotions'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<List<_iey7x119.AppliedPromotion>>(
              jsonSerialization['promotions'],
            ),
      orderId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['orderId'],
      ),
      order: jsonSerialization['order'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_ij3i88ow.Order>(
              jsonSerialization['order'],
            ),
      productId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['productId'],
      ),
      product: jsonSerialization['product'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iubf72bi.Product>(
              jsonSerialization['product'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  int quantity;

  /// Precio unitario después del precio especial y los porcentajes, en
  /// céntimos (0 en un regalo).
  int unitPriceCents;

  /// El precio normal del producto al hacer el pedido.
  /// (default 0 solo para agregar la columna: la migración la completa y el
  /// servidor siempre la pone).
  int listUnitPriceCents;

  /// Lo que se cobró por la línea, con las promociones por cantidad (2x1…).
  int lineTotalCents;

  /// Una línea de regalo (a S/ 0) de una promoción de regalo.
  bool isGift;

  /// Las promociones que se aplicaron, como foto (nombre y ahorro).
  List<_iey7x119.AppliedPromotion>? promotions;

  _isc.UuidValue orderId;

  _ij3i88ow.Order? order;

  _isc.UuidValue productId;

  _iubf72bi.Product? product;

  /// Returns a shallow copy of this [OrderItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  OrderItem copyWith({
    _isc.UuidValue? id,
    int? quantity,
    int? unitPriceCents,
    int? listUnitPriceCents,
    int? lineTotalCents,
    bool? isGift,
    List<_iey7x119.AppliedPromotion>? promotions,
    _isc.UuidValue? orderId,
    _ij3i88ow.Order? order,
    _isc.UuidValue? productId,
    _iubf72bi.Product? product,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OrderItem',
      if (id != null) 'id': id?.toJson(),
      'quantity': quantity,
      'unitPriceCents': unitPriceCents,
      'listUnitPriceCents': listUnitPriceCents,
      'lineTotalCents': lineTotalCents,
      'isGift': isGift,
      if (promotions != null)
        'promotions': promotions?.toJson(valueToJson: (v) => v.toJson()),
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
      'listUnitPriceCents': listUnitPriceCents,
      'lineTotalCents': lineTotalCents,
      'isGift': isGift,
      if (promotions != null)
        'promotions': promotions?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      'orderId': orderId.toJson(),
      if (order != null) 'order': order?.toJsonForProtocol(),
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrderItemImpl extends OrderItem {
  _OrderItemImpl({
    _isc.UuidValue? id,
    required int quantity,
    required int unitPriceCents,
    int? listUnitPriceCents,
    int? lineTotalCents,
    bool? isGift,
    List<_iey7x119.AppliedPromotion>? promotions,
    required _isc.UuidValue orderId,
    _ij3i88ow.Order? order,
    required _isc.UuidValue productId,
    _iubf72bi.Product? product,
  }) : super._(
         id: id,
         quantity: quantity,
         unitPriceCents: unitPriceCents,
         listUnitPriceCents: listUnitPriceCents,
         lineTotalCents: lineTotalCents,
         isGift: isGift,
         promotions: promotions,
         orderId: orderId,
         order: order,
         productId: productId,
         product: product,
       );

  /// Returns a shallow copy of this [OrderItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  OrderItem copyWith({
    Object? id = _Undefined,
    int? quantity,
    int? unitPriceCents,
    int? listUnitPriceCents,
    int? lineTotalCents,
    bool? isGift,
    Object? promotions = _Undefined,
    _isc.UuidValue? orderId,
    Object? order = _Undefined,
    _isc.UuidValue? productId,
    Object? product = _Undefined,
  }) {
    return OrderItem(
      id: id is _isc.UuidValue? ? id : this.id,
      quantity: quantity ?? this.quantity,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      listUnitPriceCents: listUnitPriceCents ?? this.listUnitPriceCents,
      lineTotalCents: lineTotalCents ?? this.lineTotalCents,
      isGift: isGift ?? this.isGift,
      promotions: promotions is List<_iey7x119.AppliedPromotion>?
          ? promotions
          : this.promotions?.map((e0) => e0.copyWith()).toList(),
      orderId: orderId ?? this.orderId,
      order: order is _ij3i88ow.Order? ? order : this.order?.copyWith(),
      productId: productId ?? this.productId,
      product: product is _iubf72bi.Product?
          ? product
          : this.product?.copyWith(),
    );
  }
}
