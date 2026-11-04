import 'package:flutter/material.dart';

import '../../../admin/promotions/promotion.dart';
import '../../../common/days.dart';
import '../../shared/date_format.dart';

/// Avisa que la promoción se cruza con [overlaps] (se acumulan) y pregunta
/// si se guarda igual. true con "Crear igual"; false con "Volver" o al
/// cerrarlo.
Future<bool> showOverlapDialog(
  BuildContext context,
  List<PromotionOverlapItem> overlaps, {
  String confirmLabel = 'Crear igual',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: const Text('Se cruza con otras promociones'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final overlap in overlaps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${overlap.label} · ${overlap.audience.label} · '
                    '${formatStoreRange(context, parseDay(overlap.startDate), parseDay(overlap.endDate))}',
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Se acumulan: el cliente recibe todas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
