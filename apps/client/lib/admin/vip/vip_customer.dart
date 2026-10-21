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

/// Lo que respondió el servidor al agregar correos. [added] y [duplicates]
/// van normalizados; [invalid], como se escribieron.
class VipAddSummary {
  const VipAddSummary({
    this.added = const [],
    this.duplicates = const [],
    this.invalid = const [],
  });

  factory VipAddSummary.fromJson(Object? json) => switch (json) {
    {
      'added': final List<Object?> added,
      'duplicates': final List<Object?> duplicates,
      'invalid': final List<Object?> invalid,
    } =>
      VipAddSummary(
        added: added.cast<String>(),
        duplicates: duplicates.cast<String>(),
        invalid: invalid.cast<String>(),
      ),
    _ => throw FormatException('No es un resumen', json),
  };

  final List<String> added;

  /// Repetidos en lo que se mandó o que ya eran VIP.
  final List<String> duplicates;
  final List<String> invalid;
}

/// Cuántos correos acepta el servidor por vez.
const maxEmailsPerAdd = 500;

/// Como los guarda el servidor: en minúsculas y sin espacios.
String normalizeEmail(String email) =>
    email.replaceAll(RegExp(r'\s'), '').toLowerCase();

/// El mismo formato que acepta el servidor (`algo@dominio.tld`, hasta 254
/// caracteres), sobre el correo ya normalizado.
bool isValidEmail(String email) =>
    email.length <= 254 && _emailPattern.hasMatch(email);

final _emailPattern = RegExp(r'^[^@\s]+@([^@\s.]+\.)+[^@\s.]{2,}$');

/// Los correos de un texto pegado: separados por coma, punto y coma o salto
/// de línea, sin los vacíos.
List<String> splitEmails(String text) => [
  for (final part in text.split(RegExp(r'[,;\n\r]+')))
    if (part.trim().isNotEmpty) part.trim(),
];
