import 'package:flutter/material.dart';

import '../../../theme/brand_colors.dart';

/// "VIP" en una píldora naranja claro: marca lo que es solo para clientes
/// VIP (p. ej. una promoción). El texto va en tinta, que sobre el naranja
/// claro se lee bien; el ícono, en el naranja oscuro de la marca.
class VipBadge extends StatelessWidget {
  const VipBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.labelSmall;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: BoxDecoration(
        color: NeilsColors.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 14,
            color: NeilsColors.primaryDark,
          ),
          const SizedBox(width: 4),
          Text(
            'VIP',
            style: text?.copyWith(
              color: NeilsColors.ink,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
