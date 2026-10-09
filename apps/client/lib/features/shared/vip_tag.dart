import 'package:flutter/material.dart';

import '../../theme/brand_colors.dart';

/// "VIP" junto a un precio de cliente VIP: el rojo de la marca sobre crema,
/// con un borde fino del mismo rojo. El lector de pantalla dice "Precio VIP".
class VipTag extends StatelessWidget {
  const VipTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: NeilsColors.cream,
        border: Border.all(color: NeilsColors.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'VIP',
        semanticsLabel: 'Precio VIP',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: NeilsColors.accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
