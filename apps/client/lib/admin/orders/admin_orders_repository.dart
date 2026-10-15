import '../../common/api_client.dart';
import '../../common/page_list.dart';
import '../../orders/fulfillment.dart';
import '../../orders/order_status.dart';
import 'admin_order.dart';

/// Los pedidos de todos los clientes (solo admin y staff). Los errores salen
/// como `ApiFailure`.
abstract interface class AdminOrdersRepository {
  /// Una página, los más recientes primero. Con [status] o
  /// [fulfillmentType], solo los de ese estado o tipo de entrega. [limit],
  /// cuántos por página (hasta 100; por defecto 20).
  Future<PageList<AdminOrder>> list({
    int page = 1,
    OrderStatus? status,
    FulfillmentType? fulfillmentType,
    int? limit,
  });

  /// Cambia el estado. Si el estado actual no lo permite (p. ej. otra persona
  /// ya lo cambió), `ApiFailure` 400 con el motivo. Recoger un pedido en
  /// caja lleva el [pickupCode] que muestra el cliente.
  Future<AdminOrder> changeStatus(
    String id,
    OrderStatus status, {
    String? pickupCode,
  });
}

class HttpAdminOrdersRepository implements AdminOrdersRepository {
  HttpAdminOrdersRepository(this._api);

  final AuthedApi _api;

  static const pageSize = 20;

  @override
  Future<PageList<AdminOrder>> list({
    int page = 1,
    OrderStatus? status,
    FulfillmentType? fulfillmentType,
    int? limit,
  }) async {
    final json = await _api.get(
      '/orders',
      query: {
        'page': '$page',
        'limit': '${limit ?? pageSize}',
        'status': ?status?.name,
        'fulfillmentType': ?fulfillmentType?.name,
      },
      fallback: 'No se pudieron cargar los pedidos.',
    );
    return decodeResponse(() => decodePage(json, AdminOrder.fromJson));
  }

  @override
  Future<AdminOrder> changeStatus(
    String id,
    OrderStatus status, {
    String? pickupCode,
  }) async {
    final json = await _api.patch('/orders/${Uri.encodeComponent(id)}/status', {
      'status': status.name,
      'pickupCode': ?pickupCode,
    }, fallback: 'No se pudo cambiar el estado.');
    return decodeResponse(() => AdminOrder.fromJson(json));
  }
}
