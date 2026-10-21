import 'package:flutter/material.dart';

/// "4 oct 2026, 15:30" en la hora del dispositivo y en el idioma de la app.
String formatDateTime(BuildContext context, DateTime instant) {
  final localizations = MaterialLocalizations.of(context);
  final local = instant.toLocal();
  return '${localizations.formatMediumDate(local)}, '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

/// "4 oct 2026": la fecha de un instante (p. ej. un alta) en la hora del
/// dispositivo.
String formatDate(BuildContext context, DateTime instant) =>
    MaterialLocalizations.of(context).formatShortDate(instant.toLocal());

/// Un día de la tienda (un vencimiento, la vigencia de una promoción):
/// "7 oct 2026". Del servidor llega a las 00:00 UTC: se toma la fecha tal
/// cual, sin pasarla a la hora local (que la correría al día anterior).
String formatStoreDay(BuildContext context, DateTime day) {
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatShortMonthDay(DateTime(day.year, day.month, day.day))} '
      '${day.year}';
}

/// Un período de días de la tienda, ambos incluidos: "7 – 14 oct 2026",
/// "28 sept – 5 oct 2026" o, entre años, "28 dic 2026 – 4 ene 2027".
String formatStoreRange(BuildContext context, DateTime start, DateTime end) {
  if (start.year != end.year) {
    return '${formatStoreDay(context, start)} – ${formatStoreDay(context, end)}';
  }
  final localizations = MaterialLocalizations.of(context);
  final from = start.month == end.month
      ? '${start.day}'
      : localizations.formatShortMonthDay(start);
  return '$from – ${formatStoreDay(context, end)}';
}

/// Cuánto pasó desde [since] hasta [now]: "hace menos de 1 min",
/// "hace 12 min", "hace 1 h 5 min" o "hace 2 d".
String formatElapsed(DateTime since, DateTime now) {
  final elapsed = now.difference(since);
  if (elapsed.inMinutes < 1) return 'hace menos de 1 min';
  if (elapsed.inHours < 1) return 'hace ${elapsed.inMinutes} min';
  if (elapsed.inDays < 1) {
    final minutes = elapsed.inMinutes % 60;
    return minutes == 0
        ? 'hace ${elapsed.inHours} h'
        : 'hace ${elapsed.inHours} h $minutes min';
  }
  return 'hace ${elapsed.inDays} d';
}
