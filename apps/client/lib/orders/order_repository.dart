import '../common/page_list.dart';
import 'order.dart';

/// Lo que se pide de un producto. [shownUnitPriceCents] es el precio que
/// mostraba el carrito: el servidor nunca lo cobra, solo lo compara y avisa
/// si cambió (`Order.priceChanges`).
typedef OrderLineRequest = ({
  String productId,
  int quantity,
  int? shownUnitPriceCents,
});

/// Los pedidos de la cuenta. Las rutas piden el ID token de Firebase. Los
/// errores salen como `ApiFailure` (p. ej. 409 si un producto ya no tiene
/// stock, con el mensaje del servidor).
abstract interface class OrderRepository {
  /// Crea el pedido (`POST /orders`); queda pendiente de confirmación.
  Future<Order> place(
    String idToken, {
    required String deliveryAddress,
    required List<OrderLineRequest> lines,
  });

  /// Una página de los pedidos propios, los más recientes primero.
  Future<PageList<Order>> mine(String idToken, {int page = 1});
}
