import 'package:flutter/material.dart';

import 'date_format.dart';

/// "Fechas", o el período elegido ("7 – 14 oct 2026") con la "x" para
/// quitarlo. Son días de la tienda, ambos incluidos, hasta hoy.
class DatesFilter extends StatelessWidget {
  const DatesFilter({
    super.key,
    required this.from,
    required this.to,
    required this.onChanged,
    this.helpText = 'Entre',
  });

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onChanged;

  /// El título del calendario (p. ej. "Pedidos entre").
  final String helpText;

  Future<void> _pick(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: switch ((from, to)) {
        (final from?, final to?) => DateTimeRange(start: from, end: to),
        _ => null,
      },
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      helpText: helpText,
      saveText: 'Listo',
    );
    if (picked != null) onChanged(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final range = switch ((from, to)) {
      (final from?, final to?) => formatStoreRange(context, from, to),
      _ => null,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pick(context),
          icon: const Icon(Icons.date_range_outlined),
          label: Text(range ?? 'Fechas'),
        ),
        if (range != null)
          IconButton(
            tooltip: 'Quitar las fechas',
            icon: const Icon(Icons.close),
            onPressed: () => onChanged(null, null),
          ),
      ],
    );
  }
}
