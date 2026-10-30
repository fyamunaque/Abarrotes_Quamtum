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
import '../promotions/promotion.dart' as _irk6gnzq;
import '../vip/vip_customer.dart' as _icy1qtyi;

/// Un cliente VIP elegido para una promoción de clientes elegidos (audiencia
/// `selected`). Le vale mientras siga siendo VIP: si lo dan de baja, deja de
/// valerle aunque la fila siga.
abstract class PromotionRecipient
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PromotionRecipient._({
    this.id,
    required this.promotionId,
    this.promotion,
    required this.vipCustomerId,
    this.vipCustomer,
  });

  factory PromotionRecipient({
    _isc.UuidValue? id,
    required _isc.UuidValue promotionId,
    _irk6gnzq.Promotion? promotion,
    required _isc.UuidValue vipCustomerId,
    _icy1qtyi.VipCustomer? vipCustomer,
  }) = _PromotionRecipientImpl;

  factory PromotionRecipient.fromJson(Map<String, dynamic> jsonSerialization) {
    return PromotionRecipient(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      promotionId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['promotionId'],
      ),
      promotion: jsonSerialization['promotion'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_irk6gnzq.Promotion>(
              jsonSerialization['promotion'],
            ),
      vipCustomerId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['vipCustomerId'],
      ),
      vipCustomer: jsonSerialization['vipCustomer'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_icy1qtyi.VipCustomer>(
              jsonSerialization['vipCustomer'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  _isc.UuidValue promotionId;

  _irk6gnzq.Promotion? promotion;

  _isc.UuidValue vipCustomerId;

  _icy1qtyi.VipCustomer? vipCustomer;

  /// Returns a shallow copy of this [PromotionRecipient]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PromotionRecipient copyWith({
    _isc.UuidValue? id,
    _isc.UuidValue? promotionId,
    _irk6gnzq.Promotion? promotion,
    _isc.UuidValue? vipCustomerId,
    _icy1qtyi.VipCustomer? vipCustomer,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PromotionRecipient',
      if (id != null) 'id': id?.toJson(),
      'promotionId': promotionId.toJson(),
      if (promotion != null) 'promotion': promotion?.toJson(),
      'vipCustomerId': vipCustomerId.toJson(),
      if (vipCustomer != null) 'vipCustomer': vipCustomer?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PromotionRecipient',
      if (id != null) 'id': id?.toJson(),
      'promotionId': promotionId.toJson(),
      if (promotion != null) 'promotion': promotion?.toJsonForProtocol(),
      'vipCustomerId': vipCustomerId.toJson(),
      if (vipCustomer != null) 'vipCustomer': vipCustomer?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromotionRecipientImpl extends PromotionRecipient {
  _PromotionRecipientImpl({
    _isc.UuidValue? id,
    required _isc.UuidValue promotionId,
    _irk6gnzq.Promotion? promotion,
    required _isc.UuidValue vipCustomerId,
    _icy1qtyi.VipCustomer? vipCustomer,
  }) : super._(
         id: id,
         promotionId: promotionId,
         promotion: promotion,
         vipCustomerId: vipCustomerId,
         vipCustomer: vipCustomer,
       );

  /// Returns a shallow copy of this [PromotionRecipient]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PromotionRecipient copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? promotionId,
    Object? promotion = _Undefined,
    _isc.UuidValue? vipCustomerId,
    Object? vipCustomer = _Undefined,
  }) {
    return PromotionRecipient(
      id: id is _isc.UuidValue? ? id : this.id,
      promotionId: promotionId ?? this.promotionId,
      promotion: promotion is _irk6gnzq.Promotion?
          ? promotion
          : this.promotion?.copyWith(),
      vipCustomerId: vipCustomerId ?? this.vipCustomerId,
      vipCustomer: vipCustomer is _icy1qtyi.VipCustomer?
          ? vipCustomer
          : this.vipCustomer?.copyWith(),
    );
  }
}
