import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/days.dart';
import '../../offers/offer.dart';
import '../../offers/offers_providers.dart';
import '../../router/routes.dart';
import '../catalog/price_tag.dart';
import '../catalog/product_photo.dart';
import '../shared/date_format.dart';

/// "Ofertas exclusivas": las promociones VIP de la cuenta, en una fila que se
/// desliza de costado. Tocar una abre el producto, que ya trae el precio VIP.
///
/// Solo aparece si hay algo que mostrar: sin cuenta VIP, sin ofertas o si no
/// cargan, no ocupa lugar ni deja ninguna pista.
class ExclusiveOffers extends ConsumerStatefulWidget {
  const ExclusiveOffers({super.key});

  @override
  ConsumerState<ExclusiveOffers> createState() => _ExclusiveOffersState();
}

class _ExclusiveOffersState extends ConsumerState<ExclusiveOffers> {
  static const _cardWidth = 200.0;

  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offers = switch (ref.watch(exclusiveOffersProvider)) {
      AsyncValue(value: final offers?) when offers.isNotEmpty => offers,
      _ => null,
    };
    if (offers == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Ofertas exclusivas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          // En la web también con el mouse (arrastrar o la barra).
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
            child: Scrollbar(
              controller: _controller,
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, offer) in offers.indexed) ...[
                        if (i > 0) const SizedBox(width: 12),
                        SizedBox(
                          width: _cardWidth,
                          child: _OfferCard(offer, key: ValueKey(offer.id)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
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
        onTap: () => context.go(Routes.product(offer.productId)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ProductPhoto(offer.imageUrl),
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
                    vipPrice: offer.vip,
                    fontSize: 20,
                  ),
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
