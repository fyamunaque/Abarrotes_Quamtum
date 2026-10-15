/// Los datos de la tienda, como los manda `GET /store` (apps/server): dónde
/// y cuándo se recogen los pedidos.
class StoreSettings {
  const StoreSettings({
    required this.name,
    required this.address,
    this.reference,
    this.phone,
    this.openingHours,
    this.pickupInstructions,
  });

  factory StoreSettings.fromJson(Object? json) => switch (json) {
    {'name': final String name, 'address': final String address} &&
        final Map<Object?, Object?> map =>
      StoreSettings(
        name: name,
        address: address,
        reference: map['reference'] as String?,
        phone: map['phone'] as String?,
        openingHours: map['openingHours'] as String?,
        pickupInstructions: map['pickupInstructions'] as String?,
      ),
    _ => throw FormatException('No son los datos de la tienda', json),
  };

  final String name;

  /// Vacía mientras la tienda no la cargó.
  final String address;

  /// Cómo llegar ("frente al parque").
  final String? reference;
  final String? phone;

  /// El horario de atención, en texto.
  final String? openingHours;

  /// Qué hacer al llegar a recoger un pedido.
  final String? pickupInstructions;
}
