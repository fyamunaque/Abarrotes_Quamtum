/// Los montos se guardan en céntimos enteros y viajan en el JSON como
/// texto, sin ceros finales ("4.5", "12", "0.05").
String formatMoney(int cents) {
  final sign = cents < 0 ? '-' : '';
  final units = cents.abs() ~/ 100;
  final rest = cents.abs() % 100;
  if (rest == 0) return '$sign$units';
  final decimals = rest.toString().padLeft(2, '0');
  return '$sign$units.${decimals.endsWith('0') ? decimals[0] : decimals}';
}

/// [amount] en céntimos, o null si tiene más de dos decimales.
int? toCents(num amount) {
  final cents = (amount * 100).round();
  return (amount * 100 - cents).abs() < 1e-6 ? cents : null;
}
