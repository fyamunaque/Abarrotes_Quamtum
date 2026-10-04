/// Soles con dos decimales, como en la web y Android: `S/ 4.50`. El espacio es
/// no separable, así "S/" nunca queda solo al final de una línea.
String formatSoles(int cents) {
  final sign = cents < 0 ? '-' : '';
  final amount = cents.abs();
  final decimals = (amount % 100).toString().padLeft(2, '0');
  return '${sign}S/ ${amount ~/ 100}.$decimals';
}
