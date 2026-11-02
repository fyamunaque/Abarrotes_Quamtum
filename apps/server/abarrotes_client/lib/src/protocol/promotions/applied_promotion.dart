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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Una promoción que se aplicó en una línea del pedido, como foto: su
/// nombre y cuánto ahorró. Se guarda con la línea, así sigue igual aunque
/// después cambien o borren la promoción.
abstract class AppliedPromotion
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AppliedPromotion._({
    required this.promotionId,
    required this.label,
    required this.savedCents,
  });

  factory AppliedPromotion({
    required _isc.UuidValue promotionId,
    required String label,
    required int savedCents,
  }) = _AppliedPromotionImpl;

  factory AppliedPromotion.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppliedPromotion(
      promotionId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['promotionId'],
      ),
      label: jsonSerialization['label'] as String,
      savedCents: jsonSerialization['savedCents'] as int,
    );
  }

  _isc.UuidValue promotionId;

  String label;

  int savedCents;

  /// Returns a shallow copy of this [AppliedPromotion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AppliedPromotion copyWith({
    _isc.UuidValue? promotionId,
    String? label,
    int? savedCents,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppliedPromotion',
      'promotionId': promotionId.toJson(),
      'label': label,
      'savedCents': savedCents,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppliedPromotion',
      'promotionId': promotionId.toJson(),
      'label': label,
      'savedCents': savedCents,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _AppliedPromotionImpl extends AppliedPromotion {
  _AppliedPromotionImpl({
    required _isc.UuidValue promotionId,
    required String label,
    required int savedCents,
  }) : super._(
         promotionId: promotionId,
         label: label,
         savedCents: savedCents,
       );

  /// Returns a shallow copy of this [AppliedPromotion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AppliedPromotion copyWith({
    _isc.UuidValue? promotionId,
    String? label,
    int? savedCents,
  }) {
    return AppliedPromotion(
      promotionId: promotionId ?? this.promotionId,
      label: label ?? this.label,
      savedCents: savedCents ?? this.savedCents,
    );
  }
}
