import '../common/money.dart';

/// Un código que activó la cuenta y todavía le sirve, como lo manda
/// `/promo-codes/mine`: hasta cuándo, cuántos pedidos le quedan, la compra
/// mínima y lo que da cada promoción ("2x1 en Arroz extra 5 kg").
class MyPromoCode {
  const MyPromoCode({
    required this.code,
    required this.expiresAt,
    this.usesLeft,
    this.minPurchaseCents,
    this.promotions = const [],
  });

  /// Lanza [FormatException] si [json] no tiene esa forma.
  factory MyPromoCode.fromJson(Object? json) => switch (json) {
    {
          'code': final String code,
          'expiresAt': final String expiresAt,
          'promotions': final List<Object?> promotions,
        } &&
        final Map<Object?, Object?> map =>
      MyPromoCode(
        code: code,
        expiresAt: DateTime.parse(expiresAt),
        usesLeft: map['usesLeft'] as int?,
        minPurchaseCents: switch (map['minPurchase']) {
          final String amount => parseCents(amount),
          _ => null,
        },
        promotions: [
          for (final promotion in promotions)
            switch (promotion) {
              {
                'label': final String label,
                'product': {'name': final String name},
              } =>
                '$label en $name',
              _ => throw FormatException('No es una promoción', promotion),
            },
        ],
      ),
    _ => throw FormatException('No es un código', json),
  };

  final String code;

  /// Hasta cuándo sirve (el instante, sin incluirlo).
  final DateTime expiresAt;

  /// En cuántos pedidos más se puede usar (null: sin límite).
  final int? usesLeft;
  final int? minPurchaseCents;
  final List<String> promotions;

  /// El último día de la tienda (hora de Lima, UTC−5) en que sirve.
  DateTime get lastDay {
    final last = expiresAt
        .toUtc()
        .subtract(const Duration(hours: 5))
        .subtract(const Duration(microseconds: 1));
    return DateTime(last.year, last.month, last.day);
  }
}
