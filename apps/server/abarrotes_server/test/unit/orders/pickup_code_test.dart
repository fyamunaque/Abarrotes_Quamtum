import 'package:abarrotes_server/src/orders/pickup_code.dart';
import 'package:test/test.dart';

void main() {
  test('el alfabeto: 32 caracteres, sin los que se confunden', () {
    expect(pickupCodeAlphabet.length, 32);
    expect(pickupCodeAlphabet.split('').toSet(), hasLength(32));
    for (final ambiguous in ['0', 'O', '1', 'I']) {
      expect(pickupCodeAlphabet, isNot(contains(ambiguous)));
    }
  });

  test('6 caracteres del alfabeto, distintos cada vez', () {
    final codes = [for (var i = 0; i < 2000; i++) randomPickupCode()];

    final valid = RegExp('^[$pickupCodeAlphabet]{$pickupCodeLength}\$');
    expect(codes.every(valid.hasMatch), isTrue);
    // Con mil millones posibles, 2000 al azar no se repiten.
    expect(codes.toSet(), hasLength(codes.length));
  });

  test('como lo escribe quien atiende: sin espacios y en mayúsculas', () {
    expect(normalizePickupCode(' k7m 2xq\n'), 'K7M2XQ');
  });
}
