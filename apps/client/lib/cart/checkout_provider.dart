import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../orders/fulfillment.dart';
import '../orders/order.dart';
import '../session/session_provider.dart';
import 'cart_provider.dart';
import 'cart_quote_provider.dart';

/// Cómo se confirma el pedido del carrito: el tipo de entrega elegido, si se
/// está enviando y el error del último intento.
class Checkout {
  const Checkout({
    this.fulfillmentType = FulfillmentType.delivery,
    this.busy = false,
    this.error,
  });

  final FulfillmentType fulfillmentType;
  final bool busy;

  /// Por qué falló el último intento (null: nada que mostrar). La pantalla
  /// lo muestra con su mensaje.
  final Object? error;
}

/// El checkout del carrito. Lo comparten el formulario y la barra fija del
/// teléfono, así los dos muestran lo mismo. Al salir del carrito se olvida.
final checkoutProvider =
    NotifierProvider.autoDispose<CheckoutNotifier, Checkout>(
      CheckoutNotifier.new,
    );

class CheckoutNotifier extends Notifier<Checkout> {
  @override
  Checkout build() => const Checkout();

  /// Cambia el tipo de entrega (y borra el error anterior). Mientras se
  /// envía, no.
  void choose(FulfillmentType type) {
    if (state.busy) return;
    state = Checkout(fulfillmentType: type);
  }

  /// Hace el pedido ([CartNotifier.placeOrder]) con el tipo elegido; a
  /// domicilio, a [deliveryAddress]. Devuelve el pedido, o null si ya se
  /// estaba enviando o si falló (el error queda en [Checkout.error]).
  Future<Order?> confirm({String? deliveryAddress}) async {
    if (state.busy) return null;
    final type = state.fulfillmentType;
    state = Checkout(fulfillmentType: type, busy: true);
    try {
      final order = await ref
          .read(cartProvider.notifier)
          .placeOrder(
            fulfillmentType: type,
            deliveryAddress: type == FulfillmentType.delivery
                ? deliveryAddress
                : null,
            // La que muestra el carrito, si es la de cómo está ahora.
            quote: shownQuote(
              ref.read(cartProvider),
              ref.read(cartQuoteProvider),
              ref.read(sessionProvider),
            ),
          );
      if (ref.mounted) state = Checkout(fulfillmentType: type);
      return order;
    } catch (error) {
      if (ref.mounted) {
        state = Checkout(fulfillmentType: type, error: error);
      }
      return null;
    }
  }
}
