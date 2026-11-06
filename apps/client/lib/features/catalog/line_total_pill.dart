import 'package:flutter/material.dart';

import '../../common/money.dart';
import '../../theme/brand_colors.dart';

/// Lo que cuestan las unidades elegidas, en la pastilla verde de las
/// maquetas ([NeilsColors.money] sobre [NeilsColors.moneyTint], 5,5:1).
class LineTotalPill extends StatelessWidget {
  const LineTotalPill(this.cents, {super.key});

  final int cents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: NeilsColors.moneyTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatSoles(cents),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: NeilsColors.money,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
