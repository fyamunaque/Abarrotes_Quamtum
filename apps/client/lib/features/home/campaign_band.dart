import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../catalog/catalog_providers.dart';
import '../../catalog/product.dart';
import '../../router/routes.dart';
import '../../theme/palette.dart';

/// Los tipos de promoción por cantidad: los que dan título a la campaña.
const _quantityOfferTypes = {'buyXPayY', 'extraUnit'};

/// El título de la campaña: la descripción de la primera promoción por
/// cantidad de [products] ("3x2 en Jamonada especial"); sin ninguna, el
/// general.
String campaignTitle(List<Product> products) =>
    [
      for (final product in products)
        for (final offer in product.offers)
          if (_quantityOfferTypes.contains(offer.type)) offer.description,
    ].firstOrNull ??
    'Promociones para tu negocio';

/// "3 productos en promoción hoy" (o "1 producto…").
String campaignSubtitle(int total) =>
    '$total ${total == 1 ? 'producto' : 'productos'} en promoción hoy';

/// La franja roja de la campaña de la portada: la primera promoción por
/// cantidad del día, cuántos productos están en promoción y "Ver
/// promociones". Sale de lo que ya trae la portada ([onSalePageProvider]).
/// Mientras carga o si falla, no ocupa lugar.
class CampaignBand extends ConsumerWidget {
  const CampaignBand({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(onSalePageProvider).value;
    if (page == null) return const SizedBox.shrink();
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final onBrand = palette.onBrand;
    return Material(
      color: palette.brandFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 14,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    campaignTitle(page.items),
                    style: text.titleLarge?.copyWith(color: onBrand),
                  ),
                ),
                if (page.total > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    campaignSubtitle(page.total),
                    style: text.bodyMedium?.copyWith(color: onBrand),
                  ),
                ],
              ],
            ),
            OutlinedButton(
              onPressed: () => context.go(Routes.promotions),
              style: OutlinedButton.styleFrom(
                foregroundColor: onBrand,
                side: BorderSide(color: onBrand),
              ),
              child: const Text('Ver promociones'),
            ),
          ],
        ),
      ),
    );
  }
}
