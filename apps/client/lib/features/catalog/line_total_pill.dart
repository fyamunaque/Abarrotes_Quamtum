import 'package:flutter/material.dart';

import '../../common/money.dart';
import '../../theme/palette.dart';

/// Lo que cuestan las unidades elegidas, en la pastilla verde de las
/// maquetas ([NeilsPalette.money] sobre [NeilsPalette.moneyTint], 5,5:1).
class LineTotalPill extends StatelessWidget {
  const LineTotalPill(this.cents, {super.key});

  final int cents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.palette.moneyTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatSoles(cents),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.palette.money,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
