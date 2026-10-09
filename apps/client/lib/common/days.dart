// Los días de la tienda viajan como texto `AAAA-MM-DD` (hora de Lima en el
// servidor). En la app son un DateTime local a las 00:00.

/// `AAAA-MM-DD` de [day].
String formatDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// [day] (`AAAA-MM-DD`) como fecha local a las 00:00. Lanza
/// [FormatException] si no tiene ese formato.
DateTime parseDay(String day) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(day);
  if (match == null) throw FormatException('No es un día AAAA-MM-DD', day);
  return DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
}
