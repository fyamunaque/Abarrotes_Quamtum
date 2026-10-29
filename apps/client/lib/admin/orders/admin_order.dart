import '../../orders/order.dart';

/// Quién hizo un pedido: sus datos de contacto y, si lo agregó, su DNI (para
/// confirmar quién recibe o recoge el pedido).
class OrderCustomer {
  const OrderCustomer({
    required this.name,
    required this.email,
    this.phone,
    this.dni,
  });

  final String name;
  final String email;
  final String? phone;
  final String? dni;
}

/// Un pedido como lo ve el personal: el pedido y quién lo hizo.
class AdminOrder {
  const AdminOrder({required this.order, this.customer});

  /// Como lo manda `GET /orders` del servidor. Sin el permiso
  /// `customers.view`, el servidor no manda los datos del cliente.
  factory AdminOrder.fromJson(Object? json) => switch (json) {
    {'customer': null} => AdminOrder(order: Order.fromJson(json)),
    {
      'customer':
          {'name': final String name, 'email': final String email} &&
          final Map<String, Object?> customer,
    } =>
      AdminOrder(
        order: Order.fromJson(json),
        customer: OrderCustomer(
          name: name,
          email: email,
          phone: customer['phone'] as String?,
          dni: customer['dni'] as String?,
        ),
      ),
    _ => throw FormatException('No es un pedido del panel', json),
  };

  final Order order;

  /// Null si la cuenta no puede ver los datos de los clientes.
  final OrderCustomer? customer;

  String get id => order.id;
}
