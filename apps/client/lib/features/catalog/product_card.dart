import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import 'price_tag.dart';
import 'product_photo.dart';
import 'product_tile.dart';
import 'promo_tag.dart';
import '../../theme/motion.dart';

/// Un producto en una cuadrícula (escritorio): la foto, el código y el
/// nombre, la etiqueta de su promoción o el stock ([TagOrStock]), el precio,
/// y debajo la
/// cantidad, lo que costaría y "Agregar" (o "Editar", si ya está en el
/// carrito). Agrega por su cuenta. El nombre ocupa siempre dos líneas, así
/// las tarjetas de una fila tienen el mismo alto. Toma el ancho que le dé la
/// cuadrícula.
class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Product product;

  /// Tocar la tarjeta (fuera de los botones): abre el detalle.
  final VoidCallback? onTap;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

/// Con el mouse encima (solo con un puntero que pasa por encima, en la web),
/// la tarjeta sube 2 px en [NeilsMotion.hover] y la foto se acerca a 1,03
/// dentro de su marco en [NeilsMotion.photoZoom]. Con "reducir animaciones"
/// no se mueve.
class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  void _hover(bool hovered) {
    if (_hovered != hovered) setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final lifted = _hovered && !NeilsMotion.reduced(context);
    final nameStyle = Theme.of(context).textTheme.titleSmall!;
    final nameHeight =
        MediaQuery.textScalerOf(context).scale(nameStyle.fontSize!) *
        (nameStyle.height ?? 1.2) *
        2;
    final card = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRect(
                child: AnimatedScale(
                  scale: lifted ? 1.03 : 1,
                  duration: NeilsMotion.photoZoom,
                  curve: NeilsMotion.ease,
                  child: Hero(
                    tag: productHeroTag(product),
                    child: ProductPhoto(
                      product.imageUrl,
                      name: product.name,
                      colorKey: product.category?.id,
                    ),
                  ),
                ),
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
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TagOrStock(product),
                  ),
                  const SizedBox(height: 6),
                  PriceTag(product),
                  const SizedBox(height: 12),
                  ProductQuantityActions(product: product, stacked: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return MouseRegion(
      onEnter: (_) => _hover(true),
      onExit: (_) => _hover(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: lifted ? -2 : 0),
        duration: NeilsMotion.hover,
        curve: NeilsMotion.ease,
        builder: (_, dy, child) =>
            Transform.translate(offset: Offset(0, dy), child: child),
        child: card,
      ),
    );
  }
}
