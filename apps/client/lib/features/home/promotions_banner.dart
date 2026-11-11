import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../theme/brand_images.dart';
import '../shared/account.dart';
import '../shared/brand.dart';
import '../shared/diagonal_band.dart';
import '../../theme/palette.dart';

/// La banda roja de la portada: "Promociones para tu negocio", con su texto,
/// "Ver promociones" y la franja diagonal ([BrandImages.promotionsBanner], o
/// el logo en blanco mientras no haya foto).
class PromotionsBanner extends StatelessWidget {
  const PromotionsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AccountActions.wideFrom;
    final text = Theme.of(context).textTheme;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Promociones para tu negocio',
            style: text.headlineSmall?.copyWith(color: context.palette.onBrand),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Soluciones prácticas para restaurantes, fast foods y dark kitchens.',
          style: text.bodyLarge?.copyWith(color: context.palette.onBrand),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.go(Routes.promotions),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.palette.onBrand,
            side: BorderSide(color: context.palette.onBrand),
          ),
          child: const Text('Ver promociones'),
        ),
      ],
    );
    final band = DiagonalBand(
      image: BrandImages.promotionsBanner,
      color: context.palette.brandFillDeep,
      child: Opacity(
        opacity: 0.6,
        child: NeilsLogo.white(height: wide ? 90 : 56),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: context.palette.brandFill,
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 55,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: copy,
                    ),
                  ),
                  Expanded(flex: 45, child: SizedBox(height: 220, child: band)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 110, child: band),
                  Padding(padding: const EdgeInsets.all(20), child: copy),
                ],
              ),
      ),
    );
  }
}
