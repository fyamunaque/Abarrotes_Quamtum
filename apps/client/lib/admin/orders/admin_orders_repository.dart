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
    int? number,
    int? limit,
  });

  /// Cambia el estado. Si el estado actual no lo permite (p. ej. otra persona
  /// ya lo cambió), `ApiFailure` 400 con el motivo. Recoger un pedido en
  /// caja lleva el [pickupCode] que muestra el cliente, y entregar uno a
  /// domicilio, el [deliveryCode] que el cliente le da al repartidor o,
  /// sin él (solo con `staff.manage`), [withoutCodeReason]: por qué.
  Future<AdminOrder> changeStatus(
    String id,
    OrderStatus status, {
    String? pickupCode,
    String? deliveryCode,
    String? withoutCodeReason,
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
    int? number,
    int? limit,
  }) async {
    final json = await _api.get(
      '/orders',
      query: {
        'page': '$page',
        'limit': '${limit ?? pageSize}',
        'status': ?status?.name,
        'fulfillmentType': ?fulfillmentType?.name,
        if (number != null) 'number': '$number',
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
    String? deliveryCode,
    String? withoutCodeReason,
  }) async {
    final json = await _api.patch('/orders/${Uri.encodeComponent(id)}/status', {
      'status': status.name,
      'pickupCode': ?pickupCode,
      'deliveryCode': ?deliveryCode,
      'withoutCodeReason': ?withoutCodeReason,
    }, fallback: 'No se pudo cambiar el estado.');
    return decodeResponse(() => AdminOrder.fromJson(json));
  }
}
