import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/cart_provider.dart';
import '../../catalog/product.dart';
import '../cart/add_to_cart.dart';
import '../shared/press_scale.dart';
import '../shared/quantity_stepper.dart';
import 'line_total_pill.dart';
import 'price_tag.dart';
import 'product_photo.dart';
import 'promo_tag.dart';
import '../../theme/palette.dart';

/// El nombre de un producto con su código adelante, como en las maquetas
/// ("3580 – Jamonada especial"). Sin código, el nombre solo.
String productTitle(Product product) =>
    product.sku.isEmpty ? product.name : '${product.sku} – ${product.name}';

/// El tag del [Hero] de la foto de un producto: la misma en la fila, la
/// tarjeta y el detalle, así la foto viaja al abrirlo.
String productHeroTag(Product product) => 'producto-${product.id}';

/// Los productos del teléfono en un solo bloque [NeilsPalette.surface] con
/// un borde fino, y una línea entre fila y fila (no al final). Sin
/// productos no ocupa lugar.
class ProductRows extends StatelessWidget {
  const ProductRows({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: palette.line),
            child,
          ],
        ],
      ),
    );
  }
}

/// Un producto en una fila (el teléfono, dentro de [ProductRows]): la foto
/// de 64 px, el código y el nombre, y debajo la etiqueta de su promoción o
/// el stock ([TagOrStock]); el precio a la derecha. En la segunda línea, la
/// cantidad, lo que costaría y "Agregar" (o "Editar", si ya está en el
/// carrito). No es una tarjeta: sin fondo ni sombra propios.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, this.onTap});

  final Product product;

  /// Tocar el producto (fuera de los botones): abre el detalle.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: productHeroTag(product),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox.square(
                        dimension: 64,
                        child: ProductPhoto(
                          product.imageUrl,
                          name: product.name,
                          colorKey: product.category?.id,
                          initialSize: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productTitle(product),
                          style: text.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        TagOrStock(product),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // El precio a la derecha, sin quitarle al nombre más de
                  // un tercio de la fila.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.34,
                    ),
                    child: PriceTag(
                      product,
                      fontSize: 17,
                      alignment: WrapAlignment.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ProductQuantityActions(product: product),
          ],
        ),
      ),
    );
  }
}

/// La cantidad (− y +), lo que costarían esas unidades y el botón:
/// "Agregar" las suma al carrito; si el producto ya está, la cantidad es la
/// del carrito y "Editar" la cambia. Agotado, solo "Agotado", deshabilitado.
///
/// En una fila ([stacked] en false) los tres van seguidos y pasan a dos
/// líneas si no entran; [stacked] pone el botón a todo el ancho debajo (las
/// tarjetas de la cuadrícula).
class ProductQuantityActions extends ConsumerStatefulWidget {
  const ProductQuantityActions({
    super.key,
    required this.product,
    this.stacked = false,
  });

  final Product product;
  final bool stacked;

  @override
  ConsumerState<ProductQuantityActions> createState() =>
      _ProductQuantityActionsState();
}

class _ProductQuantityActionsState
    extends ConsumerState<ProductQuantityActions> {
  /// La cantidad elegida con − y +, hasta que se agrega o se edita. Sin
  /// elegir, la del carrito (o 1).
  int? _chosen;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final inCart = ref.watch(
      cartProvider.select((cart) => cart.quantityOf(product.id)),
    );

    if (!product.inStock) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: widget.stacked ? double.infinity : null,
          child: const PressScale(
            enabled: false,
            child: FilledButton(onPressed: null, child: Text('Agotado')),
          ),
        ),
      );
    }

    final max = product.maxQuantity;
    final quantity = (_chosen ?? (inCart > 0 ? inCart : 1)).clamp(1, max);
    final stepper = QuantityStepper(
      quantity: quantity,
      max: max,
      dense: true,
      onChanged: (value) => setState(() => _chosen = value),
    );
    // Con las promociones por cantidad (2x1, N.ª unidad), como el servidor.
    final total = LineTotalPill(product.totalFor(quantity));
    final button = inCart > 0
        ? OutlinedButton.icon(
            onPressed: () {
              updateCartQuantity(context, ref, product, quantity);
              setState(() => _chosen = null);
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
          )
        : PressScale(
            child: FilledButton(
              onPressed: () {
                addToCart(context, ref, product, quantity);
                setState(() => _chosen = null);
              },
              child: const Text('Agregar'),
            ),
          );

    if (widget.stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En una tarjeta angosta (un teléfono de 320 px), la cantidad y el
          // total se achican antes que desbordarla.
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: stepper,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FittedBox(fit: BoxFit.scaleDown, child: total),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          button,
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [stepper, total, button],
    );
  }
}
