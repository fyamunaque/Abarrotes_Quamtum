import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import '../../theme/brand_colors.dart';
import 'offer_badges.dart';

/// La cinta roja de la esquina de un producto, con el borde de abajo en V:
/// la primera de sus promociones por cantidad o de regalo ("2x1", "16 + 2",
/// "+ regalo"). El lector de pantalla dice lo que da cada una. Sin
/// promociones no ocupa lugar. La ubica quien la usa (arriba a la derecha).
class PromoRibbon extends StatelessWidget {
  const PromoRibbon(this.offers, {super.key});

  final List<ProductOffer> offers;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: NeilsColors.onPrimary,
      fontWeight: FontWeight.w700,
      height: 1.1,
    );
    return Semantics(
      container: true,
      label: [for (final offer in offers) offer.description].join('. '),
      child: ExcludeSemantics(
        child: ClipPath(
          clipper: const _RibbonClipper(),
          child: ColoredBox(
            color: NeilsColors.primary,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
              child: Text(OfferBadges.badgeText(offers.first), style: style),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un rectángulo con el borde de abajo en V (8 px de profundidad).
class _RibbonClipper extends CustomClipper<Path> {
  const _RibbonClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width / 2, size.height - 8)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_RibbonClipper oldClipper) => false;
}
