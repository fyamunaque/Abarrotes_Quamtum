import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/product.dart';
import '../shared/card_strip.dart';
import 'product_card.dart';
import '../../router/navigation.dart';

/// Una fila de productos con su [title] ("Más de Lácteos", "Promociones de
/// hoy"), que se desliza de costado. Cada tarjeta, como en el catálogo:
/// tocarla abre el detalle y "Agregar" suma una unidad.
///
/// Sin productos no ocupa lugar.
class ProductStrip extends ConsumerWidget {
  const ProductStrip({super.key, required this.title, required this.products});

  final String title;
  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) return const SizedBox.shrink();
    return CardStrip(
      title: title,
      children: [
        for (final product in products)
          ProductCard(
            key: ValueKey(product.id),
            product: product,
            onTap: () => context.openProduct(product.id, product: product),
          ),
      ],
    );
  }
}
