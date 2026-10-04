import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/cart_provider.dart';
import '../../catalog/product.dart';
import '../../router/routes.dart';

/// Agrega [quantity] de [product] al carrito y lo confirma con un aviso que
/// lleva al carrito. Si ya estaba todo el stock en el carrito, lo dice.
void addToCart(
  BuildContext context,
  WidgetRef ref,
  Product product, [
  int quantity = 1,
]) {
  final before = ref.read(cartProvider).quantityOf(product.id);
  final after = ref.read(cartProvider.notifier).add(product, quantity);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          after > before
              ? 'Agregaste ${product.name}'
              : 'Ya tienes en el carrito todo el stock de ${product.name}',
        ),
        action: SnackBarAction(
          label: 'Ver carrito',
          onPressed: () => context.go(Routes.cart),
        ),
      ),
    );
}
