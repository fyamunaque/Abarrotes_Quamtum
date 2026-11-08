import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import '../../theme/brand_colors.dart';

/// Las promociones por cantidad y de regalo de un producto en insignias
/// cortas: "2x1", "2.ª al 50 %" o "+ regalo", en el rojo de la marca. El
/// lector de pantalla dice lo que da cada una ("Regalo: Sal 1 kg por cada
/// 2"). Sin ofertas no ocupa lugar.
class OfferBadges extends StatelessWidget {
  const OfferBadges(this.offers, {super.key});

  final List<ProductOffer> offers;

  /// El texto corto de [offer].
  static String badgeText(ProductOffer offer) =>
      offer.type == 'gift' ? '+ regalo' : offer.label;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: NeilsColors.onPrimary, fontWeight: FontWeight.w700);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final offer in offers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: NeilsColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText(offer),
              semanticsLabel: offer.description,
              style: style,
            ),
          ),
      ],
    );
  }
}

/// Cada oferta de un producto con lo que da ("2x1 en este producto") y su
/// título debajo, si tiene. Para el detalle.
class OfferDescriptions extends StatelessWidget {
  const OfferDescriptions(this.offers, {super.key});

  final List<ProductOffer> offers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final offer in offers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  size: 20,
                  color: NeilsColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.description, style: theme.textTheme.bodyLarge),
                      if (offer.title case final title?)
                        Text(title, style: muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
