import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import '../../theme/palette.dart';
import 'offer_badges.dart';
import 'stock_note.dart';

/// La etiqueta de mercado: recta, con un borde punteado en el rojo de la
/// marca y el texto en el rojo de los textos, sin relleno. Muestra la
/// primera promoción de un producto ("2x1", "3x2", "2.ª al 50 %",
/// "+ regalo"); el lector de pantalla dice lo que da cada una. Sin
/// promociones no ocupa lugar. [PromoTag.gift] es la del regalo del carrito.
class PromoTag extends StatelessWidget {
  const PromoTag(this.offers, {super.key}) : _text = null;

  /// "Regalo": la línea de un regalo en el carrito.
  const PromoTag.gift({super.key}) : offers = const [], _text = 'Regalo';

  final List<ProductOffer> offers;
  final String? _text;

  @override
  Widget build(BuildContext context) {
    final text = _text ?? offers.map(OfferBadges.badgeText).firstOrNull;
    if (text == null) return const SizedBox.shrink();
    final palette = context.palette;
    final tag = CustomPaint(
      painter: DashedBorderPainter(color: palette.brandFill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: palette.brandText, fontWeight: FontWeight.w700),
        ),
      ),
    );
    if (_text != null) return tag;
    return Semantics(
      container: true,
      label: [for (final offer in offers) offer.description].join('. '),
      child: ExcludeSemantics(child: tag),
    );
  }
}

/// La promoción de [product] ([PromoTag]) en lugar de "Disponible"; los
/// avisos de stock ("Últimas 4", "Agotado") se ven siempre, al lado.
class TagOrStock extends StatelessWidget {
  const TagOrStock(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final hasOffer = product.offers.isNotEmpty;
    if (!hasOffer) return StockNote(product);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PromoTag(product.offers),
        if (product.stock <= 5) StockNote(product),
      ],
    );
  }
}

/// Un borde redondeado punteado (radio 6, trazo de 1,5 y rayas de [dash]).
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 6,
    this.dash = 4,
    this.gap = 3,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius ||
      old.dash != dash ||
      old.gap != gap;
}
