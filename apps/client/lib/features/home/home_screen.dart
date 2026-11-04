import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../catalog/catalog_providers.dart';
import '../../catalog/category.dart';
import '../../catalog/product.dart';
import '../../offers/offer.dart';
import '../../offers/offers_providers.dart';
import '../../router/routes.dart';
import '../../session/session_provider.dart';
import '../../theme/brand_colors.dart';
import '../catalog/product_strip.dart';
import '../offers/exclusive_offers.dart';
import '../shared/brand.dart';
import '../shared/swoosh.dart';

/// Inicio: presentación de la tienda, accesos al catálogo y al registro, las
/// categorías y las promociones de hoy. Para una cuenta VIP, además sus
/// ofertas exclusivas. Deslizar hacia abajo vuelve a pedir el perfil, las
/// categorías y las promociones.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return PublicScaffold(
      // El logo grande ya está en la portada.
      showLogo: false,
      onRefresh: () async {
        await ref.read(sessionProvider.notifier).refreshProfile();
        ref
          ..invalidate(exclusiveOffersProvider)
          ..invalidate(categoriesProvider)
          ..invalidate(onSaleProductsProvider);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El logo ya trae su fondo naranja: hace de portada.
          const Center(child: NeilsLogo(height: 200)),
          const SizedBox(height: 24),
          const _Headline(),
          const SizedBox(height: 12),
          Text(
            'Arroz, aceite, lácteos y todo lo de la semana, con nuestros '
            'precios y promociones. Te lo llevamos a casa o lo recoges en la '
            'tienda.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => context.go(Routes.catalog),
                child: const Text('Ver el catálogo'),
              ),
              OutlinedButton(
                onPressed: () => context.go(Routes.register),
                child: const Text('Crear una cuenta'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const _Categories(),
          const _TodaysDeals(),
          const ExclusiveOffers(),
        ],
      ),
    );
  }
}

/// El titular, con el swoosh del logo dibujándose bajo la segunda línea: el
/// único momento animado de la portada.
class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium;
    // MergeSemantics por fuera: así el encabezado y las dos líneas quedan en
    // un solo nodo.
    return MergeSemantics(
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tus abarrotes,', style: style),
            // El swoosh mide lo mismo que la línea que subraya.
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('a la puerta de tu casa', style: style),
                  // Sube un poco para pegarse a las letras, como en el logo.
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: const AnimatedSwoosh(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Categorías": un acceso a cada una, que abre el catálogo filtrado. Los
/// colores de los marcadores sin foto van en orden, así dos vecinas no se
/// repiten (por el id, varias caían en el mismo). Mientras cargan o si
/// fallan, no ocupan lugar.
class _Categories extends ConsumerWidget {
  const _Categories();

  /// El ancho mínimo de cada acceso: 2 columnas en un teléfono, hasta 5.
  static const _minTileWidth = 170.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value;
    if (categories == null || categories.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Categorías',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / _minTileWidth)
                  .floor()
                  .clamp(2, 5);
              final width =
                  (constraints.maxWidth - _gap * (columns - 1)) / columns;
              return Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (final (i, category) in categories.indexed)
                    SizedBox(
                      width: width,
                      child: _CategoryTile(
                        category,
                        colors: PlaceholderColors
                            .pairs[i % PlaceholderColors.pairs.length],
                        key: ValueKey(category.id),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile(this.category, {required this.colors, super.key});

  final Category category;
  final (Color background, Color foreground) colors;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = colors;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(Routes.catalogOf(category.id)),
        child: ConstrainedBox(
          // Dos líneas de nombre caben sin que unas tarjetas crezcan más que
          // otras (salvo con el texto agrandado).
          constraints: const BoxConstraints(minHeight: 76),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: foreground),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Promociones de hoy": los productos en oferta, con su precio y
/// "Agregar". A una cuenta VIP no le repite los que ya van en "Ofertas
/// exclusivas". Sin promociones, no ocupa lugar.
class _TodaysDeals extends ConsumerWidget {
  const _TodaysDeals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exclusive = {
      for (final offer
          in ref.watch(exclusiveOffersProvider).value ?? const <Offer>[])
        offer.productId,
    };
    final products = [
      for (final product
          in ref.watch(onSaleProductsProvider).value ?? const <Product>[])
        if (!exclusive.contains(product.id)) product,
    ];
    if (products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ProductStrip(title: 'Promociones de hoy', products: products),
    );
  }
}
