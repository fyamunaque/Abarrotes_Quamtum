/// Tipos de movimiento de stock, con los nombres del servidor.
enum MovementType {
  incoming('Entrada'),
  outgoing('Salida'),
  adjustment('Ajuste');

  const MovementType(this.label);

  final String label;
}

/// Un movimiento del historial de inventario.
class Movement {
  const Movement({
    required this.id,
    required this.type,
    required this.quantity,
    required this.createdAt,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.userName,
    this.reason,
  });

  /// Como lo manda `/inventory/movements`.
  factory Movement.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'type': final String type,
      'quantity': final int quantity,
      'createdAt': final String createdAt,
      'product': {
        'id': final String productId,
        'name': final String productName,
        'sku': final String sku,
      },
      'user': {'name': final String userName},
    }) {
      return Movement(
        id: id,
        type:
            MovementType.values.asNameMap()[type] ??
            (throw FormatException('Tipo desconocido', type)),
        quantity: quantity,
        reason: json['reason'] as String?,
        createdAt: DateTime.parse(createdAt),
        productId: productId,
        productName: productName,
        sku: sku,
        userName: userName,
      );
    }
    throw FormatException('No es un movimiento', json);
  }

  final String id;
  final MovementType type;

  /// En entradas y salidas, positiva; en un ajuste, la corrección con signo.
  final int quantity;

  final String? reason;
  final DateTime createdAt;
  final String productId;
  final String productName;
  final String sku;

  /// Quién lo originó: el staff que lo registró o el cliente del pedido.
  final String userName;

  /// Cuánto cambió el stock: negativo en las salidas.
  int get change => type == MovementType.outgoing ? -quantity : quantity;
}

/// Un movimiento por registrar.
class MovementInput {
  const MovementInput({
    required this.productId,
    required this.type,
    required this.quantity,
    this.reason,
  });

  final String productId;
  final MovementType type;
  final int quantity;
  final String? reason;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'type': type.name,
    'quantity': quantity,
    if (reason case final reason? when reason.trim().isNotEmpty)
      'reason': reason.trim(),
  };
}
