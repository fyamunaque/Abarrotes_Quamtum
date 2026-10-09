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
import '../orders/order_item.dart' as _iuzd2jqp;
import '../orders/order_status.dart' as _i2b33p21;
import '../users/user.dart' as _iqzoui01;

abstract class Order
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Order._({
    this.id,
    _i2b33p21.OrderStatus? status,
    required this.totalCents,
    required this.deliveryAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.customerId,
    this.customer,
    this.items,
  }) : status = status ?? _i2b33p21.OrderStatus.pendingConfirmation,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Order({
    _isc.UuidValue? id,
    _i2b33p21.OrderStatus? status,
    required int totalCents,
    required String deliveryAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    required _isc.UuidValue customerId,
    _iqzoui01.User? customer,
    List<_iuzd2jqp.OrderItem>? items,
  }) = _OrderImpl;

  factory Order.fromJson(Map<String, dynamic> jsonSerialization) {
    return Order(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      status: jsonSerialization['status'] == null
          ? null
          : _i2b33p21.OrderStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      totalCents: jsonSerialization['totalCents'] as int,
      deliveryAddress: jsonSerialization['deliveryAddress'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      customerId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['customerId'],
      ),
      customer: jsonSerialization['customer'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['customer'],
            ),
      items: jsonSerialization['items'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<List<_iuzd2jqp.OrderItem>>(
              jsonSerialization['items'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  _i2b33p21.OrderStatus status;

  /// Total en céntimos.
  int totalCents;

  String deliveryAddress;

  DateTime createdAt;

  /// Serverpod no tiene @updatedAt: lo actualiza quien modifica el pedido.
  DateTime updatedAt;

  _isc.UuidValue customerId;

  _iqzoui01.User? customer;

  List<_iuzd2jqp.OrderItem>? items;

  /// Returns a shallow copy of this [Order]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Order copyWith({
    _isc.UuidValue? id,
    _i2b33p21.OrderStatus? status,
    int? totalCents,
    String? deliveryAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    _isc.UuidValue? customerId,
    _iqzoui01.User? customer,
    List<_iuzd2jqp.OrderItem>? items,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Order',
      if (id != null) 'id': id?.toJson(),
      'status': status.toJson(),
      'totalCents': totalCents,
      'deliveryAddress': deliveryAddress,
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
      'totalCents': totalCents,
      'deliveryAddress': deliveryAddress,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'customerId': customerId.toJson(),
      if (customer != null) 'customer': customer?.toJsonForProtocol(),
      if (items != null)
        'items': items?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrderImpl extends Order {
  _OrderImpl({
    _isc.UuidValue? id,
    _i2b33p21.OrderStatus? status,
    required int totalCents,
    required String deliveryAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    required _isc.UuidValue customerId,
    _iqzoui01.User? customer,
    List<_iuzd2jqp.OrderItem>? items,
  }) : super._(
         id: id,
         status: status,
         totalCents: totalCents,
         deliveryAddress: deliveryAddress,
         createdAt: createdAt,
         updatedAt: updatedAt,
         customerId: customerId,
         customer: customer,
         items: items,
       );

  /// Returns a shallow copy of this [Order]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Order copyWith({
    Object? id = _Undefined,
    _i2b33p21.OrderStatus? status,
    int? totalCents,
    String? deliveryAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    _isc.UuidValue? customerId,
    Object? customer = _Undefined,
    Object? items = _Undefined,
  }) {
    return Order(
      id: id is _isc.UuidValue? ? id : this.id,
      status: status ?? this.status,
      totalCents: totalCents ?? this.totalCents,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
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
