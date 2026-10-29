import 'package:abarrotes_server/src/auth/firebase_identity.dart';
import 'package:abarrotes_server/src/common/customer_requirements.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

/// Lo que pide una cuenta para hacer pedidos: el celular, el DNI (opcional)
/// y los términos vigentes, con el correo confirmado.
void main() {
  test('el celular: 9 dígitos que empiezan con 9, con o sin +51', () {
    expect(normalizePhone('987654321'), '987654321');
    expect(normalizePhone('987 654 321'), '987654321');
    expect(normalizePhone('987-654-321'), '987654321');
    expect(normalizePhone('+51 987 654 321'), '987654321');
    expect(normalizePhone('51987654321'), '987654321');
    expect(normalizePhone('(01) 4567890'), isNull);
    expect(normalizePhone('887654321'), isNull);
    expect(normalizePhone('98765432'), isNull);
    expect(normalizePhone('9876543210'), isNull);
    expect(normalizePhone('98765432a'), isNull);
  });

  test('el DNI: 8 dígitos', () {
    expect(isValidDni('45678912'), isTrue);
    expect(isValidDni('4567891'), isFalse);
    expect(isValidDni('456789123'), isFalse);
    expect(isValidDni('4567891a'), isFalse);
  });

  group('lo que falta para pedir', () {
    final complete = User(
      firebaseUid: 'uid-ana',
      email: 'ana@tienda.pe',
      name: 'Ana',
      phone: '987654321',
      termsVersion: currentTermsVersion,
    );
    const verified = FirebaseIdentity(uid: 'uid-ana', emailVerified: true);

    test('con todo, nada', () {
      expect(isProfileComplete(complete), isTrue);
      expect(missingToOrder(complete, verified), isNull);
    });

    test('primero el correo confirmado', () {
      expect(
        missingToOrder(complete, const FirebaseIdentity(uid: 'uid-ana')),
        contains('Confirma tu correo'),
      );
    });

    test('el celular y los términos vigentes', () {
      for (final user in [
        complete.copyWith(phone: null),
        complete.copyWith(termsVersion: null),
        complete.copyWith(termsVersion: '2020-01-01'),
      ]) {
        expect(isProfileComplete(user), isFalse);
        expect(missingToOrder(user, verified), contains('Completa tu cuenta'));
      }
    });
  });
}
