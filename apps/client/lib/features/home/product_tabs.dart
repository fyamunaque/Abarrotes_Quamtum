import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../catalog/catalog_providers.dart';
import '../../catalog/product.dart';
import '../../offers/offer.dart';
import '../../offers/offers_providers.dart';
import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import '../../theme/brand_colors.dart';
import '../catalog/product_card.dart';
import '../catalog/product_grid.dart';
import '../catalog/product_tile.dart';
import '../shared/account.dart';
import '../shared/error_message.dart';

enum _Tab {
  frequent('Frecuentes', Icons.shopping_cart_outlined),
  suggested('Sugeridos', Icons.star_outline),
  promos('Promos', Icons.local_offer_outlined);

  const _Tab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Las pestañas de productos de la portada: Frecuentes (lo que más pide la
/// cuenta; sin cuenta no está), Sugeridos (lo más vendido) y Promos (lo que
/// está en promoción hoy, sin repetir las ofertas exclusivas de un VIP).
///
/// Con cuenta arranca en Frecuentes, con su indicador mientras cargan, y pasa
/// a Sugeridos si la cuenta no tiene ninguno o no se pudieron cargar. Sin
/// cuenta, en Sugeridos. Una vez que la persona elige una, no cambia sola. En el teléfono los productos
/// van en lista; en escritorio, en tarjetas. Se ven hasta [shown], con "Ver
/// más" (o, en Promos, "Ver todas las promociones").
class ProductTabs extends ConsumerStatefulWidget {
  const ProductTabs({super.key});

  static const shown = 8;

  @override
  ConsumerState<ProductTabs> createState() => _ProductTabsState();
}

class _ProductTabsState extends ConsumerState<ProductTabs> {
  _Tab? _chosen;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(
      sessionProvider.select((session) => session is SignedIn),
    );
    final frequent = signedIn ? ref.watch(frequentProductsProvider) : null;
    final tabs = [if (signedIn) _Tab.frequent, _Tab.suggested, _Tab.promos];
    final startOnFrequent = switch (frequent) {
      null => false,
      AsyncValue(value: final list?) => list.isNotEmpty,
      AsyncValue(hasError: true) => false,
      // Cargando: no salta a Sugeridos mientras tanto.
      _ => true,
    };
    final current = switch (_chosen) {
      final chosen? when tabs.contains(chosen) => chosen,
      _ when startOnFrequent => _Tab.frequent,
      _ => _Tab.suggested,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Para el lector de pantalla: el título del grupo, y cada pestaña sigue
        // siendo un nodo propio que dice si está elegida.
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Productos',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tab in tabs)
                ChoiceChip(
                  avatar: Icon(
                    tab.icon,
                    size: 18,
                    color: tab == current
                        ? NeilsColors.onPrimary
                        : NeilsColors.primary,
                  ),
                  label: Text(tab.label),
                  // Más ajustadas que las de Material: las tres entran en una
                  // línea en un teléfono de 390.
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  labelPadding: const EdgeInsetsDirectional.only(
                    start: 4,
                    end: 4,
                  ),
                  showCheckmark: false,
                  selected: tab == current,
                  selectedColor: NeilsColors.primary,
                  labelStyle: TextStyle(
                    color: tab == current
                        ? NeilsColors.onPrimary
                        : NeilsColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() {
                    _chosen = tab;
                    _expanded = false;
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        switch (current) {
          _Tab.frequent => _products(
            frequent ?? const AsyncData([]),
            onRetry: () => ref.invalidate(frequentProductsProvider),
            empty:
                'Cuando hagas tu primer pedido, aquí verás lo que más pides.',
          ),
          _Tab.suggested => _products(
            ref.watch(suggestedProductsProvider),
            onRetry: () => ref.invalidate(suggestedProductsProvider),
            empty: 'Todavía no hay sugeridos.',
          ),
          _Tab.promos => _products(
            _promos(),
            onRetry: () => ref.invalidate(onSaleProductsProvider),
            empty: 'Hoy no hay promociones.',
            footer: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => context.go(Routes.promotions),
                child: const Text('Ver todas las promociones'),
              ),
            ),
          ),
        },
      ],
    );
  }

  /// Las promociones de hoy, sin las que un VIP ya ve en sus ofertas
  /// exclusivas.
  AsyncValue<List<Product>> _promos() {
    final exclusive = {
      for (final offer
          in ref.watch(exclusiveOffersProvider).value ?? const <Offer>[])
        offer.productId,
    };
    return ref
        .watch(onSaleProductsProvider)
        .whenData(
          (products) => [
            for (final product in products)
              if (!exclusive.contains(product.id)) product,
          ],
        );
  }

  Widget _products(
    AsyncValue<List<Product>> value, {
    required VoidCallback onRetry,
    required String empty,
    Widget? footer,
  }) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return switch (value) {
      AsyncValue(value: final list?) when list.isEmpty => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(empty, style: muted),
      ),
      AsyncValue(value: final list?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _list(_expanded ? list : list.take(ProductTabs.shown).toList()),
          if (footer != null)
            footer
          else if (!_expanded && list.length > ProductTabs.shown)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => _expanded = true),
                child: const Text('Ver más'),
              ),
            ),
        ],
      ),
      AsyncValue(:final error?) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                errorMessage(error, 'No se pudieron cargar los productos.'),
                style: muted,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }

  Widget _list(List<Product> products) {
    void open(Product product) => context.go(Routes.product(product.id));
    if (MediaQuery.sizeOf(context).width >= AccountActions.wideFrom) {
      return ProductGrid(
        children: [
          for (final product in products)
            ProductCard(
              key: ValueKey(product.id),
              product: product,
              onTap: () => open(product),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final product in products) ...[
          ProductTile(
            key: ValueKey(product.id),
            product: product,
            onTap: () => open(product),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
