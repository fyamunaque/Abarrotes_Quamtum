import '../../common/api_client.dart';
import '../../common/page_list.dart';
import '../../orders/order_status.dart';
import 'admin_order.dart';

/// Los pedidos de todos los clientes (solo admin y staff). Los errores salen
/// como `ApiFailure`.
abstract interface class AdminOrdersRepository {
  /// Una página, los más recientes primero. Con [status], solo los de ese
  /// estado.
  Future<PageList<AdminOrder>> list({int page = 1, OrderStatus? status});

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
  Future<PageList<AdminOrder>> list({int page = 1, OrderStatus? status}) async {
    final json = await _api.get(
      '/orders',
      query: {'page': '$page', 'limit': '$pageSize', 'status': ?status?.name},
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
