/// La tienda trabaja con días de Lima. Perú no usa horario de verano desde
/// 1994, así que la hora de la tienda es siempre UTC-5.
const storeTimeZone = 'America/Lima';
const _utcOffset = Duration(hours: -5);

final _dayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// El día de la tienda (`2026-10-01`) en que cae [instant].
String storeDay(DateTime instant) => _format(instant.toUtc().add(_utcOffset));

/// Las 00:00 de [day] en la tienda, como instante UTC.
DateTime storeDayStart(String day) => _parse(day).subtract(_utcOffset);

/// [day] más [days] días (pueden ser negativos).
String addDays(String day, int days) =>
    _format(_parse(day).add(Duration(days: days)));

/// Días de [from] a [to] (negativo si [to] es anterior).
int daysBetween(String from, String to) =>
    _parse(to).difference(_parse(from)).inDays;

/// Cada día de [from] a [to], ambos incluidos.
List<String> eachDay(String from, String to) => [
  for (var i = 0; i <= daysBetween(from, to); i++) addDays(from, i),
];

/// El lunes de la semana de [day].
String startOfWeek(String day) =>
    addDays(day, -(_parse(day).weekday - DateTime.monday));

/// El primer día del mes de [day].
String startOfMonth(String day) => '${day.substring(0, 8)}01';

/// Las fechas sin hora, como el vencimiento de un producto, se guardan a
/// medianoche UTC y se comparan como día de calendario, sin zona horaria.
DateTime utcMidnight(String day) => _parse(day);

/// El día de calendario de una fecha sin hora (ver [utcMidnight]).
String calendarDay(DateTime date) => _format(date.toUtc());

/// Si [day] es un día real con formato `AAAA-MM-DD` ("2026-02-30" no pasa).
bool isValidDay(String day) {
  if (!_dayPattern.hasMatch(day)) return false;
  final parsed = DateTime.tryParse('${day}T00:00:00Z');
  return parsed != null && _format(parsed) == day;
}

DateTime _parse(String day) => DateTime.parse('${day}T00:00:00Z');

String _format(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
