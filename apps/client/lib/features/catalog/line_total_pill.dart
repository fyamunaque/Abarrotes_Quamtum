import 'package:flutter/material.dart';

import '../../common/money.dart';
import '../../theme/palette.dart';
import '../shared/value_fade.dart';

/// Lo que cuestan las unidades elegidas, en la pastilla verde de las
/// maquetas ([NeilsPalette.money] sobre [NeilsPalette.moneyTint]). El total
/// cambia con un fundido ([ValueFade]).
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
      child: ValueFade(
        value: cents,
        child: Text(
          formatSoles(cents),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.palette.money,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
