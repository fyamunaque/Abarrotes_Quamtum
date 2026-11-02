// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

import '../auth/firebase_auth_middleware.dart';
import '../auth/guards.dart';
import '../common/api_route.dart';
import '../common/customer_requirements.dart';
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
/// `customers.view`; el código de recojo, para el dueño del pedido y para el
/// personal con `orders.view`, y el de entrega, solo para el dueño.
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
      // su código. La cuenta tiene que tener el correo confirmado, el celular
      // y los términos vigentes aceptados (si no, 403 con lo que falta).
      signedIn(Method.post, (session, request) async {
        if (missingToOrder(request.currentUser, request.firebaseIdentity)
            case final missing?) {
          return jsonError(403, missing);
        }
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
          allowed: const {'productId', 'quantity', 'unitPrice', 'lineTotal'},
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
              shownLineTotal: item.cents(
                'lineTotal',
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
                shownLineTotalCents: line.shownLineTotal,
              ),
          ],
        );
        return jsonResponse(201, {
          ...orderJson(placed.order, withCodes: true),
          'priceChanges': placed.priceChanges.map(priceChangeJson).toList(),
          'notices': placed.notices,
        });
      }),
    ),
    (
      '/orders/mine',
      // Filtros: search (el N.º o un producto del pedido), state (active,
      // delivered o cancelled), fulfillmentType, y from y to (días de la
      // tienda).
      signedIn(Method.get, (session, request) async {
        final query = InputReader.query(
          request,
          allowed: {
            ...PageQuery.fields,
            'search',
            'state',
            'fulfillmentType',
            'from',
            'to',
          },
        );
        final page = PageQuery.read(query);
        final search = query.text('search', maxLength: 100, required: false);
        final progress = query.oneOf(
          'state',
          OrderProgress.values,
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

        final (list, total) = await orders.mine(
          session,
          request.currentUser,
          page,
          search: search,
          progress: progress,
          fulfillmentType: fulfillmentType,
          from: from,
          to: to,
        );
        return jsonResponse(
          200,
          page.wrap(
            [for (final order in list) orderJson(order, withCodes: true)],
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
            'number',
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
        final number = query.integer('number', required: false);
        query.check();

        final (list, total) = await orders.list(
          session,
          page,
          status: status,
          fulfillmentType: fulfillmentType,
          from: from,
          to: to,
          number: number,
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
        // deliveryCode: el que el cliente le da al repartidor.
        // withoutCodeReason: entregar a domicilio sin el código (solo con
        // staff.manage), por qué; queda en el pedido y en la bitácora.
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {
            'status',
            'pickupCode',
            'deliveryCode',
            'withoutCodeReason',
          },
        );
        final status = body.oneOf('status', OrderStatus.values);
        final pickupCode = body.text(
          'pickupCode',
          maxLength: 20,
          required: false,
        );
        final deliveryCode = body.text(
          'deliveryCode',
          maxLength: 20,
          required: false,
        );
        final withoutCodeReason = body.text(
          'withoutCodeReason',
          maxLength: 255,
          required: false,
        );
        if (withoutCodeReason != null && withoutCodeReason.length < 5) {
          body.reject('Escribe por qué se entrega sin código');
        }
        body.check();
        if (withoutCodeReason != null &&
            !request.staffAccess.can(Permission.staffManage)) {
          return jsonError(
            403,
            'Solo quien administra la tienda entrega un pedido sin código',
          );
        }

        final order = await orders.changeStatus(
          session,
          id,
          status!,
          by: request.currentUser,
          code: pickupCode ?? deliveryCode,
          withoutCodeReason: withoutCodeReason,
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
/// a mano. Los códigos de recojo y de entrega, solo con [withCodes] (el dueño
/// del pedido); el de recojo, además con [withPickupCode] (el personal con
/// `orders.view`). El de entrega nunca va al personal: se lo pide al
/// cliente.
Map<String, Object?> orderJson(
  Order order, {
  bool withCodes = false,
  bool withPickupCode = false,
}) {
  return {
    'id': order.id.toString(),
    'number': order.number,
    'status': order.status.name,
    'fulfillmentType': order.fulfillmentType.name,
    'allowedNextStatuses': [
      for (final status in orderStateOfOrder(order).nextStatuses) status.name,
    ],
    // A precio normal, lo que ahorraron las promociones y lo cobrado.
    'subtotal': formatMoney(order.subtotalCents),
    'discount': formatMoney(order.discountCents),
    'total': formatMoney(order.totalCents),
    'deliveryAddress': order.deliveryAddress,
    'pickupCode': withCodes || withPickupCode ? order.pickupCode : null,
    'deliveryCode': withCodes ? order.deliveryCode : null,
    // Para todos: si entregarlo pide el código (los pedidos de antes no lo
    // tienen), así el panel sabe si pedírselo al cliente.
    'hasDeliveryCode': order.deliveryCode != null,
    'deliveredWithoutCodeReason': order.deliveredWithoutCodeReason,
    'readyForPickupAt': order.readyForPickupAt?.toUtc().toIso8601String(),
    'createdAt': order.createdAt.toUtc().toIso8601String(),
    'updatedAt': order.updatedAt.toUtc().toIso8601String(),
    'customerId': order.customerId.toString(),
    'items': [
      for (final item in order.items ?? const <OrderItem>[])
        {
          'id': item.id.toString(),
          'quantity': item.quantity,
          'listUnitPrice': formatMoney(item.listUnitPriceCents),
          'unitPrice': formatMoney(item.unitPriceCents),
          'lineTotal': formatMoney(item.lineTotalCents),
          'isGift': item.isGift,
          'promotions': [
            for (final applied in item.promotions ?? const <AppliedPromotion>[])
              {
                'label': applied.label,
                'saved': formatMoney(applied.savedCents),
              },
          ],
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

/// Un precio que cambió entre el carrito y el cobro, para avisarle al
/// cliente: el total de la línea o, si el carrito mandó el precio
/// unitario (apps de antes), ese.
Map<String, Object?> priceChangeJson(PriceChange change) => {
  'productId': change.productId.toString(),
  'name': change.name,
  if (change.shownLineTotalCents case final shown?) ...{
    'shownLineTotal': formatMoney(shown),
    'lineTotal': formatMoney(change.lineTotalCents!),
  } else ...{
    'shownUnitPrice': formatMoney(change.shownUnitPriceCents!),
    'unitPrice': formatMoney(change.unitPriceCents!),
  },
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
            // Para confirmar quién recibe o recoge el pedido.
            'dni': customer.dni,
          }
        : null,
  };
}
