import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/cart.dart';
import '../../cart/cart_provider.dart';
import '../../common/money.dart';
import '../../router/routes.dart';
import '../../theme/neils_theme.dart';
import '../catalog/product_photo.dart';
import '../shared/brand.dart';
import '../shared/quantity_stepper.dart';

/// El carrito: cambiar cantidades, quitar productos y ver el total.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return PublicScaffold(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Carrito', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          if (cart.isEmpty)
            const _EmptyCart()
          else ...[
            for (final line in cart.lines)
              _CartLineTile(line, key: ValueKey(line.product.id)),
            const Divider(height: 32),
            _Total(cart),
          ],
        ],
      ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile(this.line, {super.key});

  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final product = line.product;
    final cart = ref.read(cartProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 64,
                  child: ProductPhoto(product.imageUrl, iconSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: theme.textTheme.titleMedium),
                    Text(
                      '${formatSoles(product.finalPriceCents)} c/u',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar del carrito',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => cart.remove(product.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              QuantityStepper(
                quantity: line.quantity,
                max: product.maxQuantity,
                onChanged: (quantity) => cart.setQuantity(product.id, quantity),
              ),
              const Spacer(),
              Text(
                formatSoles(line.totalCents),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.cart);

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Total', style: text.titleLarge),
            const Spacer(),
            Text(
              formatSoles(cart.totalCents),
              style: NeilsText.price(fontSize: 26),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'La tienda cobra los precios del momento en que confirmas el pedido.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Tu carrito está vacío.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(Routes.catalog),
            child: const Text('Ver el catálogo'),
          ),
        ],
      ),
    );
  }
}
