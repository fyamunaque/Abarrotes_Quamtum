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
}
