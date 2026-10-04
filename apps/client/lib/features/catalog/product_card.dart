import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import '../../common/money.dart';
import '../../theme/neils_theme.dart';
import '../shared/press_scale.dart';
import '../shared/swoosh.dart';

/// Un producto en una grilla: foto, nombre, precio subrayado con el swoosh de
/// la marca y "Agregar". Toma el ancho que le dé la grilla.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onAdd});

  final Product product;

  /// Agrega una unidad al carrito.
  final VoidCallback onAdd;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 4 / 3, child: _Photo(product.imageUrl)),
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
                _Price(product),
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
      ),
    );
  }
}

/// El precio que se paga hoy, con el swoosh debajo. En promoción, al lado va
/// el precio normal tachado.
class _Price extends StatelessWidget {
  const _Price(this.product);

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                style: NeilsText.price(),
              ),
              // Sube para quedar pegado a los números, como en el logo.
              Transform.translate(
                offset: const Offset(0, -5),
                child: const Swoosh(),
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

/// La foto del producto, o una canasta sobre fondo neutro si no tiene o no
/// carga. Decorativa: el nombre ya dice qué es.
class _Photo extends StatelessWidget {
  const _Photo(this.url);

  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.shopping_basket_outlined,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    final url = this.url;
    return ExcludeSemantics(
      child: url == null
          ? placeholder
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
