import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/vip/vip_customer.dart';

/// Las mismas reglas que el servidor (`VipService` en apps/server).
void main() {
  test('normalizeEmail: minúsculas y sin espacios en ninguna parte', () {
    expect(normalizeEmail('  Ana.Rojas@Gmail.COM '), 'ana.rojas@gmail.com');
    expect(normalizeEmail('luis @ tienda.pe'), 'luis@tienda.pe');
  });

  test('isValidEmail: usuario, dominio y extensión', () {
    for (final email in ['ana@gmail.com', 'ana.rojas+vip@tienda.com.pe']) {
      expect(isValidEmail(email), isTrue, reason: email);
    }
    for (final email in [
      '',
      'ana',
      'ana@',
      '@gmail.com',
      'ana@gmail',
      'ana@gmail.c',
      'ana@@gmail.com',
      'ana@gmail..com',
    ]) {
      expect(isValidEmail(email), isFalse, reason: email);
    }
    expect(isValidEmail('${'a' * 64}@${'b' * 186}.com'), isFalse);
  });

  test('splitEmails: por coma, punto y coma o salto de línea', () {
    expect(
      splitEmails(
        ' ana@gmail.com, luis@hotmail.com\n\nmaria@tienda.pe;\r\n'
        'pedro@gmail.com ,, ',
      ),
      [
        'ana@gmail.com',
        'luis@hotmail.com',
        'maria@tienda.pe',
        'pedro@gmail.com',
      ],
    );
    expect(splitEmails(' \n , '), isEmpty);
  });
}
