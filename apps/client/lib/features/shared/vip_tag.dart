import 'package:flutter/material.dart';

import '../../theme/palette.dart';

/// "VIP" junto a un precio de cliente VIP: el rojo de la marca sobre blanco,
/// con un borde fino del mismo rojo. El lector de pantalla dice "Precio VIP".
class VipTag extends StatelessWidget {
  const VipTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.brandText),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'VIP',
        semanticsLabel: 'Precio VIP',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.palette.brandText,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
