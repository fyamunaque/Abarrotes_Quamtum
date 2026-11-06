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
import 'promo_ribbon.dart';
import 'stock_note.dart';

/// El nombre de un producto con su código adelante, como en las maquetas
/// ("3580 – Jamonada especial"). Sin código, el nombre solo.
String productTitle(Product product) =>
    product.sku.isEmpty ? product.name : '${product.sku} – ${product.name}';

/// Un producto en una lista (el teléfono): la foto, el código y el nombre,
/// el precio y el stock, y debajo la cantidad, lo que costaría y "Agregar"
/// (o "Editar", si ya está en el carrito). La cinta de su promoción va en la
/// esquina.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, this.onTap});

  final Product product;

  /// Tocar el producto (fuera de los botones): abre el detalle.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox.square(
                          dimension: 88,
                          child: ProductPhoto(
                            product.imageUrl,
                            name: product.name,
                            colorKey: product.category?.id,
                            initialSize: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          // Que el nombre no quede debajo de la cinta.
                          padding: EdgeInsetsDirectional.only(
                            end: product.offers.isEmpty ? 0 : 56,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productTitle(product),
                                style: text.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              PriceTag(product, fontSize: 18),
                              const SizedBox(height: 2),
                              StockNote(product),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProductQuantityActions(product: product),
                ],
              ),
            ),
            PositionedDirectional(
              top: 0,
              end: 12,
              child: PromoRibbon(product.offers),
            ),
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
    final total = LineTotalPill(product.finalPriceCents * quantity);
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
