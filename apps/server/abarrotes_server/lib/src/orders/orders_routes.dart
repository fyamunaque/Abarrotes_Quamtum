// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

import '../auth/firebase_auth_middleware.dart';
import '../auth/guards.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/money.dart';
import '../common/pagination.dart';
import '../common/shopper.dart';
import '../generated/protocol.dart';
import 'orders_service.dart';
import 'states/order_states.dart';

/// Rutas de pedidos: crear y ver los propios, para cualquier cuenta; el
/// listado, con `orders.view`, y los cambios de estado, con
/// `orders.updateStatus`. El contacto del cliente solo va con
/// `customers.view`, y el código de recojo, para el dueño del pedido y para
/// el personal con `orders.view`.
List<RouteEntry> ordersRoutes(
  OrdersService orders,
  Guards guards, {
  required ShopperResolver shoppers,
}) {
  Route signedIn(Method method, ApiHandler handler) =>
      guards.signedIn(ApiRoute(method, handler));
  Route requires(Permission permission, Method method, ApiHandler handler) =>
      guards.require(permission, ApiRoute(method, handler));
  Map<String, Object?> panelJson(Request request, Order order) =>
      adminOrderJson(
        order,
        withCustomer: request.staffAccess.can(Permission.customersView),
        withPickupCode: request.staffAccess.can(Permission.ordersView),
      );

  return [
    (
      '/orders',
      // El pedido queda a nombre de quien lo crea. Los precios y el total los
      // pone el servidor con los precios de hoy para ese cliente. Cada ítem
      // puede traer el unitPrice que mostraba el carrito: nunca se cobra, solo
      // se compara, y si cambió va en priceChanges. A domicilio (por defecto)
      // lleva la dirección; con recojo en tienda no, y el servidor le genera
      // su código.
      signedIn(Method.post, (session, request) async {
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {'fulfillmentType', 'deliveryAddress', 'items'},
        );
        final fulfillmentType =
            body.oneOf(
              'fulfillmentType',
              FulfillmentType.values,
              required: false,
            ) ??
            FulfillmentType.delivery;
        final deliveryAddress = body.text(
          'deliveryAddress',
          maxLength: 255,
          required: false,
        );
        switch (fulfillmentType) {
          case FulfillmentType.delivery when !body.has('deliveryAddress'):
            body.reject('deliveryAddress es obligatorio a domicilio');
          case FulfillmentType.pickup when body.has('deliveryAddress'):
            body.reject(
              'deliveryAddress no va en un pedido de recojo en tienda',
            );
          default:
        }
        final items = body.objects(
          'items',
          allowed: const {'productId', 'quantity', 'unitPrice'},
          min: 1,
          max: 100,
        );
        final lines = [
          for (final item in items ?? const <InputReader>[])
            (
              productId: item.uuid('productId'),
              quantity: item.integer('quantity', min: 1, max: 999),
              shownUnitPrice: item.cents(
                'unitPrice',
                minCents: 0,
                required: false,
              ),
            ),
        ];
        body.check();

        final placed = await orders.create(
          session,
          customer: request.currentUser,
          shopper: await shoppers.resolve(session, request.firebaseIdentity),
          fulfillmentType: fulfillmentType,
          deliveryAddress: deliveryAddress,
          lines: [
            for (final line in lines)
              (
                productId: line.productId!,
                quantity: line.quantity!,
                shownUnitPriceCents: line.shownUnitPrice,
              ),
          ],
        );
        return jsonResponse(201, {
          ...orderJson(placed.order, withPickupCode: true),
          'priceChanges': placed.priceChanges.map(priceChangeJson).toList(),
        });
      }),
    ),
    (
      '/orders/mine',
      signedIn(Method.get, (session, request) async {
        final query = InputReader.query(request, allowed: PageQuery.fields);
        final page = PageQuery.read(query);
        query.check();

        final (list, total) = await orders.mine(
          session,
          request.currentUser,
          page,
        );
        return jsonResponse(
          200,
          page.wrap(
            [for (final order in list) orderJson(order, withPickupCode: true)],
            total,
          ),
        );
      }),
    ),
    (
      '/orders',
      requires(Permission.ordersView, Method.get, (session, request) async {
        final query = InputReader.query(
          request,
          allowed: {
            ...PageQuery.fields,
            'status',
            'fulfillmentType',
            'from',
            'to',
          },
        );
        final page = PageQuery.read(query);
        final status = query.oneOf(
          'status',
          OrderStatus.values,
          required: false,
        );
        final fulfillmentType = query.oneOf(
          'fulfillmentType',
          FulfillmentType.values,
          required: false,
        );
        final from = query.day('from', required: false);
        final to = query.day('to', required: false);
        query.check();

        final (list, total) = await orders.list(
          session,
          page,
          status: status,
          fulfillmentType: fulfillmentType,
          from: from,
          to: to,
        );
        return jsonResponse(
          200,
          page.wrap(
            list.map((order) => panelJson(request, order)).toList(),
            total,
          ),
        );
      }),
    ),
    (
      '/orders/:id/status',
      requires(Permission.ordersUpdateStatus, Method.patch, (
        session,
        request,
      ) async {
        final id = idParam(request);
        // pickupCode: el que muestra el cliente al recoger su pedido.
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {'status', 'pickupCode'},
        );
        final status = body.oneOf('status', OrderStatus.values);
        final pickupCode = body.text(
          'pickupCode',
          maxLength: 20,
          required: false,
        );
        body.check();

        final order = await orders.changeStatus(
          session,
          id,
          status!,
          by: request.currentUser,
          pickupCode: pickupCode,
        );
        return jsonResponse(200, panelJson(request, order));
      }),
    ),
  ];
}

