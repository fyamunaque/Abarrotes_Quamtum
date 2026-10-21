/// Correos como se guardan (VIP, personal): en minúsculas y sin espacios en
/// ninguna parte.
String normalizeEmail(String email) =>
    email.replaceAll(RegExp(r'\s'), '').toLowerCase();

/// Un formato razonable de correo ya normalizado: `algo@dominio.tld`, hasta
/// 254 caracteres. No comprueba que el correo exista.
bool isValidEmail(String email) =>
    email.length <= 254 && _emailPattern.hasMatch(email);

final _emailPattern = RegExp(r'^[^@\s]+@([^@\s.]+\.)+[^@\s.]{2,}$');

/// El resultado de agregar varios correos a la vez (VIP, personal). Los
/// agregados y los duplicados van normalizados; los inválidos, como llegaron
/// (sin espacios en los bordes), para que se reconozcan.
typedef EmailAddSummary = ({
  List<String> added,
  List<String> duplicates,
  List<String> invalid,
});

/// Separa [emails] en candidatos (normalizados, válidos y sin repetir, en
/// orden), repetidos e inválidos.
({List<String> candidates, List<String> duplicates, List<String> invalid})
sortEmails(List<String> emails) {
  final candidates = <String>[];
  final duplicates = <String>[];
  final invalid = <String>[];
  final seen = <String>{};
  for (final raw in emails) {
    final email = normalizeEmail(raw);
    if (!isValidEmail(email)) {
      invalid.add(raw.trim());
    } else if (!seen.add(email)) {
      duplicates.add(email);
    } else {
      candidates.add(email);
    }
  }
  return (candidates: candidates, duplicates: duplicates, invalid: invalid);
}
