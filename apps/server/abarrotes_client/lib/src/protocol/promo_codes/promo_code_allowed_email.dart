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
import '../promo_codes/promo_code.dart' as _ijnkkha9;

/// Un correo (en minúsculas y sin espacios) que puede activar un código con
/// `eligibility` en `listed`.
abstract class PromoCodeAllowedEmail
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PromoCodeAllowedEmail._({
    this.id,
    required this.promoCodeId,
    this.promoCode,
    required this.email,
  });

  factory PromoCodeAllowedEmail({
    _isc.UuidValue? id,
    required _isc.UuidValue promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    required String email,
  }) = _PromoCodeAllowedEmailImpl;

  factory PromoCodeAllowedEmail.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PromoCodeAllowedEmail(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      promoCodeId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['promoCodeId'],
      ),
      promoCode: jsonSerialization['promoCode'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_ijnkkha9.PromoCode>(
              jsonSerialization['promoCode'],
            ),
      email: jsonSerialization['email'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  _isc.UuidValue promoCodeId;

  _ijnkkha9.PromoCode? promoCode;

  String email;

  /// Returns a shallow copy of this [PromoCodeAllowedEmail]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PromoCodeAllowedEmail copyWith({
    _isc.UuidValue? id,
    _isc.UuidValue? promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    String? email,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PromoCodeAllowedEmail',
      if (id != null) 'id': id?.toJson(),
      'promoCodeId': promoCodeId.toJson(),
      if (promoCode != null) 'promoCode': promoCode?.toJson(),
      'email': email,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PromoCodeAllowedEmail',
      if (id != null) 'id': id?.toJson(),
      'promoCodeId': promoCodeId.toJson(),
      if (promoCode != null) 'promoCode': promoCode?.toJsonForProtocol(),
      'email': email,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromoCodeAllowedEmailImpl extends PromoCodeAllowedEmail {
  _PromoCodeAllowedEmailImpl({
    _isc.UuidValue? id,
    required _isc.UuidValue promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    required String email,
  }) : super._(
         id: id,
         promoCodeId: promoCodeId,
         promoCode: promoCode,
         email: email,
       );

  /// Returns a shallow copy of this [PromoCodeAllowedEmail]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PromoCodeAllowedEmail copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? promoCodeId,
    Object? promoCode = _Undefined,
    String? email,
  }) {
    return PromoCodeAllowedEmail(
      id: id is _isc.UuidValue? ? id : this.id,
      promoCodeId: promoCodeId ?? this.promoCodeId,
      promoCode: promoCode is _ijnkkha9.PromoCode?
          ? promoCode
          : this.promoCode?.copyWith(),
      email: email ?? this.email,
    );
  }
}
