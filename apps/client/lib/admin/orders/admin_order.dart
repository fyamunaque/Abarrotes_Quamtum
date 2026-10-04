import '../../orders/order.dart';

/// Un pedido como lo ve el staff: el pedido y quién lo hizo.
class AdminOrder {
  const AdminOrder({
    required this.order,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
  });

  /// Como lo manda `GET /orders` (el `AdminOrder` de packages/shared-types).
  factory AdminOrder.fromJson(Object? json) => switch (json) {
    {
      'customer':
          {'name': final String name, 'email': final String email} &&
          final Map<String, Object?> customer,
    } =>
      AdminOrder(
        order: Order.fromJson(json),
        customerName: name,
        customerEmail: email,
        customerPhone: customer['phone'] as String?,
      ),
    _ => throw FormatException('No es un pedido del panel', json),
  };

  final Order order;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;

  String get id => order.id;
}
