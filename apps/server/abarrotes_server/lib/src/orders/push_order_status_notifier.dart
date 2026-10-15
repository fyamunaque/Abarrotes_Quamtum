import 'dart:async';

// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

import '../generated/protocol.dart';
import '../push/device_push.dart';
import '../push/push_sender.dart';
import 'order_status_notifier.dart';

/// Avisa por push al dueño del pedido cuando cambia de estado, a cada uno de
/// sus dispositivos, con un texto según el tipo de entrega y el estado (ver
/// [orderStatusMessage]).
class PushOrderStatusNotifier implements OrderStatusNotifier {
  PushOrderStatusNotifier({required this._sender, required this._run});

  final PushSender _sender;
  final SessionRunner _run;

  /// En segundo plano, con su propia sesión: el estado ya cambió y la
  /// respuesta no espera. Si algo falla, queda en el log de esa sesión.
  @override
  void statusChanged(Order order) {
    if (orderStatusMessage(order) == null) return;
    unawaited(
      _run((session) => notifyNow(session, order)).catchError((Object _) {
        // withSession ya lo dejó en el log.
      }),
    );
  }

  /// Manda el aviso de [order] y deja el resumen en el log.
  Future<PushSummary> notifyNow(Session session, Order order) async {
    final message = orderStatusMessage(order);
    if (message == null) return (sent: 0, invalid: 0, failed: 0);
    if (!_sender.enabled) {
      session.log(
        'Aviso push del pedido ${order.id}: el envío push no está '
        'configurado (fcmServiceAccountFile)',
      );
      return (sent: 0, invalid: 0, failed: 0);
    }
    final devices = await DeviceToken.db.find(
      session,
      where: (device) => device.userId.equals(order.customerId),
    );
    final summary = await pushToDevices(session, _sender, devices, message);
    session.log(
      'Aviso push del pedido ${order.id} (${order.status.name}): '
      '${summary.sent} enviados, ${summary.invalid} tokens inválidos '
      'borrados, ${summary.failed} fallidos',
      level: summary.failed > 0 ? LogLevel.warning : LogLevel.info,
    );
    return summary;
  }
}

/// El aviso para el cliente del estado actual de [order], según su tipo de
/// entrega; null si ese estado no avisa (pendiente, recién creado). Los
/// datos dicen a la app qué pedido abrir. La dirección no va: el aviso se ve
/// en la pantalla bloqueada.
PushMessage? orderStatusMessage(Order order) {
  final pickup = order.fulfillmentType == FulfillmentType.pickup;
  final (String, String)? text = switch (order.status) {
    OrderStatus.pendingConfirmation => null,
    OrderStatus.confirmed => (
      'Confirmamos tu pedido',
      pickup
          ? 'Te avisamos cuando empecemos a prepararlo.'
          : 'Lo estamos alistando para enviártelo.',
    ),
    OrderStatus.preparing => (
      'Estamos preparando tu pedido',
      'Te avisamos cuando esté listo para recoger.',
    ),
    OrderStatus.readyForPickup => (
      'Tu pedido está listo',
      'Tu pedido está listo para recoger en tienda, tu código es '
          '${order.pickupCode}.',
    ),
    OrderStatus.outForDelivery => (
      'Tu pedido está en camino',
      'Pronto llega a la dirección que nos diste.',
    ),
    OrderStatus.delivered =>
      pickup
          ? ('Recogiste tu pedido', '¡Gracias por tu compra!')
          : ('Entregamos tu pedido', '¡Gracias por tu compra!'),
    OrderStatus.cancelled => (
      'Cancelamos tu pedido',
      'Si tienes dudas, escríbenos.',
    ),
  };
  if (text == null) return null;
  final (title, body) = text;
  return PushMessage(
    title: title,
    body: body,
    data: {
      'type': 'order_status',
      'orderId': order.id.toString(),
      'status': order.status.name,
    },
  );
}
