import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import 'price_tag.dart';
import 'product_photo.dart';
import 'product_tile.dart';
import 'promo_ribbon.dart';
import 'stock_note.dart';

/// Un producto en una cuadrícula (escritorio): la foto con la cinta de su
/// promoción, el código y el nombre, el precio y el stock, y debajo la
/// cantidad, lo que costaría y "Agregar" (o "Editar", si ya está en el
/// carrito). Agrega por su cuenta. El nombre ocupa siempre dos líneas, así
/// las tarjetas de una fila tienen el mismo alto. Toma el ancho que le dé la
/// cuadrícula.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Product product;

  /// Tocar la tarjeta (fuera de los botones): abre el detalle.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nameStyle = Theme.of(context).textTheme.titleSmall!;
    final nameHeight =
        MediaQuery.textScalerOf(context).scale(nameStyle.fontSize!) *
        (nameStyle.height ?? 1.2) *
        2;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductPhoto(
                    product.imageUrl,
                    name: product.name,
                    colorKey: product.category?.id,
                  ),
                  PositionedDirectional(
                    top: 0,
                    end: 12,
                    child: PromoRibbon(product.offers),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: nameHeight,
                    child: Text(
                      productTitle(product),
                      style: nameStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PriceTag(product),
                  const SizedBox(height: 2),
                  StockNote(product),
                  const SizedBox(height: 12),
                  ProductQuantityActions(product: product, stacked: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
