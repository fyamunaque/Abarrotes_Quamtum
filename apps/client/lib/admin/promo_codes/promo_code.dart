import '../../common/money.dart';
import '../promotions/promotion.dart';

/// En qué está un código hoy. Lo calcula el servidor con las fechas y si
/// está encendido.
enum PromoCodeStatus {
  active('Activo', 'Activos'),
  scheduled('Programado', 'Programados'),
  expired('Vencido', 'Vencidos'),
  paused('Pausado', 'Pausados');

  const PromoCodeStatus(this.label, this.pluralLabel);

  final String label;

  /// Para los filtros.
  final String pluralLabel;
}

/// Quién puede activar un código, con los nombres del servidor.
enum PromoCodeEligibility {
  everyone('Todos'),
  vip('Solo VIP'),

  /// Los correos de `PromoCode.allowedEmails`.
  listed('Lista de correos');

  const PromoCodeEligibility(this.label);

  final String label;
}

/// Un código promocional con el texto que eligió el administrador
/// ("VERANO-10"): quien lo activa usa sus [promotions] por un tiempo y unos
/// pedidos, si cumple las condiciones.
class PromoCode {
  const PromoCode({
    required this.id,
    required this.code,
    required this.active,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.benefitDays,
    this.maxRedemptions,
    this.usesPerCustomer,
    this.minPurchaseCents,
    this.newCustomersOnly = false,
    this.eligibility = PromoCodeEligibility.everyone,
    this.allowedEmails = const [],
    this.promotions = const [],
    this.redemptions = 0,
    this.orders = 0,
  });

  /// Como lo manda `/promo-codes`.
  factory PromoCode.fromJson(Object? json) => switch (json) {
    {
          'id': final String id,
          'code': final String code,
          'active': final bool active,
          'status': final String status,
          'startDate': final String startDate,
          'endDate': final String endDate,
          'eligibility': final String eligibility,
          'redemptions': final int redemptions,
          'orders': final int orders,
        } &&
        final Map<Object?, Object?> map =>
      PromoCode(
        id: id,
        code: code,
        active: active,
        status:
            PromoCodeStatus.values.asNameMap()[status] ??
            (throw FormatException('Estado desconocido', status)),
        startDate: startDate,
        endDate: endDate,
        benefitDays: map['benefitDays'] as int?,
        maxRedemptions: map['maxRedemptions'] as int?,
        usesPerCustomer: map['usesPerCustomer'] as int?,
        minPurchaseCents: switch (map['minPurchase']) {
          final String amount => parseCents(amount),
          _ => null,
        },
        newCustomersOnly: map['newCustomersOnly'] == true,
        eligibility:
            PromoCodeEligibility.values.asNameMap()[eligibility] ??
            (throw FormatException('Condición desconocida', eligibility)),
        allowedEmails: switch (map['allowedEmails']) {
          final List<Object?> emails => emails.cast<String>(),
          _ => const [],
        },
        promotions: switch (map['promotions']) {
          final List<Object?> list => [
            for (final promotion in list) Promotion.fromJson(promotion),
          ],
          _ => const [],
        },
        redemptions: redemptions,
        orders: orders,
      ),
    _ => throw FormatException('No es un código', json),
  };

  final String id;
  final String code;

  /// El interruptor: apagado no se activa y sus promociones dejan de valer.
  final bool active;
  final PromoCodeStatus status;

  /// Días de la tienda (`AAAA-MM-DD`) en que se puede activar, ambos
  /// incluidos.
  final String startDate;
  final String endDate;

  /// Cuántos días dura el beneficio desde que cada cliente lo activa (null:
  /// hasta el fin de la vigencia).
  final int? benefitDays;

  /// Cuántos clientes pueden activarlo (null: sin límite).
  final int? maxRedemptions;

  /// En cuántos pedidos puede usarlo cada cliente (null: sin límite).
  final int? usesPerCustomer;

  /// El total mínimo para que sus promociones se apliquen.
  final int? minPurchaseCents;
  final bool newCustomersOnly;
  final PromoCodeEligibility eligibility;

  /// Con [PromoCodeEligibility.listed]: quiénes pueden activarlo.
  final List<String> allowedEmails;

  /// Las promociones que da (con la audiencia del código).
  final List<Promotion> promotions;

  /// Cuántos clientes lo activaron y en cuántos pedidos se usó.
  final int redemptions;
  final int orders;

  /// "Activado por 47 de 100", o "Activado por 3" sin límite.
  String get redemptionsLabel => switch (maxRedemptions) {
    final max? => 'Activado por $redemptions de $max',
    null => 'Activado por $redemptions',
  };
}

/// Lo que se manda al crear o editar un código. Un límite en null es "sin
/// límite" (al editar, quita el que tenía).
class PromoCodeInput {
  const PromoCodeInput({
    required this.code,
    required this.startDate,
    required this.endDate,
    required this.active,
    this.benefitDays,
    this.maxRedemptions,
    this.usesPerCustomer,
    this.minPurchaseCents,
    this.newCustomersOnly = false,
    this.eligibility = PromoCodeEligibility.everyone,
    this.allowedEmails = const [],
  });

  final String code;

  /// `AAAA-MM-DD`, ambos incluidos.
  final String startDate;
  final String endDate;
  final bool active;
  final int? benefitDays;
  final int? maxRedemptions;
  final int? usesPerCustomer;
  final int? minPurchaseCents;
  final bool newCustomersOnly;
  final PromoCodeEligibility eligibility;

  /// Solo con [PromoCodeEligibility.listed] (con otra condición, vacía).
  final List<String> allowedEmails;

  Map<String, Object?> toJson() => {
    'code': code,
    'startDate': startDate,
    'endDate': endDate,
    'active': active,
    'benefitDays': benefitDays,
    'maxRedemptions': maxRedemptions,
    'usesPerCustomer': usesPerCustomer,
    'minPurchase': switch (minPurchaseCents) {
      final cents? => cents / 100,
      null => null,
    },
    'newCustomersOnly': newCustomersOnly,
    'eligibility': eligibility.name,
    'allowedEmails': eligibility == PromoCodeEligibility.listed
        ? allowedEmails
        : const <String>[],
  };
}
