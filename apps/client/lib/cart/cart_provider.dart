import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/product.dart';
import 'cart.dart';

/// El carrito. Vive solo en memoria: se vacía al cerrar o recargar la app.
final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() => const Cart();

  /// Suma [quantity] unidades de [product], o lo agrega. Nunca pasa de
  /// [Product.maxQuantity]. Devuelve cuántas quedaron en el carrito.
  int add(Product product, [int quantity = 1]) =>
      _set(product, state.quantityOf(product.id) + quantity);

  /// Cambia la cantidad de una línea (entre 1 y el máximo del producto).
  void setQuantity(String productId, int quantity) {
    final line = state.lineOf(productId);
    if (line != null) {
      _set(line.product, quantity.clamp(1, line.product.maxQuantity));
    }
  }

  void remove(String productId) => state = Cart([
    for (final line in state.lines)
      if (line.product.id != productId) line,
  ]);

  void clear() => state = const Cart();

  int _set(Product product, int quantity) {
    final clamped = quantity.clamp(0, product.maxQuantity);
    if (clamped == 0) {
      remove(product.id);
      return 0;
    }
    final line = CartLine(product, clamped);
    state = Cart(
      state.lineOf(product.id) == null
          ? [...state.lines, line]
          : [
              for (final current in state.lines)
                current.product.id == product.id ? line : current,
            ],
    );
    return clamped;
  }
}
