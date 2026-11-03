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
import '../promo_codes/promo_code_allowed_email.dart' as _i0o3plfo;
import '../promo_codes/promo_code_eligibility.dart' as _ivxx501j;
import '../promotions/promotion.dart' as _irk6gnzq;

/// Un código promocional con el texto que eligió el administrador
/// ("VERANO-10"). Quien lo activa en su cuenta usa sus promociones (las de
/// audiencia `code`) por un tiempo y unos pedidos. Las fechas son los días
/// de la tienda (America/Lima) en que se puede activar: [inicio 00:00, día
/// siguiente al fin 00:00).
abstract class PromoCode
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PromoCode._({
    this.id,
    required this.code,
    bool? active,
    required this.startDate,
    required this.endDate,
    this.benefitDays,
    this.maxRedemptions,
    this.usesPerCustomer,
    this.minPurchaseCents,
    bool? newCustomersOnly,
    _ivxx501j.PromoCodeEligibility? eligibility,
    DateTime? createdAt,
    this.promotions,
    this.allowedEmails,
  }) : active = active ?? true,
       newCustomersOnly = newCustomersOnly ?? false,
       eligibility = eligibility ?? _ivxx501j.PromoCodeEligibility.everyone,
       createdAt = createdAt ?? DateTime.now();

  factory PromoCode({
    _isc.UuidValue? id,
    required String code,
    bool? active,
    required DateTime startDate,
    required DateTime endDate,
    int? benefitDays,
    int? maxRedemptions,
    int? usesPerCustomer,
    int? minPurchaseCents,
    bool? newCustomersOnly,
    _ivxx501j.PromoCodeEligibility? eligibility,
    DateTime? createdAt,
    List<_irk6gnzq.Promotion>? promotions,
    List<_i0o3plfo.PromoCodeAllowedEmail>? allowedEmails,
  }) = _PromoCodeImpl;

  factory PromoCode.fromJson(Map<String, dynamic> jsonSerialization) {
    return PromoCode(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      code: jsonSerialization['code'] as String,
      active: jsonSerialization['active'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['active']),
      startDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['startDate'],
      ),
      endDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['endDate'],
      ),
      benefitDays: jsonSerialization['benefitDays'] as int?,
      maxRedemptions: jsonSerialization['maxRedemptions'] as int?,
      usesPerCustomer: jsonSerialization['usesPerCustomer'] as int?,
      minPurchaseCents: jsonSerialization['minPurchaseCents'] as int?,
      newCustomersOnly: jsonSerialization['newCustomersOnly'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['newCustomersOnly'],
            ),
      eligibility: jsonSerialization['eligibility'] == null
          ? null
          : _ivxx501j.PromoCodeEligibility.fromJson(
              (jsonSerialization['eligibility'] as String),
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      promotions: jsonSerialization['promotions'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<List<_irk6gnzq.Promotion>>(
              jsonSerialization['promotions'],
            ),
      allowedEmails: jsonSerialization['allowedEmails'] == null
          ? null
          : _iv4mbvnl.Protocol()
                .deserialize<List<_i0o3plfo.PromoCodeAllowedEmail>>(
                  jsonSerialization['allowedEmails'],
                ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  /// En mayúsculas: de 3 a 20 letras, números o guiones.
  String code;

  /// El interruptor: apagado no se activa y sus promociones dejan de valer.
  bool active;

  DateTime startDate;

  DateTime endDate;

  /// Cuántos días dura el beneficio desde que cada cliente lo activa. Sin
  /// valor, hasta el fin de la vigencia.
  int? benefitDays;

  /// Cuántos clientes pueden activarlo. Sin valor, sin límite.
  int? maxRedemptions;

  /// En cuántos pedidos puede usarlo cada cliente. Sin valor, sin límite.
  int? usesPerCustomer;

  /// La compra mínima, en céntimos: el total sin las promociones del código.
  int? minPurchaseCents;

  /// Solo para quien todavía no hizo ningún pedido.
  bool newCustomersOnly;

  /// Quién puede activarlo: todos, los VIP o los correos de [allowedEmails].
  _ivxx501j.PromoCodeEligibility eligibility;

  DateTime createdAt;

  /// Las promociones que da (con audiencia `code`): al menos una para
  /// encenderlo.
  List<_irk6gnzq.Promotion>? promotions;

  /// Con `eligibility` en `listed`: los correos que pueden activarlo.
  List<_i0o3plfo.PromoCodeAllowedEmail>? allowedEmails;

  /// Returns a shallow copy of this [PromoCode]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PromoCode copyWith({
    _isc.UuidValue? id,
    String? code,
    bool? active,
    DateTime? startDate,
    DateTime? endDate,
    int? benefitDays,
    int? maxRedemptions,
    int? usesPerCustomer,
    int? minPurchaseCents,
    bool? newCustomersOnly,
    _ivxx501j.PromoCodeEligibility? eligibility,
    DateTime? createdAt,
    List<_irk6gnzq.Promotion>? promotions,
    List<_i0o3plfo.PromoCodeAllowedEmail>? allowedEmails,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PromoCode',
      if (id != null) 'id': id?.toJson(),
      'code': code,
      'active': active,
      'startDate': startDate.toJson(),
      'endDate': endDate.toJson(),
      if (benefitDays != null) 'benefitDays': benefitDays,
      if (maxRedemptions != null) 'maxRedemptions': maxRedemptions,
      if (usesPerCustomer != null) 'usesPerCustomer': usesPerCustomer,
      if (minPurchaseCents != null) 'minPurchaseCents': minPurchaseCents,
      'newCustomersOnly': newCustomersOnly,
      'eligibility': eligibility.toJson(),
      'createdAt': createdAt.toJson(),
      if (promotions != null)
        'promotions': promotions?.toJson(valueToJson: (v) => v.toJson()),
      if (allowedEmails != null)
        'allowedEmails': allowedEmails?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PromoCode',
      if (id != null) 'id': id?.toJson(),
      'code': code,
      'active': active,
      'startDate': startDate.toJson(),
      'endDate': endDate.toJson(),
      if (benefitDays != null) 'benefitDays': benefitDays,
      if (maxRedemptions != null) 'maxRedemptions': maxRedemptions,
      if (usesPerCustomer != null) 'usesPerCustomer': usesPerCustomer,
      if (minPurchaseCents != null) 'minPurchaseCents': minPurchaseCents,
      'newCustomersOnly': newCustomersOnly,
      'eligibility': eligibility.toJson(),
      'createdAt': createdAt.toJson(),
      if (promotions != null)
        'promotions': promotions?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (allowedEmails != null)
        'allowedEmails': allowedEmails?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromoCodeImpl extends PromoCode {
  _PromoCodeImpl({
    _isc.UuidValue? id,
    required String code,
    bool? active,
    required DateTime startDate,
    required DateTime endDate,
    int? benefitDays,
    int? maxRedemptions,
    int? usesPerCustomer,
    int? minPurchaseCents,
    bool? newCustomersOnly,
    _ivxx501j.PromoCodeEligibility? eligibility,
    DateTime? createdAt,
    List<_irk6gnzq.Promotion>? promotions,
    List<_i0o3plfo.PromoCodeAllowedEmail>? allowedEmails,
  }) : super._(
         id: id,
         code: code,
         active: active,
         startDate: startDate,
         endDate: endDate,
         benefitDays: benefitDays,
         maxRedemptions: maxRedemptions,
         usesPerCustomer: usesPerCustomer,
         minPurchaseCents: minPurchaseCents,
         newCustomersOnly: newCustomersOnly,
         eligibility: eligibility,
         createdAt: createdAt,
         promotions: promotions,
         allowedEmails: allowedEmails,
       );

  /// Returns a shallow copy of this [PromoCode]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PromoCode copyWith({
    Object? id = _Undefined,
    String? code,
    bool? active,
    DateTime? startDate,
    DateTime? endDate,
    Object? benefitDays = _Undefined,
    Object? maxRedemptions = _Undefined,
    Object? usesPerCustomer = _Undefined,
    Object? minPurchaseCents = _Undefined,
    bool? newCustomersOnly,
    _ivxx501j.PromoCodeEligibility? eligibility,
    DateTime? createdAt,
    Object? promotions = _Undefined,
    Object? allowedEmails = _Undefined,
  }) {
    return PromoCode(
      id: id is _isc.UuidValue? ? id : this.id,
      code: code ?? this.code,
      active: active ?? this.active,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      benefitDays: benefitDays is int? ? benefitDays : this.benefitDays,
      maxRedemptions: maxRedemptions is int?
          ? maxRedemptions
          : this.maxRedemptions,
      usesPerCustomer: usesPerCustomer is int?
          ? usesPerCustomer
          : this.usesPerCustomer,
      minPurchaseCents: minPurchaseCents is int?
          ? minPurchaseCents
          : this.minPurchaseCents,
      newCustomersOnly: newCustomersOnly ?? this.newCustomersOnly,
      eligibility: eligibility ?? this.eligibility,
      createdAt: createdAt ?? this.createdAt,
      promotions: promotions is List<_irk6gnzq.Promotion>?
          ? promotions
          : this.promotions?.map((e0) => e0.copyWith()).toList(),
      allowedEmails: allowedEmails is List<_i0o3plfo.PromoCodeAllowedEmail>?
          ? allowedEmails
          : this.allowedEmails?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
