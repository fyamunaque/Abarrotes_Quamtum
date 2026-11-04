import 'package:serverpod/serverpod.dart';

import '../auth/guards.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart';
import 'inventory_service.dart';
import 'stock_alerts.dart';
import 'stock_alerts_json.dart';

/// Rutas de inventario: verlo pide `inventory.view` y registrar un
/// movimiento, `inventory.adjust`.
List<RouteEntry> inventoryRoutes(
  InventoryService inventory,
  StockAlerts alerts,
  Guards guards,
) {
  Route view(Method method, ApiHandler handler) =>
      guards.require(Permission.inventoryView, ApiRoute(method, handler));
  Route adjust(Method method, ApiHandler handler) =>
      guards.require(Permission.inventoryAdjust, ApiRoute(method, handler));

  return [
    (
      '/inventory/movements',
      adjust(Method.post, (session, request) async {
        final input = _readMovement(await readJsonBody(request));
        final movement = await inventory.record(
          session,
          input,
          by: request.currentUser,
        );
        return jsonResponse(201, {
          ...movementJson(movement),
          // El producto como quedó después del movimiento.
          'product': {
            ..._productJson(movement.product!),
            'currentStock': movement.product!.currentStock,
          },
        });
      }),
    ),
    (
      '/inventory/movements',
      view(Method.get, (session, request) async {
        final query = InputReader.query(
          request,
          allowed: {
            ...PageQuery.fields,
            'productId',
            'origin',
            'categoryId',
            'search',
            'from',
            'to',
          },
        );
        final page = PageQuery.read(query);
        final productId = query.uuid('productId', required: false);
        final origin = query.oneOf(
          'origin',
          MovementOrigin.values,
          required: false,
        );
        final categoryId = query.uuid('categoryId', required: false);
        final search = query.text('search', maxLength: 100, required: false);
        final from = query.day('from', required: false);
        final to = query.day('to', required: false);
        query.check();

        final (list, total) = await inventory.list(
          session,
          page,
          productId: productId,
          origin: origin,
          categoryId: categoryId,
          search: search,
          from: from,
          to: to,
        );
        return jsonResponse(
          200,
          page.wrap(list.map(movementJson).toList(), total),
        );
      }),
    ),
    (
      '/inventory/alerts/low-stock',
      view(Method.get, (session, request) async {
        InputReader.query(request, allowed: const {}).check();
        return jsonResponse(
          200,
          lowStockReportJson(await alerts.lowStock(session)),
        );
      }),
    ),
    (
      '/inventory/alerts/expiring',
      view(Method.get, (session, request) async {
        final query = InputReader.query(request, allowed: const {'days'});
        final days =
            query.integer('days', min: 1, max: 365, required: false) ?? 7;
        query.check();

        return jsonResponse(
          200,
          expiringReportJson(await alerts.expiring(session, days)),
        );
      }),
    ),
  ];
}

/// Body de POST /inventory/movements. Entrada y salida llevan una cantidad
/// positiva; el ajuste, la corrección con signo (distinta de 0) y su motivo.
MovementInput _readMovement(Object? json) {
  final body = InputReader.body(
    json,
    allowed: const {'productId', 'type', 'quantity', 'reason'},
  );
  final productId = body.uuid('productId');
  final type = body.oneOf('type', MovementType.values);
  final quantity = body.integer(
    'quantity',
    min: -_maxQuantity,
    max: _maxQuantity,
  );
  final reason = body.text('reason', maxLength: 300, nullable: true);
  if (type == MovementType.adjustment) {
    if (quantity == 0) body.reject('quantity no puede ser 0 en un ajuste');
    if (reason == null) body.reject('reason es obligatorio en un ajuste');
  } else if (type != null && quantity != null && quantity < 1) {
    body.reject('quantity debe ser mayor que 0 en una ${_typeLabel[type]}');
  }
  body.check();
  return (
    productId: productId!,
    type: type!,
    quantity: quantity!,
    reason: reason,
  );
}

const _maxQuantity = 1000000;
const _typeLabel = {
  MovementType.incoming: 'entrada',
  MovementType.outgoing: 'salida',
};

/// Un movimiento como lo lee la app (`Movement.fromJson`), con el tipo en
/// minúsculas (`incoming`, `outgoing`, `adjustment`).
Map<String, Object?> movementJson(InventoryMovement movement) => {
  'id': movement.id.toString(),
  'type': movement.type.name,
  'quantity': movement.quantity,
  'reason': movement.reason,
  'createdAt': movement.createdAt.toUtc().toIso8601String(),
  'product': _productJson(movement.product!),
  // Quién lo originó: el cliente del pedido o el staff que lo registró.
  'user': {'id': movement.user!.id.toString(), 'name': movement.user!.name},
  // El pedido que lo originó; null si se registró a mano.
  'order': switch (movement.order) {
    final order? => {'id': order.id.toString(), 'number': order.number},
    null => null,
  },
};

Map<String, Object?> _productJson(Product product) => {
  'id': product.id.toString(),
  'name': product.name,
  'sku': product.sku,
};
