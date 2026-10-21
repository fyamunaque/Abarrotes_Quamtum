import '../common/api_client.dart';
import '../common/page_list.dart';
import 'fulfillment.dart';
import 'order.dart';
import 'order_repository.dart';

/// [OrderRepository] contra `POST /orders` y `GET /orders/mine`.
class HttpOrderRepository implements OrderRepository {
  HttpOrderRepository(this._api);

  final ApiClient _api;

  static const pageSize = 10;

  @override
  Future<Order> place(
    String idToken, {
    FulfillmentType fulfillmentType = FulfillmentType.delivery,
    String? deliveryAddress,
    required List<OrderLineRequest> lines,
  }) async {
    final json = await _api.post(
      '/orders',
      {
        'fulfillmentType': fulfillmentType.name,
        // Con recojo en tienda no va: el servidor la rechaza.
        if (fulfillmentType == FulfillmentType.delivery)
          'deliveryAddress': deliveryAddress,
        'items': [
          for (final line in lines)
            {
              'productId': line.productId,
              'quantity': line.quantity,
              if (line.shownUnitPriceCents case final cents?)
                'unitPrice': cents / 100,
            },
        ],
      },
      idToken: idToken,
      fallback: 'No se pudo hacer el pedido.',
    );
    return decodeResponse(() => Order.fromJson(json));
  }

  @override
  Future<PageList<Order>> mine(String idToken, {int page = 1}) async {
    final json = await _api.get(
      '/orders/mine',
      query: {'page': '$page', 'limit': '$pageSize'},
      idToken: idToken,
      fallback: 'No se pudieron cargar tus pedidos.',
    );
    return decodeResponse(() => decodePage(json, Order.fromJson));
  }
}
