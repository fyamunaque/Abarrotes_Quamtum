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
import '../products/product.dart' as _iubf72bi;
import '../promotions/promotion_audience.dart' as _ifhe3ya9;
import '../promotions/promotion_recipient.dart' as _i7eleph1;
import '../promotions/promotion_type.dart' as _i4iqhu0d;

/// Una promoción de un producto por un periodo: un precio especial, un
/// porcentaje, un NxM, una unidad extra con descuento o un regalo (`type`).
/// Las fechas son días de la
/// tienda (America/Lima): [inicio 00:00, día siguiente al fin 00:00).
abstract class Promotion
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Promotion._({
    this.id,
    _i4iqhu0d.PromotionType? type,
    this.promoPriceCents,
    this.percent,
    this.buyQuantity,
    this.payQuantity,
    this.giftProductId,
    this.giftProduct,
    this.giftQuantity,
    required this.startDate,
    required this.endDate,
    bool? active,
    required this.productId,
    this.product,
    _ifhe3ya9.PromotionAudience? audience,
    this.recipients,
    this.title,
  }) : type = type ?? _i4iqhu0d.PromotionType.specialPrice,
       active = active ?? true,
       audience = audience ?? _ifhe3ya9.PromotionAudience.everyone;

  factory Promotion({
    _isc.UuidValue? id,
    _i4iqhu0d.PromotionType? type,
    int? promoPriceCents,
    int? percent,
    int? buyQuantity,
    int? payQuantity,
    _isc.UuidValue? giftProductId,
    _iubf72bi.Product? giftProduct,
    int? giftQuantity,
    required DateTime startDate,
    required DateTime endDate,
    bool? active,
    required _isc.UuidValue productId,
    _iubf72bi.Product? product,
    _ifhe3ya9.PromotionAudience? audience,
    List<_i7eleph1.PromotionRecipient>? recipients,
    String? title,
  }) = _PromotionImpl;

  factory Promotion.fromJson(Map<String, dynamic> jsonSerialization) {
    return Promotion(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      type: jsonSerialization['type'] == null
          ? null
          : _i4iqhu0d.PromotionType.fromJson(
              (jsonSerialization['type'] as String),
            ),
      promoPriceCents: jsonSerialization['promoPriceCents'] as int?,
      percent: jsonSerialization['percent'] as int?,
      buyQuantity: jsonSerialization['buyQuantity'] as int?,
      payQuantity: jsonSerialization['payQuantity'] as int?,
      giftProductId: jsonSerialization['giftProductId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['giftProductId'],
            ),
      giftProduct: jsonSerialization['giftProduct'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iubf72bi.Product>(
              jsonSerialization['giftProduct'],
            ),
      giftQuantity: jsonSerialization['giftQuantity'] as int?,
      startDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['startDate'],
      ),
      endDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['endDate'],
      ),
      active: jsonSerialization['active'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['active']),
      productId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['productId'],
      ),
      product: jsonSerialization['product'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iubf72bi.Product>(
              jsonSerialization['product'],
            ),
      audience: jsonSerialization['audience'] == null
          ? null
          : _ifhe3ya9.PromotionAudience.fromJson(
              (jsonSerialization['audience'] as String),
            ),
      recipients: jsonSerialization['recipients'] == null
          ? null
          : _iv4mbvnl.Protocol()
                .deserialize<List<_i7eleph1.PromotionRecipient>>(
                  jsonSerialization['recipients'],
                ),
      title: jsonSerialization['title'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  _i4iqhu0d.PromotionType type;

  /// Solo en `specialPrice`: el precio de la promoción, en céntimos.
  int? promoPriceCents;

  /// En `percentOff` y `extraUnit`: cuánto menos, en %.
  int? percent;

  /// En `buyXPayY`, la N que se lleva; en `extraUnit`, cada cuántas
  /// unidades; en `gift`, cada cuántas unidades hay regalo.
  int? buyQuantity;

  /// En `buyXPayY`: la M que se paga.
  int? payQuantity;

  _isc.UuidValue? giftProductId;

  /// En `gift`: el producto que se regala y cuántos por cada `buyQuantity`.
  _iubf72bi.Product? giftProduct;

  int? giftQuantity;

  DateTime startDate;

  DateTime endDate;

  bool active;

  _isc.UuidValue productId;

  _iubf72bi.Product? product;

  /// A quién va dirigida: a todos, a los clientes VIP o solo a los VIP
  /// elegidos ([recipients]).
  _ifhe3ya9.PromotionAudience audience;

  /// Con la audiencia `selected`: los clientes VIP elegidos.
  List<_i7eleph1.PromotionRecipient>? recipients;

  /// Para mostrar la oferta (p. ej. "Semana del arroz"). Opcional.
  String? title;

  /// Returns a shallow copy of this [Promotion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Promotion copyWith({
    _isc.UuidValue? id,
    _i4iqhu0d.PromotionType? type,
    int? promoPriceCents,
    int? percent,
    int? buyQuantity,
    int? payQuantity,
    _isc.UuidValue? giftProductId,
    _iubf72bi.Product? giftProduct,
    int? giftQuantity,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    _isc.UuidValue? productId,
    _iubf72bi.Product? product,
    _ifhe3ya9.PromotionAudience? audience,
    List<_i7eleph1.PromotionRecipient>? recipients,
    String? title,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Promotion',
      if (id != null) 'id': id?.toJson(),
      'type': type.toJson(),
      if (promoPriceCents != null) 'promoPriceCents': promoPriceCents,
      if (percent != null) 'percent': percent,
      if (buyQuantity != null) 'buyQuantity': buyQuantity,
      if (payQuantity != null) 'payQuantity': payQuantity,
      if (giftProductId != null) 'giftProductId': giftProductId?.toJson(),
      if (giftProduct != null) 'giftProduct': giftProduct?.toJson(),
      if (giftQuantity != null) 'giftQuantity': giftQuantity,
      'startDate': startDate.toJson(),
      'endDate': endDate.toJson(),
      'active': active,
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJson(),
      'audience': audience.toJson(),
      if (recipients != null)
        'recipients': recipients?.toJson(valueToJson: (v) => v.toJson()),
      if (title != null) 'title': title,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Promotion',
      if (id != null) 'id': id?.toJson(),
      'type': type.toJson(),
      if (promoPriceCents != null) 'promoPriceCents': promoPriceCents,
      if (percent != null) 'percent': percent,
      if (buyQuantity != null) 'buyQuantity': buyQuantity,
      if (payQuantity != null) 'payQuantity': payQuantity,
      if (giftProductId != null) 'giftProductId': giftProductId?.toJson(),
      if (giftProduct != null) 'giftProduct': giftProduct?.toJsonForProtocol(),
      if (giftQuantity != null) 'giftQuantity': giftQuantity,
      'startDate': startDate.toJson(),
      'endDate': endDate.toJson(),
      'active': active,
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJsonForProtocol(),
      'audience': audience.toJson(),
      if (recipients != null)
        'recipients': recipients?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (title != null) 'title': title,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromotionImpl extends Promotion {
  _PromotionImpl({
    _isc.UuidValue? id,
    _i4iqhu0d.PromotionType? type,
    int? promoPriceCents,
    int? percent,
    int? buyQuantity,
    int? payQuantity,
    _isc.UuidValue? giftProductId,
    _iubf72bi.Product? giftProduct,
    int? giftQuantity,
    required DateTime startDate,
    required DateTime endDate,
    bool? active,
    required _isc.UuidValue productId,
    _iubf72bi.Product? product,
    _ifhe3ya9.PromotionAudience? audience,
    List<_i7eleph1.PromotionRecipient>? recipients,
    String? title,
  }) : super._(
         id: id,
         type: type,
         promoPriceCents: promoPriceCents,
         percent: percent,
         buyQuantity: buyQuantity,
         payQuantity: payQuantity,
         giftProductId: giftProductId,
         giftProduct: giftProduct,
         giftQuantity: giftQuantity,
         startDate: startDate,
         endDate: endDate,
         active: active,
         productId: productId,
         product: product,
         audience: audience,
         recipients: recipients,
         title: title,
       );

  /// Returns a shallow copy of this [Promotion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Promotion copyWith({
    Object? id = _Undefined,
    _i4iqhu0d.PromotionType? type,
    Object? promoPriceCents = _Undefined,
    Object? percent = _Undefined,
    Object? buyQuantity = _Undefined,
    Object? payQuantity = _Undefined,
    Object? giftProductId = _Undefined,
    Object? giftProduct = _Undefined,
    Object? giftQuantity = _Undefined,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    _isc.UuidValue? productId,
    Object? product = _Undefined,
    _ifhe3ya9.PromotionAudience? audience,
    Object? recipients = _Undefined,
    Object? title = _Undefined,
  }) {
    return Promotion(
      id: id is _isc.UuidValue? ? id : this.id,
      type: type ?? this.type,
      promoPriceCents: promoPriceCents is int?
          ? promoPriceCents
          : this.promoPriceCents,
      percent: percent is int? ? percent : this.percent,
      buyQuantity: buyQuantity is int? ? buyQuantity : this.buyQuantity,
      payQuantity: payQuantity is int? ? payQuantity : this.payQuantity,
      giftProductId: giftProductId is _isc.UuidValue?
          ? giftProductId
          : this.giftProductId,
      giftProduct: giftProduct is _iubf72bi.Product?
          ? giftProduct
          : this.giftProduct?.copyWith(),
      giftQuantity: giftQuantity is int? ? giftQuantity : this.giftQuantity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      productId: productId ?? this.productId,
      product: product is _iubf72bi.Product?
          ? product
          : this.product?.copyWith(),
      audience: audience ?? this.audience,
      recipients: recipients is List<_i7eleph1.PromotionRecipient>?
          ? recipients
          : this.recipients?.map((e0) => e0.copyWith()).toList(),
      title: title is String? ? title : this.title,
    );
  }
}
