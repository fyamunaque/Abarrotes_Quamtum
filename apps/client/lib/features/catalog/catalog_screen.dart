import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../catalog/catalog_providers.dart';
import '../../common/api_client.dart';
import '../../router/routes.dart';
import '../cart/add_to_cart.dart';
import '../shared/brand.dart';
import 'product_card.dart';
import 'product_grid.dart';

/// Catálogo: las categorías para filtrar y los productos, página a página.
/// La categoría elegida va en la URL (`?categoria=<id>`), así un enlace
/// abre el catálogo ya filtrado.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, this.categoryId});

  /// null: todas las categorías.
  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Catálogo', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          _CategoryFilter(selected: categoryId),
          const SizedBox(height: 20),
          _Products(categoryId),
        ],
      ),
    );
  }
}

/// "Todas" y una opción por categoría. Si las categorías no cargan, no se
/// muestra: los productos se pueden ver igual.
class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value;
    if (categories == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todas'),
          selected: selected == null,
          onSelected: (_) => context.go(Routes.catalog),
        ),
        for (final category in categories)
          ChoiceChip(
            label: Text(category.name),
            selected: category.id == selected,
            onSelected: (_) => context.go(Routes.catalogOf(category.id)),
          ),
      ],
    );
  }
}

class _Products extends ConsumerWidget {
  const _Products(this.categoryId);

  final String? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = productListProvider(categoryId);
    return switch (ref.watch(provider)) {
      AsyncData(value: final list) when list.products.isEmpty => _Message(
        categoryId == null
            ? 'Todavía no hay productos.'
            : 'No hay productos en esta categoría.',
      ),
      AsyncData(value: final list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductGrid(
            children: [
              for (final product in list.products)
                ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  onTap: () => context.go(Routes.product(product.id)),
                  onAdd: () => addToCart(context, ref, product),
                ),
            ],
          ),
          if (list.hasMore) ...[
            const SizedBox(height: 20),
            Center(
              child: list.loadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () => _loadMore(context, ref),
                      child: const Text('Ver más productos'),
                    ),
            ),
          ],
        ],
      ),
      AsyncError(:final error) => _Message(
        error is ApiFailure
            ? error.message
            : 'No se pudieron cargar los productos.',
        action: FilledButton.tonal(
          onPressed: () => ref.invalidate(provider),
          child: const Text('Reintentar'),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }

  Future<void> _loadMore(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(productListProvider(categoryId).notifier).loadMore();
    } on ApiFailure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (action case final action?) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }
}
