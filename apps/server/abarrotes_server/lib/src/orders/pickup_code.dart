import 'dart:math';

/// Los caracteres del código de recojo: dígitos y mayúsculas sin los que se
/// confunden al dictarlos o leerlos (0/O y 1/I). Son 32.
const pickupCodeAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

const pickupCodeLength = 6;

/// Genera un código de recojo (en los tests, uno fijo).
typedef PickupCodeGenerator = String Function();

final _random = Random.secure();

/// Un código al azar de [pickupCodeLength] caracteres de
/// [pickupCodeAlphabet]: unos mil millones posibles.
String randomPickupCode() => String.fromCharCodes([
  for (var i = 0; i < pickupCodeLength; i++)
    pickupCodeAlphabet.codeUnitAt(_random.nextInt(pickupCodeAlphabet.length)),
]);

/// Como lo escribe quien atiende en caja: sin espacios y en mayúsculas.
String normalizePickupCode(String code) =>
    code.replaceAll(RegExp(r'\s'), '').toUpperCase();
