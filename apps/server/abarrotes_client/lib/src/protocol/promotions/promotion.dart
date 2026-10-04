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

/// Precio especial de un producto por un periodo. Las fechas son días de la
/// tienda (America/Lima): [inicio 00:00, día siguiente al fin 00:00).
abstract class Promotion
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
    _isc.UuidValue? id,
    required int promoPriceCents,
    required DateTime startDate,
    required DateTime endDate,
    bool? active,
    required _isc.UuidValue productId,
    _iubf72bi.Product? product,
  }) = _PromotionImpl;

  factory Promotion.fromJson(Map<String, dynamic> jsonSerialization) {
    return Promotion(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      promoPriceCents: jsonSerialization['promoPriceCents'] as int,
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
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  int promoPriceCents;

  DateTime startDate;

  DateTime endDate;

  bool active;

  _isc.UuidValue productId;

  _iubf72bi.Product? product;

  /// Returns a shallow copy of this [Promotion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Promotion copyWith({
    _isc.UuidValue? id,
    int? promoPriceCents,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    _isc.UuidValue? productId,
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromotionImpl extends Promotion {
  _PromotionImpl({
    _isc.UuidValue? id,
    required int promoPriceCents,
    required DateTime startDate,
    required DateTime endDate,
    bool? active,
    required _isc.UuidValue productId,
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
  @_isc.useResult
  @override
  Promotion copyWith({
    Object? id = _Undefined,
    int? promoPriceCents,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    _isc.UuidValue? productId,
    Object? product = _Undefined,
  }) {
    return Promotion(
      id: id is _isc.UuidValue? ? id : this.id,
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
