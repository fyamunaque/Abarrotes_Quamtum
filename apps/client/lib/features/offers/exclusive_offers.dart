import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/days.dart';
import '../../offers/offer.dart';
import '../../offers/offers_providers.dart';
import '../catalog/offer_badges.dart';
import '../catalog/price_tag.dart';
import '../catalog/product_photo.dart';
import '../shared/card_strip.dart';
import '../shared/date_format.dart';
import '../shared/vip_tag.dart';
import '../../router/navigation.dart';

/// "Ofertas exclusivas": las promociones VIP de la cuenta, en una fila que se
/// desliza de costado. Tocar una abre el producto, que ya trae el precio VIP.
///
/// Solo aparece si hay algo que mostrar: sin cuenta VIP, sin ofertas o si no
/// cargan, no ocupa lugar ni deja ninguna pista.
class ExclusiveOffers extends ConsumerWidget {
  const ExclusiveOffers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = switch (ref.watch(exclusiveOffersProvider)) {
      AsyncValue(value: final offers?) when offers.isNotEmpty => offers,
      _ => null,
    };
    if (offers == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: CardStrip(
        title: 'Ofertas exclusivas',
        children: [
          for (final offer in offers)
            _OfferCard(offer, key: ValueKey(offer.id)),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard(this.offer, {super.key});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final until = formatStoreDay(context, parseDay(offer.endDate));
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.openProduct(offer.productId),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ProductPhoto(
                offer.imageUrl,
                name: offer.productName,
                colorKey: offer.categoryId,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.productName,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (offer.title case final title?)
                    Text(
                      title,
                      style: muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  PriceTag.prices(
                    priceCents: offer.priceCents,
                    promoPriceCents: offer.promoPriceCents,
                    vipPrice: offer.vip && offer.deal == null,
                    fontSize: 20,
                  ),
                  // Un NxM, una unidad extra o un regalo: el precio es el
                  // normal y la oferta va en su insignia.
                  if (offer.deal case final deal?) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OfferBadges([deal]),
                        if (offer.vip) const VipTag(),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text('Hasta el $until', style: muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
