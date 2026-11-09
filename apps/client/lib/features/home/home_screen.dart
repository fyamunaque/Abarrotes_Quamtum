import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../catalog/catalog_providers.dart';
import '../../offers/offers_providers.dart';
import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import '../../store/store_providers.dart';
import '../../theme/brand_images.dart';
import '../admin/home/greeting.dart';
import '../catalog/category_card.dart';
import '../offers/exclusive_offers.dart';
import '../shared/account.dart';
import '../shared/brand.dart';
import '../shared/brand_hero.dart';
import '../shared/card_strip.dart';
import '../shared/store_search_field.dart';
import 'product_tabs.dart';
import 'campaign_band.dart';
import 'home_entrance.dart';
import 'store_footer.dart';
import '../../theme/palette.dart';

/// Inicio, para negocios. En escritorio: el titular con lo que se vende, el
/// horario de la tienda y sus botones, las pestañas Frecuentes, Sugeridos y
/// Promos ([ProductTabs]), la franja de la campaña, las categorías y el pie.
/// En el teléfono: el saludo, el buscador, las pestañas en filas, la franja y
/// las categorías en una fila. Para una cuenta VIP, además sus ofertas
/// exclusivas. Deslizar hacia abajo vuelve a pedir el perfil, las
/// categorías y las promociones.
///
/// El titular entra una vez por sesión ([homeEntranceProvider]).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Si el titular entra esta vez: solo la primera de la sesión.
  late final bool _entrance = !ref.read(homeEntranceProvider);

  @override
  void initState() {
    super.initState();
    if (_entrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(homeEntranceProvider.notifier).seen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AccountActions.wideFrom;
    final hours = ref.watch(storeSettingsProvider).value?.openingHours?.trim();
    return PublicScaffold(
      maxWidth: 1120,
      onRefresh: () async {
        await ref.read(sessionProvider.notifier).refreshProfile();
        ref
          ..invalidate(exclusiveOffersProvider)
          ..invalidate(categoriesProvider)
          ..invalidate(onSalePageProvider)
          ..invalidate(frequentProductsProvider)
          ..invalidate(suggestedProductsProvider);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: wide
            ? [
                BrandHero(
                  titleStart: 'Insumos para restaurantes ',
                  titleAccent: 'y cafeterías',
                  body:
                      'Embutidos, lácteos, panes y abarrotes, con entrega a '
                      'tu negocio o recojo en tienda.',
                  note: hours == null || hours.isEmpty
                      ? null
                      : 'Atendemos $hours',
                  image: BrandImages.hero,
                  entrance: _entrance,
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
                const SizedBox(height: 40),
                const ProductTabs(),
                const SizedBox(height: 24),
                const CampaignBand(),
                const SizedBox(height: 40),
                const _Categories(),
                const ExclusiveOffers(),
                const SizedBox(height: 16),
                const StoreFooter(),
              ]
            : const [
                _Greeting(),
                SizedBox(height: 16),
                StoreSearchField(),
                SizedBox(height: 20),
                ProductTabs(),
                SizedBox(height: 8),
                CampaignBand(),
                SizedBox(height: 24),
                _Categories(),
                ExclusiveOffers(),
              ],
      ),
    );
  }
}

/// El saludo corto del teléfono, según la hora de Lima: "Buenos días, Ana"
/// (sin cuenta, "Buenos días").
class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user.name.trim().split(RegExp(r'\s+')).first,
      _ => null,
    };
    final greeting = greetingFor(DateTime.now().toUtc());
    return Semantics(
      header: true,
      child: Text(
        name == null || name.isEmpty ? greeting : '$greeting, $name',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
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
          colors: context
              .palette
              .placeholderPairs[i % context.palette.placeholderPairs.length],
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
