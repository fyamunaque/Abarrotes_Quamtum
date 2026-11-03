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
import '../promo_codes/promo_code_redemption.dart' as _iwmivuof;

/// Un pedido que usó un código activado (le ahorró algo una de sus
/// promociones). Los usos de un cliente son sus pedidos no cancelados:
/// cancelar un pedido devuelve el uso.
abstract class OrderPromoCodeUse
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  OrderPromoCodeUse._({
    this.id,
    required this.orderId,
    this.order,
    required this.redemptionId,
    this.redemption,
  });

  factory OrderPromoCodeUse({
    _isc.UuidValue? id,
    required _isc.UuidValue orderId,
    _ij3i88ow.Order? order,
    required _isc.UuidValue redemptionId,
    _iwmivuof.PromoCodeRedemption? redemption,
  }) = _OrderPromoCodeUseImpl;

  factory OrderPromoCodeUse.fromJson(Map<String, dynamic> jsonSerialization) {
    return OrderPromoCodeUse(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      orderId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['orderId'],
      ),
      order: jsonSerialization['order'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_ij3i88ow.Order>(
              jsonSerialization['order'],
            ),
      redemptionId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['redemptionId'],
      ),
      redemption: jsonSerialization['redemption'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iwmivuof.PromoCodeRedemption>(
              jsonSerialization['redemption'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  _isc.UuidValue orderId;

  _ij3i88ow.Order? order;

  _isc.UuidValue redemptionId;

  _iwmivuof.PromoCodeRedemption? redemption;

  /// Returns a shallow copy of this [OrderPromoCodeUse]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  OrderPromoCodeUse copyWith({
    _isc.UuidValue? id,
    _isc.UuidValue? orderId,
    _ij3i88ow.Order? order,
    _isc.UuidValue? redemptionId,
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrderPromoCodeUseImpl extends OrderPromoCodeUse {
  _OrderPromoCodeUseImpl({
    _isc.UuidValue? id,
    required _isc.UuidValue orderId,
    _ij3i88ow.Order? order,
    required _isc.UuidValue redemptionId,
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
  @_isc.useResult
  @override
  OrderPromoCodeUse copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? orderId,
    Object? order = _Undefined,
    _isc.UuidValue? redemptionId,
    Object? redemption = _Undefined,
  }) {
    return OrderPromoCodeUse(
      id: id is _isc.UuidValue? ? id : this.id,
      orderId: orderId ?? this.orderId,
      order: order is _ij3i88ow.Order? ? order : this.order?.copyWith(),
      redemptionId: redemptionId ?? this.redemptionId,
      redemption: redemption is _iwmivuof.PromoCodeRedemption?
          ? redemption
          : this.redemption?.copyWith(),
    );
  }
}
