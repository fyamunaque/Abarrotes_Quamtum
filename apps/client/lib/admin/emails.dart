/// Lo que respondió el servidor al agregar correos (a los clientes VIP o al
/// equipo). [added] y [duplicates] van normalizados; [invalid], como se
/// escribieron.
class EmailAddSummary {
  const EmailAddSummary({
    this.added = const [],
    this.duplicates = const [],
    this.invalid = const [],
  });

  factory EmailAddSummary.fromJson(Object? json) => switch (json) {
    {
      'added': final List<Object?> added,
      'duplicates': final List<Object?> duplicates,
      'invalid': final List<Object?> invalid,
    } =>
      EmailAddSummary(
        added: added.cast<String>(),
        duplicates: duplicates.cast<String>(),
        invalid: invalid.cast<String>(),
      ),
    _ => throw FormatException('No es un resumen', json),
  };

  final List<String> added;

  /// Repetidos en lo que se mandó o que ya estaban en la lista.
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
