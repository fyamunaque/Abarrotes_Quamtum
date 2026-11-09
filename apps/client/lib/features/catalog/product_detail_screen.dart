import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/cart_provider.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/category.dart';
import '../../catalog/product.dart';
import '../../common/api_client.dart';
import '../../router/routes.dart';
import '../shared/brand.dart';
import 'offer_badges.dart';
import 'price_tag.dart';
import 'product_photo.dart';
import 'product_strip.dart';
import 'product_tile.dart';
import 'promo_tag.dart';
import 'stock_note.dart';

/// El detalle de un producto: foto, precio, descripción y agregar al carrito
/// eligiendo la cantidad. Debajo, "Más de" su categoría: otros productos de
/// la misma categoría.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = productProvider(productId);
    return PublicScaffold(
      // El nombre del producto, cuando ya cargó.
      title: ref.watch(provider).value?.name ?? 'Producto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go(Routes.catalog),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Catálogo'),
          ),
          const SizedBox(height: 8),
          switch (ref.watch(provider)) {
            AsyncData(value: final product) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Detail(product),
                if (product.category case final category?)
                  _Related(category: category, productId: product.id),
              ],
            ),
            // 404: no existe o se dio de baja; 400: el id del enlace no es
            // válido. Para la persona es lo mismo.
            AsyncError(error: ApiFailure(status: 400 || 404)) => _Unavailable(
              onCatalog: () => context.go(Routes.catalog),
            ),
            AsyncError(:final error) => Column(
              children: [
                Text(
                  error is ApiFailure
                      ? error.message
                      : 'No se pudo cargar el producto.',
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(provider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
            _ => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.product);

  final Product product;

  @override
  Widget build(BuildContext context) {
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ProductPhoto(
          product.imageUrl,
          name: product.name,
          colorKey: product.category?.id,
          initialSize: 72,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 720
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: photo),
                const SizedBox(width: 32),
                Expanded(child: _Info(product)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [photo, const SizedBox(height: 20), _Info(product)],
            ),
    );
  }
}

/// El código y el nombre, el precio, el stock, las promociones, la
/// descripción y la fila para agregar ("Agregar", o "Editar" si ya está en el
/// carrito).
class _Info extends ConsumerWidget {
  const _Info(this.product);

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inCart = ref.watch(
      cartProvider.select((cart) => cart.quantityOf(product.id)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.category case final category?)
          Text(
            category.name,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Text(productTitle(product), style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        PriceTag(product, fontSize: 30),
        const SizedBox(height: 6),
        // En el detalle hay lugar: la etiqueta y la disponibilidad.
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [PromoTag(product.offers), StockNote(product)],
        ),
        if (product.offers.isNotEmpty) ...[
          const SizedBox(height: 12),
          OfferDescriptions(product.offers),
        ],
        if (product.description case final description?) ...[
          const SizedBox(height: 16),
          Text(description, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 24),
        ProductQuantityActions(product: product),
        if (inCart > 0) ...[
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Tienes $inCart en el carrito.'),
              TextButton(
                onPressed: () => context.go(Routes.cart),
                child: const Text('Ver carrito'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Más de Lácteos": otros productos de la categoría. Mientras cargan, si
/// fallan o si no hay otros, no ocupa lugar.
class _Related extends ConsumerWidget {
  const _Related({required this.category, required this.productId});

  final Category category;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref
        .watch(
          relatedProductsProvider((
            categoryId: category.id,
            productId: productId,
          )),
        )
        .value;
    if (products == null || products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: ProductStrip(title: 'Más de ${category.name}', products: products),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onCatalog});

  final VoidCallback onCatalog;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Text(
              'Este producto ya no está disponible.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCatalog,
              child: const Text('Ver el catálogo'),
            ),
          ],
        ),
      ),
    );
  }
}
