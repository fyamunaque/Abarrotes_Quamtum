import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/product.dart';
import '../common/api_client.dart';
import '../orders/order.dart';
import '../orders/orders_providers.dart';
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

  /// Hace el pedido con lo que hay en el carrito, a nombre de la cuenta
  /// abierta. Si sale bien, vacía el carrito y devuelve el pedido.
  ///
  /// Si falla (`ApiFailure` del servidor, p. ej. 409 sin stock, o
  /// `AuthFailure` si la sesión terminó), el carrito queda igual. Si el
  /// servidor llegó a ver el pedido, el catálogo se vuelve a cargar: el
  /// stock cambió.
  Future<Order> placeOrder({required String deliveryAddress}) async {
    final lines = state.lines;
    if (lines.isEmpty) throw const ApiFailure('Tu carrito está vacío.');

    final token = await ref.read(authRepositoryProvider).idToken();
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .place(
            token,
            deliveryAddress: deliveryAddress,
            lines: [
              for (final line in lines)
                (productId: line.product.id, quantity: line.quantity),
            ],
          );
      state = const Cart();
      ref
        ..invalidate(myOrdersProvider)
        ..invalidate(productListProvider)
        ..invalidate(productProvider);
      return order;
    } on ApiFailure catch (failure) {
      if (failure.status case 400 || 409) {
        ref
          ..invalidate(productListProvider)
          ..invalidate(productProvider);
      }
      rethrow;
    }
  }

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
