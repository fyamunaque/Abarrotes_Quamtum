import '../auth/firebase_identity.dart';
import '../generated/protocol.dart';

/// La versión vigente de los términos de uso y la política de privacidad (la
/// misma que `termsVersion` en apps/client/lib/legal/legal_texts.dart). Si
/// los textos cambian, se sube esta fecha y cada cuenta los vuelve a aceptar
/// antes de pedir.
const currentTermsVersion = '2026-10-28';

/// [text] como celular peruano normalizado ("987654321"), o null si no es uno:
/// 9 dígitos que empiezan con 9. Admite espacios, guiones, puntos y el
/// prefijo +51 (o 51) delante.
String? normalizePhone(String text) {
  var digits = text.replaceAll(RegExp(r'[\s\-.()]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  if (digits.length == 11 && digits.startsWith('51')) {
    digits = digits.substring(2);
  }
  return RegExp(r'^9\d{8}$').hasMatch(digits) ? digits : null;
}

/// Si [text] es un DNI: 8 dígitos.
bool isValidDni(String text) => RegExp(r'^\d{8}$').hasMatch(text);

/// Si la cuenta tiene lo que pide un pedido además del correo confirmado: el
/// celular y la versión vigente de los términos aceptada.
bool isProfileComplete(User user) =>
    user.phone != null && user.termsVersion == currentTermsVersion;

/// Lo que le falta a [user] para hacer un pedido, como mensaje para la
/// persona, o null si puede pedir: el correo confirmado ([identity], del
/// token), el celular y los términos vigentes.
String? missingToOrder(User user, FirebaseIdentity identity) {
  if (!identity.emailVerified) {
    return 'Confirma tu correo para hacer pedidos: te enviamos un enlace.';
  }
  if (!isProfileComplete(user)) {
    return 'Completa tu cuenta para hacer pedidos: tu celular y aceptar los '
        'términos.';
  }
  return null;
}
