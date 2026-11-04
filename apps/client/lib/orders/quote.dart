import '../common/money.dart';
import 'order.dart';

/// Cómo se cobraría el carrito hoy (`POST /orders/quote` en apps/server),
/// sin guardar nada: cada línea con sus promociones, los regalos en sus
/// propias líneas (en 0), el subtotal, los descuentos, el total y los avisos
/// ("Solo quedaba 1 de Sal 1 kg para regalo").
class Quote {
  const Quote({
    required this.lines,
    required this.subtotalCents,
    required this.discountCents,
    required this.totalCents,
    this.notices = const [],
    this.requested = const [],
    this.owner,
  });

  /// Lanza [FormatException] si [json] no tiene esa forma.
  factory Quote.fromJson(Object? json) => switch (json) {
    {
          'lines': final List<Object?> lines,
          'subtotal': final String subtotal,
          'discount': final String discount,
          'total': final String total,
        } &&
        final Map<Object?, Object?> map =>
      Quote(
        lines: [for (final line in lines) OrderLine.fromJson(line)],
        subtotalCents: parseCents(subtotal),
        discountCents: parseCents(discount),
        totalCents: parseCents(total),
        notices: switch (map['notices']) {
          final List<Object?> notices => [
            for (final notice in notices)
              if (notice is String) notice,
          ],
          _ => const [],
        },
      ),
    _ => throw FormatException('No es una cotización', json),
  };

  final List<OrderLine> lines;
  final int subtotalCents;
  final int discountCents;
  final int totalCents;
  final List<String> notices;

  /// Lo que se pidió cotizar (productos y cantidades). El servidor deja
  /// afuera los que ya no están (con su aviso): por esto se sabe si es la
  /// del carrito.
  final List<({String productId, int quantity})> requested;

  /// Para quién se pidió: el correo de la cuenta, o null sin cuenta. Con
  /// otra cuenta, otras promociones.
  final String? owner;

  /// La misma, con lo que se pidió y para quién.
  Quote forRequest(
    List<({String productId, int quantity})> lines, {
    String? owner,
  }) => Quote(
    lines: this.lines,
    subtotalCents: subtotalCents,
    discountCents: discountCents,
    totalCents: totalCents,
    notices: notices,
    requested: lines,
    owner: owner,
  );

  /// La línea de [productId] que se compra (no un regalo), si está.
  OrderLine? lineOf(String productId) => lines
      .where((line) => !line.isGift && line.productId == productId)
      .firstOrNull;

  /// Los regalos.
  List<OrderLine> get gifts => [
    for (final line in lines)
      if (line.isGift) line,
  ];
}