/// El pedido con sus líneas, como lo lee la app (`Order.fromJson`). Montos
/// como texto ("4.5") y estado como en el modelo (`pendingConfirmation`,
/// `confirmed`…). `allowedNextStatuses` sale del flujo de su tipo de
/// entrega: las apps arman sus botones con eso, sin las transiciones escritas
/// a mano. El código de recojo, solo [withPickupCode] (el dueño del pedido o
/// el personal con `orders.view`).
Map<String, Object?> orderJson(Order order, {required bool withPickupCode}) {
  return {
    'id': order.id.toString(),
    'status': order.status.name,
    'fulfillmentType': order.fulfillmentType.name,
    'allowedNextStatuses': [
      for (final status in orderStateOfOrder(order).nextStatuses) status.name,
    ],
    'total': formatMoney(order.totalCents),
    'deliveryAddress': order.deliveryAddress,
    'pickupCode': withPickupCode ? order.pickupCode : null,
    'readyForPickupAt': order.readyForPickupAt?.toUtc().toIso8601String(),
    'createdAt': order.createdAt.toUtc().toIso8601String(),
    'updatedAt': order.updatedAt.toUtc().toIso8601String(),
    'customerId': order.customerId.toString(),
    'items': [
      for (final item in order.items ?? const <OrderItem>[])
        {
          'id': item.id.toString(),
          'quantity': item.quantity,
          'unitPrice': formatMoney(item.unitPriceCents),
          'orderId': item.orderId.toString(),
          'productId': item.productId.toString(),
          'product': {
            'id': item.product!.id.toString(),
            'name': item.product!.name,
            'imageUrl': item.product!.imageUrl,
          },
        },
    ],
  };
}

/// Un precio que cambió entre el carrito y el cobro, para avisarle al cliente.
Map<String, Object?> priceChangeJson(PriceChange change) => {
  'productId': change.productId.toString(),
  'name': change.name,
  'shownUnitPrice': formatMoney(change.shownUnitPriceCents),
  'unitPrice': formatMoney(change.unitPriceCents),
};

/// Como [orderJson] y, para el panel, quién lo hizo: sus datos de contacto
/// solo [withCustomer] (`customers.view`); si no, `customer` va en null.
Map<String, Object?> adminOrderJson(
  Order order, {
  required bool withCustomer,
  required bool withPickupCode,
}) {
  final customer = order.customer!;
  return {
    ...orderJson(order, withPickupCode: withPickupCode),
    'customer': withCustomer
        ? {
            'id': customer.id.toString(),
            'name': customer.name,
            'email': customer.email,
            'phone': customer.phone,
          }
        : null,
  };
}
