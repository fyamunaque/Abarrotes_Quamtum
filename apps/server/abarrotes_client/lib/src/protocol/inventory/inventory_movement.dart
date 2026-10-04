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
import '../inventory/movement_type.dart' as _iwxdrlkj;
import '../products/product.dart' as _iubf72bi;
import '../users/user.dart' as _iqzoui01;

abstract class InventoryMovement
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
    _isc.UuidValue? id,
    required _iwxdrlkj.MovementType type,
    required int quantity,
    String? reason,
    DateTime? createdAt,
    required _isc.UuidValue productId,
    _iubf72bi.Product? product,
    required _isc.UuidValue userId,
    _iqzoui01.User? user,
  }) = _InventoryMovementImpl;

  factory InventoryMovement.fromJson(Map<String, dynamic> jsonSerialization) {
    return InventoryMovement(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      type: _iwxdrlkj.MovementType.fromJson(
        (jsonSerialization['type'] as String),
      ),
      quantity: jsonSerialization['quantity'] as int,
      reason: jsonSerialization['reason'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      productId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['productId'],
      ),
      product: jsonSerialization['product'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iubf72bi.Product>(
              jsonSerialization['product'],
            ),
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      user: jsonSerialization['user'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['user'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  _iwxdrlkj.MovementType type;

  int quantity;

  String? reason;

  DateTime createdAt;

  _isc.UuidValue productId;

  _iubf72bi.Product? product;

  _isc.UuidValue userId;

  /// Quién lo originó: el cliente que hizo el pedido o el staff que lo canceló.
  _iqzoui01.User? user;

  /// Returns a shallow copy of this [InventoryMovement]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  InventoryMovement copyWith({
    _isc.UuidValue? id,
    _iwxdrlkj.MovementType? type,
    int? quantity,
    String? reason,
    DateTime? createdAt,
    _isc.UuidValue? productId,
    _iubf72bi.Product? product,
    _isc.UuidValue? userId,
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _InventoryMovementImpl extends InventoryMovement {
  _InventoryMovementImpl({
    _isc.UuidValue? id,
    required _iwxdrlkj.MovementType type,
    required int quantity,
    String? reason,
    DateTime? createdAt,
    required _isc.UuidValue productId,
    _iubf72bi.Product? product,
    required _isc.UuidValue userId,
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
  @_isc.useResult
  @override
  InventoryMovement copyWith({
    Object? id = _Undefined,
    _iwxdrlkj.MovementType? type,
    int? quantity,
    Object? reason = _Undefined,
    DateTime? createdAt,
    _isc.UuidValue? productId,
    Object? product = _Undefined,
    _isc.UuidValue? userId,
    Object? user = _Undefined,
  }) {
    return InventoryMovement(
      id: id is _isc.UuidValue? ? id : this.id,
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
