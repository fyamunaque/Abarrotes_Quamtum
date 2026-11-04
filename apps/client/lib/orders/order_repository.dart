import '../common/page_list.dart';
import 'fulfillment.dart';
import 'order.dart';
import 'order_filter.dart';
import 'quote.dart';

/// Lo que se pide de un producto. [shownUnitPriceCents] es el precio que
/// mostraba el carrito y [shownLineTotalCents], el total de la línea de la
/// cotización (con sus promociones), si la había: el servidor nunca los
/// cobra, solo los compara y avisa si cambiaron (`Order.priceChanges`).
typedef OrderLineRequest = ({
  String productId,
  int quantity,
  int? shownUnitPriceCents,
  int? shownLineTotalCents,
});

/// Un producto del carrito para cotizar.
typedef QuoteLineRequest = ({String productId, int quantity});

/// Los pedidos de la cuenta. Las rutas piden el ID token de Firebase. Los
/// errores salen como `ApiFailure` (p. ej. 409 si un producto ya no tiene
/// stock, con el mensaje del servidor).
abstract interface class OrderRepository {
  /// Crea el pedido (`POST /orders`); queda pendiente de confirmación. A
  /// domicilio lleva [deliveryAddress]; con recojo en tienda, no (el
  /// servidor le genera su código).
  Future<Order> place(
    String idToken, {
    FulfillmentType fulfillmentType = FulfillmentType.delivery,
    String? deliveryAddress,
    required List<OrderLineRequest> lines,
  });

  /// Cómo se cobraría [lines] hoy (`POST /orders/quote`), sin guardar
  /// nada. Con [idToken], con las promociones de esa cuenta (p. ej. las
  /// VIP); sin él, las de todos.
  Future<Quote> quote(List<QuoteLineRequest> lines, {String? idToken});

  /// Una página de los pedidos propios, los más recientes primero, con la
  /// búsqueda y los filtros de [filter].
  Future<PageList<Order>> mine(
    String idToken, {
    int page = 1,
    MyOrdersFilter filter = allMyOrders,
  });
}
