import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/cart_provider.dart';
import '../../catalog/product.dart';
import 'cart_notice.dart';

/// Agrega [quantity] de [product] al carrito y lo confirma con el aviso del
/// carrito ([showCartNotice]). Si ya estaba todo el stock en el carrito, lo
/// dice.
void addToCart(
  BuildContext context,
  WidgetRef ref,
  Product product, [
  int quantity = 1,
]) {
  final before = ref.read(cartProvider).quantityOf(product.id);
  final after = ref.read(cartProvider.notifier).add(product, quantity);
  final added = after > before;
  showCartNotice(
    context,
    product: product,
    title: added ? 'Agregado al carrito' : 'Ya tienes todo el stock',
    stockLimit: !added,
  );
}

/// Deja [quantity] de [product], que ya está en el carrito ("Editar"), y lo
/// confirma con el aviso del carrito.
void updateCartQuantity(
  BuildContext context,
  WidgetRef ref,
  Product product,
  int quantity,
) {
  ref.read(cartProvider.notifier).setQuantity(product.id, quantity);
  final now = ref.read(cartProvider).quantityOf(product.id);
  showCartNotice(context, product: product, title: 'Ahora llevas $now');
}
