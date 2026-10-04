/// Un monto como lo manda el servidor (`"4.5"`, `"10"`, `"8.90"`) en céntimos.
/// Lanza [FormatException] si no es un monto con dos decimales como máximo.
int parseCents(String amount) {
  final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(amount);
  if (match == null) throw FormatException('No es un monto', amount);
  final cents =
      int.parse(match[2]!) * 100 + int.parse((match[3] ?? '').padRight(2, '0'));
  return match[1] == '-' ? -cents : cents;
}

/// Soles con dos decimales, como en la web y Android: `S/ 4.50`. El espacio es
/// no separable, así "S/" nunca queda solo al final de una línea.
String formatSoles(int cents) {
  final sign = cents < 0 ? '-' : '';
  final amount = cents.abs();
  final decimals = (amount % 100).toString().padLeft(2, '0');
  return '${sign}S/ ${amount ~/ 100}.$decimals';
}

/// Un monto escrito por la persona ("24.90", "24,9", "24") en céntimos, o null
/// si no lo es: acepta punto o coma y dos decimales como máximo, sin signo.
int? parseSolesInput(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.startsWith('-')) return null;
  try {
    return parseCents(normalized);
  } on FormatException {
    return null;
  }
}

/// Un monto para un campo de texto: `24.90` (sin "S/", que va en el campo).
String formatSolesInput(int cents) =>
    '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
