import 'package:flutter_test/flutter_test.dart';
import 'package:neils/features/admin/home/greeting.dart';

void main() {
  test('el saludo sigue la hora de Lima', () {
    // 14:00 UTC son las 9:00 en Lima.
    expect(greetingFor(DateTime.utc(2026, 11, 5, 14)), 'Buenos días');
    // 20:00 UTC son las 15:00.
    expect(greetingFor(DateTime.utc(2026, 11, 5, 20)), 'Buenas tardes');
    // 2:00 UTC son las 21:00 del día anterior.
    expect(greetingFor(DateTime.utc(2026, 11, 5, 2)), 'Buenas noches');
    // Los bordes: las 12:00 y las 19:00 de Lima.
    expect(greetingFor(DateTime.utc(2026, 11, 5, 17)), 'Buenas tardes');
    expect(greetingFor(DateTime.utc(2026, 11, 6)), 'Buenas noches');
    expect(greetingFor(DateTime.utc(2026, 11, 5, 16, 59)), 'Buenos días');
  });
}
