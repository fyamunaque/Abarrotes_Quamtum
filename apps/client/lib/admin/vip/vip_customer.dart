/// Un cliente VIP: un correo que puede usar las promociones VIP (cuando
/// ingresa con ese correo verificado).
class VipCustomer {
  const VipCustomer({
    required this.id,
    required this.email,
    required this.active,
    required this.createdAt,
    required this.hasAccount,
    this.addedByName,
  });

  /// Como lo manda `/vip-customers`.
  factory VipCustomer.fromJson(Object? json) => switch (json) {
    {
          'id': final String id,
          'email': final String email,
          'active': final bool active,
          'createdAt': final String createdAt,
          'hasAccount': final bool hasAccount,
        } &&
        final Map<Object?, Object?> map =>
      VipCustomer(
        id: id,
        email: email,
        active: active,
        createdAt: DateTime.parse(createdAt),
        hasAccount: hasAccount,
        addedByName: switch (map['addedBy']) {
          {'name': final String name} => name,
          _ => null,
        },
      ),
    _ => throw FormatException('No es un cliente VIP', json),
  };

  final String id;
  final String email;

  /// Dado de baja: deja de ser VIP, pero queda en el historial.
  final bool active;

  /// La fecha de alta.
  final DateTime createdAt;

  /// Si ese correo ya tiene una cuenta en la tienda.
  final bool hasAccount;

  /// El admin que lo agregó.
  final String? addedByName;
}
