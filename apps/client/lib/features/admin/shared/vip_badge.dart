import 'package:flutter/material.dart';

import '../../../theme/palette.dart';

/// "VIP" en una píldora del tono de lo elegido (rojo claro; en oscuro, rojo
/// hondo): marca lo que es solo para clientes VIP (p. ej. una promoción).
/// El texto va en tinta; el ícono, en el color del texto sobre ese tono.
class VipBadge extends StatelessWidget {
  const VipBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.labelSmall;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: BoxDecoration(
        color: context.palette.brandTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: 14,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'VIP',
            style: text?.copyWith(
              color: context.palette.ink,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
