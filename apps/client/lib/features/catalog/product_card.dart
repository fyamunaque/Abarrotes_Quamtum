import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import '../shared/press_scale.dart';
import 'price_tag.dart';
import 'product_photo.dart';

/// Un producto en una grilla: foto, nombre, precio subrayado con el swoosh de
/// la marca y "Agregar". Toma el ancho que le dé la grilla.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    this.onTap,
  });

  final Product product;

  /// Agrega una unidad al carrito.
  final VoidCallback onAdd;

  /// Tocar la tarjeta (fuera de "Agregar"): abre el detalle.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // El nombre siempre ocupa dos líneas, así las tarjetas de una fila quedan
    // parejas aunque un nombre sea corto.
    final nameStyle = theme.textTheme.titleMedium!;
    final nameHeight =
        MediaQuery.textScalerOf(context).scale(nameStyle.fontSize!) *
        (nameStyle.height ?? 1.2) *
        2;
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(onTap: onTap, child: _content(nameStyle, nameHeight)),
    );
  }

  Widget _content(TextStyle nameStyle, double nameHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(aspectRatio: 4 / 3, child: ProductPhoto(product.imageUrl)),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: nameHeight,
                child: Text(
                  product.name,
                  style: nameStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              PriceTag(product),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PressScale(
                  enabled: product.inStock,
                  child: FilledButton.tonalIcon(
                    onPressed: product.inStock ? onAdd : null,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: Text(product.inStock ? 'Agregar' : 'Agotado'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
