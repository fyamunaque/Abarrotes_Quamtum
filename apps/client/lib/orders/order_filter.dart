import 'fulfillment.dart';

/// En qué va un pedido, para filtrar "Mis pedidos", con los nombres del
/// servidor (`state` en `GET /orders/mine`).
enum OrderProgress {
  active('En curso'),
  delivered('Entregados'),
  cancelled('Cancelados');

  const OrderProgress(this.label);

  final String label;
}

/// La búsqueda y los filtros de "Mis pedidos" (vacío o null: todos).
/// [search] es el N.º del pedido o el nombre de un producto; [from] y [to]
/// son días de la tienda, ambos incluidos.
typedef MyOrdersFilter = ({
  String search,
  OrderProgress? progress,
  FulfillmentType? fulfillmentType,
  DateTime? from,
  DateTime? to,
});

/// Sin filtros.
const MyOrdersFilter allMyOrders = (
  search: '',
  progress: null,
  fulfillmentType: null,
  from: null,
  to: null,
);
