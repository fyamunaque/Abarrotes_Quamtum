import 'package:abarrotes_server/src/vip/vip_service.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeEmail', () {
    test('pasa a minúsculas y quita los espacios de cualquier parte', () {
      expect(
        VipService.normalizeEmail('  Ana.Rojas@Gmail.COM '),
        'ana.rojas@gmail.com',
      );
      expect(VipService.normalizeEmail('luis @ tienda.pe'), 'luis@tienda.pe');
      expect(
        VipService.normalizeEmail('\tmaria@tienda.pe\n'),
        'maria@tienda.pe',
      );
    });
  });

  group('isValidEmail', () {
    test('acepta correos con usuario, dominio y extensión', () {
      for (final email in [
        'ana@gmail.com',
        'ana.rojas+vip@tienda.com.pe',
        'a_b-c@sub.dominio.org',
      ]) {
        expect(VipService.isValidEmail(email), isTrue, reason: email);
      }
    });

    test('rechaza lo que no tiene forma de correo', () {
      for (final email in [
        '',
        'ana',
        'ana@',
        '@gmail.com',
        'ana@gmail',
        'ana@gmail.c',
        'ana@@gmail.com',
        'ana@gmail..com',
        'ana@.com',
        'ana rojas@gmail.com',
      ]) {
        expect(VipService.isValidEmail(email), isFalse, reason: email);
      }
    });

    test('rechaza más de 254 caracteres', () {
      final long = '${'a' * 64}@${'b' * 185}.com';
      expect(long.length, 254);
      expect(VipService.isValidEmail(long), isTrue);
      expect(VipService.isValidEmail('a$long'), isFalse);
    });
  });
}
