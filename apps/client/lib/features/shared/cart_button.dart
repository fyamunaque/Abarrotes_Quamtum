import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/cart_provider.dart';
import '../../router/routes.dart';

/// El carrito en la barra, con cuántas unidades tiene.
class CartButton extends ConsumerWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider.select((cart) => cart.count));
    return IconButton(
      tooltip: count == 0 ? 'Carrito' : 'Carrito: $count',
      onPressed: () => context.go(Routes.cart),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
