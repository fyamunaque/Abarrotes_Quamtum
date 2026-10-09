import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/cart_provider.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/product.dart';
import '../../common/api_client.dart';
import '../../router/routes.dart';
import '../cart/add_to_cart.dart';
import '../shared/brand.dart';
import '../shared/press_scale.dart';
import '../shared/quantity_stepper.dart';
import 'price_tag.dart';
import 'product_photo.dart';

/// El detalle de un producto: foto, precio, descripción y agregar al carrito
/// eligiendo la cantidad.
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
            AsyncData(value: final product) => _Detail(product),
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
        child: ProductPhoto(product.imageUrl, iconSize: 72),
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

class _Info extends ConsumerStatefulWidget {
  const _Info(this.product);

  final Product product;

  @override
  ConsumerState<_Info> createState() => _InfoState();
}

class _InfoState extends ConsumerState<_Info> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);
    final inCart = ref.watch(
      cartProvider.select((cart) => cart.quantityOf(product.id)),
    );
    // Lo que todavía se puede sumar sin pasar del stock.
    final available = product.maxQuantity - inCart;
    final quantity = _quantity.clamp(1, available < 1 ? 1 : available);

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
        Text(product.name, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        PriceTag(product, fontSize: 30),
        const SizedBox(height: 8),
        Text(_stockText(product), style: theme.textTheme.bodyMedium),
        if (product.description case final description?) ...[
          const SizedBox(height: 16),
          Text(description, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 24),
        if (available > 0)
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              QuantityStepper(
                quantity: quantity,
                max: available,
                onChanged: (value) => setState(() => _quantity = value),
              ),
              PressScale(
                child: FilledButton.icon(
                  onPressed: () {
                    addToCart(context, ref, product, quantity);
                    setState(() => _quantity = 1);
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Agregar al carrito'),
                ),
              ),
            ],
          ),
        if (inCart > 0) ...[
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                available > 0
                    ? 'Tienes $inCart en el carrito.'
                    : 'Ya tienes en el carrito todo el stock ($inCart).',
              ),
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

  static String _stockText(Product product) => switch (product.stock) {
    0 => 'Agotado',
    1 => 'Queda 1',
    <= 5 => 'Quedan ${product.stock}',
    _ => 'Disponible',
  };
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
