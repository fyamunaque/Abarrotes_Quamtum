import 'package:flutter_test/flutter_test.dart';
import 'package:neils/common/money.dart';

void main() {
  test('soles con dos decimales y un espacio que no se corta', () {
    expect(formatSoles(450), 'S/ 4.50');
    expect(formatSoles(2490), 'S/ 24.90');
    expect(formatSoles(5), 'S/ 0.05');
    expect(formatSoles(0), 'S/ 0.00');
    expect(formatSoles(123456), 'S/ 1234.56');
    expect(formatSoles(-890), '-S/ 8.90');
  });

  test('los montos del servidor en céntimos', () {
    expect(parseCents('4.5'), 450);
    expect(parseCents('8.90'), 890);
    expect(parseCents('10'), 1000);
    expect(parseCents('0.05'), 5);
    expect(parseCents('-1.2'), -120);
    for (final bad in ['', '4.555', '4,5', 'S/ 4.50', '.5']) {
      expect(() => parseCents(bad), throwsFormatException, reason: bad);
    }
  });

  test('lo que escribe la persona: punto o coma, sin signo', () {
    expect(parseSolesInput('24.90'), 2490);
    expect(parseSolesInput(' 24,9 '), 2490);
    expect(parseSolesInput('24'), 2400);
    expect(parseSolesInput('0'), 0);
    for (final bad in ['', '-5', '24.999', 'S/ 24', '24.9.0', 'abc']) {
      expect(parseSolesInput(bad), isNull, reason: bad);
    }
  });

  test('un monto para un campo de texto', () {
    expect(formatSolesInput(2490), '24.90');
    expect(formatSolesInput(5), '0.05');
    expect(formatSolesInput(1000), '10.00');
  });
}
