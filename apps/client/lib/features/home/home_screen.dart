import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../catalog/catalog_providers.dart';
import '../../offers/offers_providers.dart';
import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import '../../theme/brand_colors.dart';
import '../../theme/brand_images.dart';
import '../catalog/category_card.dart';
import '../offers/exclusive_offers.dart';
import '../shared/account.dart';
import '../shared/brand.dart';
import '../shared/brand_hero.dart';
import '../shared/card_strip.dart';
import '../shared/diagonal_band.dart';
import '../shared/store_search_field.dart';
import 'product_tabs.dart';
import 'promotions_banner.dart';

/// Inicio, para negocios. En escritorio: el titular con sus botones, los
/// sellos, "Nuestras categorías", la banda de promociones y las pestañas
/// Frecuentes, Sugeridos y Promos ([ProductTabs]). En el teléfono: el saludo,
/// el buscador, las pestañas, las categorías en una fila y la banda. Para una cuenta VIP, además
/// sus ofertas exclusivas. Deslizar hacia abajo vuelve a pedir el perfil, las
/// categorías y las promociones.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= AccountActions.wideFrom;
    return PublicScaffold(
      maxWidth: 1120,
      onRefresh: () async {
        await ref.read(sessionProvider.notifier).refreshProfile();
        ref
          ..invalidate(exclusiveOffersProvider)
          ..invalidate(categoriesProvider)
          ..invalidate(onSaleProductsProvider);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: wide
            ? [
                BrandHero(
                  titleStart: 'Tu negocio siempre abastecido ',
                  titleAccent: "con Neil's.",
                  body:
                      'Insumos gastronómicos de calidad, con precios '
                      'competitivos y entrega confiable.',
                  image: BrandImages.hero,
                  actions: [
                    FilledButton.icon(
                      onPressed: () => context.go(Routes.catalog),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Ver catálogo'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go(Routes.promotions),
                      child: const Text('Ver promociones'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const TrustBadges(),
                const SizedBox(height: 40),
                const _Categories(),
                const PromotionsBanner(),
                const SizedBox(height: 32),
                const ProductTabs(),
                const SizedBox(height: 24),
                const ExclusiveOffers(),
              ]
            : const [
                _Greeting(),
                SizedBox(height: 16),
                StoreSearchField(),
                SizedBox(height: 20),
                ProductTabs(),
                SizedBox(height: 16),
                _Categories(),
                PromotionsBanner(),
                SizedBox(height: 24),
                ExclusiveOffers(),
              ],
      ),
    );
  }
}

/// El saludo del teléfono: "¡Hola, Ana!" (sin cuenta, "¡Hola!"), lo que
/// ofrece la tienda y una franja chica de la marca.
class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final name = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user.name.trim().split(RegExp(r'\s+')).first,
      _ => null,
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  name == null ? '¡Hola!' : '¡Hola, $name!',
                  style: text.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Abastece tu negocio con los mejores productos.',
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          height: 88,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const DiagonalBand(
              image: BrandImages.hero,
              child: Opacity(opacity: 0.7, child: NeilsLogo.white(height: 36)),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Nuestras categorías": una tarjeta por categoría, que abre el catálogo
/// filtrado. En escritorio en una cuadrícula de 4 columnas; en el teléfono,
/// en una fila que se desliza. Los colores van en orden, así dos vecinas no
/// se repiten. Mientras cargan o si fallan, no ocupan lugar.
class _Categories extends ConsumerWidget {
  const _Categories();

  static const _gap = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value;
    if (categories == null || categories.isEmpty) {
      return const SizedBox.shrink();
    }
    final cards = [
      for (final (i, category) in categories.indexed)
        CategoryCard(
          key: ValueKey(category.id),
          category: category,
          colors: PlaceholderColors.pairs[i % PlaceholderColors.pairs.length],
          onTap: () => context.go(Routes.catalogOf(category.id)),
        ),
    ];
    const title = 'Nuestras categorías';
    if (MediaQuery.sizeOf(context).width < AccountActions.wideFrom) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: CardStrip(title: title, cardWidth: 140, children: cards),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const columns = 4;
              final width =
                  (constraints.maxWidth - _gap * (columns - 1)) / columns;
              return Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (final card in cards) SizedBox(width: width, child: card),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
