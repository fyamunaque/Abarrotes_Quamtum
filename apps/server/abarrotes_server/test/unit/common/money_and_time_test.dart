import 'package:abarrotes_server/src/common/money.dart';
import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:test/test.dart';

void main() {
  group('formatMoney', () {
    test('escribe los céntimos como texto, sin ceros finales', () {
      expect(formatMoney(450), '4.5');
      expect(formatMoney(1200), '12');
      expect(formatMoney(5), '0.05');
      expect(formatMoney(399), '3.99');
      expect(formatMoney(0), '0');
    });
  });

  group('toCents', () {
    test('convierte montos con hasta dos decimales', () {
      expect(toCents(4.5), 450);
      expect(toCents(0.1 + 0.2), 30);
      expect(toCents(19.99), 1999);
      expect(toCents(12), 1200);
    });

    test('rechaza más de dos decimales', () {
      expect(toCents(4.555), isNull);
      expect(toCents(0.001), isNull);
    });
  });

  group('hora de la tienda (Lima, UTC-5)', () {
    test('storeDay usa la fecha de Lima, no la UTC', () {
      // 03:00 UTC del 2 de octubre son las 22:00 del 1 en Lima.
      expect(storeDay(DateTime.utc(2026, 10, 2, 3)), '2026-10-01');
      expect(storeDay(DateTime.utc(2026, 10, 2, 5)), '2026-10-02');
    });

    test('storeDayStart es la medianoche de Lima en UTC', () {
      expect(storeDayStart('2026-10-01'), DateTime.utc(2026, 10, 1, 5));
    });

    test('addDays cruza meses y años', () {
      expect(addDays('2026-12-31', 1), '2027-01-01');
      expect(addDays('2026-03-01', -1), '2026-02-28');
    });

    test('daysBetween cuenta días de calendario', () {
      expect(daysBetween('2026-10-01', '2026-10-08'), 7);
      expect(daysBetween('2026-10-01', '2026-09-30'), -1);
      expect(daysBetween('2026-12-31', '2027-01-01'), 1);
    });

    test('las fechas sin hora se guardan a medianoche UTC y se leen igual', () {
      expect(utcMidnight('2027-03-31'), DateTime.utc(2027, 3, 31));
      // A diferencia de storeDay, que la pasaría al 30 en hora de Lima.
      expect(calendarDay(DateTime.utc(2027, 3, 31)), '2027-03-31');
      expect(storeDay(DateTime.utc(2027, 3, 31)), '2027-03-30');
    });

    test('isValidDay exige un día real AAAA-MM-DD', () {
      expect(isValidDay('2026-10-01'), isTrue);
      expect(isValidDay('2026-02-30'), isFalse);
      expect(isValidDay('2026-10-1'), isFalse);
      expect(isValidDay('01/10/2026'), isFalse);
    });
  });
}
