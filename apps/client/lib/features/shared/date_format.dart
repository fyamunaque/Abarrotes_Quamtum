import 'package:flutter/material.dart';

/// "4 oct 2026, 15:30" en la hora del dispositivo y en el idioma de la app.
String formatDateTime(BuildContext context, DateTime instant) {
  final localizations = MaterialLocalizations.of(context);
  final local = instant.toLocal();
  return '${localizations.formatMediumDate(local)}, '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

/// Un día de la tienda (un vencimiento, la vigencia de una promoción):
/// "7 oct 2026". Del servidor llega a las 00:00 UTC: se toma la fecha tal
/// cual, sin pasarla a la hora local (que la correría al día anterior).
String formatStoreDay(BuildContext context, DateTime day) {
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatShortMonthDay(DateTime(day.year, day.month, day.day))} '
      '${day.year}';
}
