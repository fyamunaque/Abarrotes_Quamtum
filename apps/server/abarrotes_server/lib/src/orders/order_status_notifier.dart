import '../generated/protocol.dart';

/// Avisa al cliente que su pedido cambió de estado (p. ej. un push). orders
/// solo dice cuándo; cómo lo decide la implementación, que se arma en
/// `server.dart`.
abstract interface class OrderStatusNotifier {
  /// [order] acaba de pasar a su estado actual (el cambio ya se guardó). No
  /// espera ni lanza: lo que haga corre aparte y sus errores van al log.
  void statusChanged(Order order);
}

/// No avisa a nadie.
class NoOrderStatusNotifier implements OrderStatusNotifier {
  const NoOrderStatusNotifier();

  @override
  void statusChanged(Order order) {}
}
