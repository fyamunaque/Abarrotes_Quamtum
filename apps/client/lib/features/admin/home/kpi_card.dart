import 'package:flutter/material.dart';

import '../../../theme/brand_colors.dart';
import '../../../theme/neils_theme.dart';

/// Un indicador del inicio del panel: el ícono en un cuadro rojo claro, el
/// título, la cifra grande en rojo y un detalle ("2 pedidos").
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: NeilsColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: NeilsColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: NeilsText.price(
                        fontSize: 24,
                        color: NeilsColors.primary,
                      ),
                    ),
                    if (detail case final detail?)
                      Text(
                        detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
