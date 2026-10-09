// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

import '../auth/firebase_token_verifier.dart';
import '../auth/role_guard.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/money.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart';
import 'orders_service.dart';

/// Rutas de pedidos: crear y ver los propios, para cualquier cuenta; el
/// listado y los cambios de estado, solo para admin y staff.
List<RouteEntry> ordersRoutes(
  OrdersService orders,
  FirebaseTokenVerifier verifier,
) {
  Route signedIn(Method method, ApiHandler handler) =>
      RoleGuard(anyRole, ApiRoute(method, handler), verifier: verifier);
  Route staffOnly(Method method, ApiHandler handler) =>
      RoleGuard(staffRoles, ApiRoute(method, handler), verifier: verifier);

  return [
    (
      '/orders',
      // El pedido queda a nombre de quien lo crea. Sin precios ni total: los
      // pone el servidor con los precios de hoy.
      signedIn(Method.post, (session, request) async {
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {'deliveryAddress', 'items'},
        );
        final deliveryAddress = body.text('deliveryAddress', maxLength: 255);
        final items = body.objects(
          'items',
          allowed: const {'productId', 'quantity'},
          min: 1,
          max: 100,
        );
        final lines = [
          for (final item in items ?? const <InputReader>[])
            (
              productId: item.uuid('productId'),
              quantity: item.integer('quantity', min: 1, max: 999),
            ),
        ];
        body.check();

        final order = await orders.create(
          session,
          customer: request.currentUser,
          deliveryAddress: deliveryAddress!,
          lines: [
            for (final line in lines)
              (productId: line.productId!, quantity: line.quantity!),
          ],
        );
        return jsonResponse(201, orderJson(order));
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
          page.wrap(list.map(orderJson).toList(), total),
        );
      }),
    ),
    (
      '/orders',
      staffOnly(Method.get, (session, request) async {
        final query = InputReader.query(
          request,
          allowed: {...PageQuery.fields, 'status', 'from', 'to'},
        );
        final page = PageQuery.read(query);
        final status = query.oneOf(
          'status',
          OrderStatus.values,
          required: false,
        );
        final from = query.day('from', required: false);
        final to = query.day('to', required: false);
        query.check();

        final (list, total) = await orders.list(
          session,
          page,
          status: status,
          from: from,
          to: to,
        );
        return jsonResponse(
          200,
          page.wrap(list.map(adminOrderJson).toList(), total),
        );
      }),
    ),
    (
      '/orders/:id/status',
      staffOnly(Method.patch, (session, request) async {
        final id = idParam(request);
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {'status'},
        );
        final status = body.oneOf('status', OrderStatus.values);
        body.check();

        final order = await orders.changeStatus(
          session,
          id,
          status!,
          by: request.currentUser,
        );
        return jsonResponse(200, adminOrderJson(order));
      }),
    ),
  ];
}

/// El pedido con sus líneas, como lo lee la app (`Order.fromJson`). Montos
/// como texto ("4.5") y estado como en el modelo (`pendingConfirmation`,
/// `confirmed`…).
Map<String, Object?> orderJson(Order order) {
  return {
    'id': order.id.toString(),
    'status': order.status.name,
    'total': formatMoney(order.totalCents),
    'deliveryAddress': order.deliveryAddress,
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

/// Como [orderJson] y, además, quién lo hizo (para el panel).
Map<String, Object?> adminOrderJson(Order order) {
  final customer = order.customer!;
  return {
    ...orderJson(order),
    'customer': {
      'id': customer.id.toString(),
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
    },
  };
}
