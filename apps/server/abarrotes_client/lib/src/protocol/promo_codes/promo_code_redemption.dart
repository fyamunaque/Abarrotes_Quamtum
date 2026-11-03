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
import '../users/user.dart' as _iqzoui01;

/// Un código activado por un cliente: sus promociones le valen hasta
/// `expiresAt` (exclusivo) y mientras le queden usos. Uno por cliente y
/// código.
abstract class PromoCodeRedemption
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PromoCodeRedemption._({
    this.id,
    required this.promoCodeId,
    this.promoCode,
    required this.userId,
    this.user,
    required this.activatedAt,
    required this.expiresAt,
  });

  factory PromoCodeRedemption({
    _isc.UuidValue? id,
    required _isc.UuidValue promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    required _isc.UuidValue userId,
    _iqzoui01.User? user,
    required DateTime activatedAt,
    required DateTime expiresAt,
  }) = _PromoCodeRedemptionImpl;

  factory PromoCodeRedemption.fromJson(Map<String, dynamic> jsonSerialization) {
    return PromoCodeRedemption(
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
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      user: jsonSerialization['user'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['user'],
            ),
      activatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['activatedAt'],
      ),
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  _isc.UuidValue promoCodeId;

  _ijnkkha9.PromoCode? promoCode;

  _isc.UuidValue userId;

  _iqzoui01.User? user;

  DateTime activatedAt;

  DateTime expiresAt;

  /// Returns a shallow copy of this [PromoCodeRedemption]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PromoCodeRedemption copyWith({
    _isc.UuidValue? id,
    _isc.UuidValue? promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    _isc.UuidValue? userId,
    _iqzoui01.User? user,
    DateTime? activatedAt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PromoCodeRedemption',
      if (id != null) 'id': id?.toJson(),
      'promoCodeId': promoCodeId.toJson(),
      if (promoCode != null) 'promoCode': promoCode?.toJson(),
      'userId': userId.toJson(),
      if (user != null) 'user': user?.toJson(),
      'activatedAt': activatedAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PromoCodeRedemption',
      if (id != null) 'id': id?.toJson(),
      'promoCodeId': promoCodeId.toJson(),
      if (promoCode != null) 'promoCode': promoCode?.toJsonForProtocol(),
      'userId': userId.toJson(),
      if (user != null) 'user': user?.toJsonForProtocol(),
      'activatedAt': activatedAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromoCodeRedemptionImpl extends PromoCodeRedemption {
  _PromoCodeRedemptionImpl({
    _isc.UuidValue? id,
    required _isc.UuidValue promoCodeId,
    _ijnkkha9.PromoCode? promoCode,
    required _isc.UuidValue userId,
    _iqzoui01.User? user,
    required DateTime activatedAt,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         promoCodeId: promoCodeId,
         promoCode: promoCode,
         userId: userId,
         user: user,
         activatedAt: activatedAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [PromoCodeRedemption]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PromoCodeRedemption copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? promoCodeId,
    Object? promoCode = _Undefined,
    _isc.UuidValue? userId,
    Object? user = _Undefined,
    DateTime? activatedAt,
    DateTime? expiresAt,
  }) {
    return PromoCodeRedemption(
      id: id is _isc.UuidValue? ? id : this.id,
      promoCodeId: promoCodeId ?? this.promoCodeId,
      promoCode: promoCode is _ijnkkha9.PromoCode?
          ? promoCode
          : this.promoCode?.copyWith(),
      userId: userId ?? this.userId,
      user: user is _iqzoui01.User? ? user : this.user?.copyWith(),
      activatedAt: activatedAt ?? this.activatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
