import 'package:flutter/material.dart';

/// "4 oct 2026, 15:30" en la hora del dispositivo y en el idioma de la app.
String formatDateTime(BuildContext context, DateTime instant) {
  final localizations = MaterialLocalizations.of(context);
  final local = instant.toLocal();
  return '${localizations.formatMediumDate(local)}, '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
