import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import '../../theme/brand_colors.dart';

/// Lo que la tienda dice del stock: solo lo necesario, nunca cuántas
/// unidades hay en total.
String stockText(int stock) => switch (stock) {
  <= 0 => 'Agotado',
  1 => 'Última unidad',
  <= 5 => 'Últimas $stock',
  _ => 'Disponible',
};

/// [stockText] de [product], en rojo cuando quedan pocas o ninguna.
class StockNote extends StatelessWidget {
  const StockNote(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      stockText(product.stock),
      style: theme.textTheme.labelMedium?.copyWith(
        color: product.stock <= 5
            ? NeilsColors.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
