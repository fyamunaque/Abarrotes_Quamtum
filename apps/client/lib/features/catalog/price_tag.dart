import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import '../../common/money.dart';
import '../../theme/neils_theme.dart';
import '../shared/swoosh.dart';

/// El precio que se paga hoy, subrayado con el swoosh de la marca. En
/// promoción, al lado va el precio normal tachado.
class PriceTag extends StatelessWidget {
  const PriceTag(this.product, {super.key, this.fontSize = 22});

  final Product product;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = fontSize / 22;
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                formatSoles(product.finalPriceCents),
                style: NeilsText.price(fontSize: fontSize),
              ),
              // Sube para quedar pegado a los números, como en el logo.
              Transform.translate(
                offset: Offset(0, -5 * scale),
                child: Swoosh(height: 8 * scale),
              ),
            ],
          ),
        ),
        if (product.onSale)
          Text(
            formatSoles(product.priceCents),
            // Tachado no se oye: el lector de pantalla dice "Antes".
            semanticsLabel: 'Antes ${formatSoles(product.priceCents)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}
