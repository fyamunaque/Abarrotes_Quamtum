import 'package:flutter_test/flutter_test.dart';
import 'package:neils/common/days.dart';

void main() {
  test('días de la tienda: AAAA-MM-DD de ida y vuelta', () {
    expect(formatDay(DateTime(2026, 3, 7, 18, 30)), '2026-03-07');
    expect(parseDay('2026-11-02'), DateTime(2026, 11, 2));
    expect(formatDay(parseDay('2026-01-31')), '2026-01-31');
    for (final bad in ['2026-1-31', '31/01/2026', '']) {
      expect(() => parseDay(bad), throwsFormatException, reason: bad);
    }
  });
}
