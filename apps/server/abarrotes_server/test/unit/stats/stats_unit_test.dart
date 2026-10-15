import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/stats/day_range.dart';
import 'package:abarrotes_server/src/stats/providers/overview_report_provider.dart';
import 'package:abarrotes_server/src/stats/report_provider.dart';
import 'package:abarrotes_server/src/stats/reports.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  group('resolveDayRange', () {
    const today = '2026-10-01';

    test('sin parámetros, los últimos 30 días hasta hoy', () {
      expect(resolveDayRange(today: today), (
        from: '2026-09-02',
        to: '2026-10-01',
      ));
    });

    test('sin from, los 30 días que terminan en to', () {
      expect(
        resolveDayRange(to: '2026-09-15', today: today).from,
        '2026-08-17',
      );
    });

    test('rechaza rangos invertidos o de más de un año', () {
      expect(
        () =>
            resolveDayRange(from: '2026-10-05', to: '2026-10-01', today: today),
        throwsA(isA<ApiException>()),
      );
      expect(
        () =>
            resolveDayRange(from: '2025-09-30', to: '2026-10-01', today: today),
        throwsA(isA<ApiException>()),
      );
      // 366 días sí.
      expect(
        resolveDayRange(from: '2025-10-01', to: '2026-10-01', today: today),
        (from: '2025-10-01', to: '2026-10-01'),
      );
    });
  });

  group('calendario de la tienda', () {
    test('eachDay incluye ambos extremos', () {
      expect(eachDay('2026-09-29', '2026-10-01'), [
        '2026-09-29',
        '2026-09-30',
        '2026-10-01',
      ]);
    });

    test('la semana empieza el lunes y el mes el día 1', () {
      // El 1 de octubre de 2026 es jueves.
      expect(startOfWeek('2026-10-01'), '2026-09-28');
      expect(startOfWeek('2026-09-28'), '2026-09-28');
      expect(startOfWeek('2026-10-04'), '2026-09-28');
      expect(startOfMonth('2026-10-17'), '2026-10-01');
    });
  });

  test(
    'el overview compone los reportes que recibe, sin consultar la base',
    () async {
      final sales = _FakeSales();
      final overview = OverviewReportProvider(
        sales: sales,
        orderStatus: _FakeOrderStatus(),
        fulfillment: _FakeFulfillment(),
        // Jueves 1 de octubre, 07:00 en Lima.
        now: () => DateTime.utc(2026, 10, 1, 12),
      );

      final report = await overview.getSummary(_NoSession(), null);

      expect(sales.requested, [
        (from: '2026-10-01', to: '2026-10-01'),
        (from: '2026-09-28', to: '2026-10-01'),
        (from: '2026-10-01', to: '2026-10-01'),
      ]);
      expect(report.week.range.from, '2026-09-28');
      expect(report.ordersByStatus[OrderStatus.delivered], 7);
      expect(report.ordersByFulfillment[FulfillmentType.pickup], 2);
      expect(report.generatedAt, DateTime.utc(2026, 10, 1, 12));
    },
  );
}

class _FakeSales extends ReportProvider<DayRange, SalesReport> {
  final requested = <DayRange>[];

  @override
  Future<SalesReport> getSummary(Session session, DayRange range) async {
    requested.add(range);
    return (range: range, totalCents: 0, orders: 0, daily: <SalesPoint>[]);
  }
}

class _FakeOrderStatus extends ReportProvider<void, OrdersByStatus> {
  @override
  Future<OrdersByStatus> getSummary(Session session, void range) async => {
    OrderStatus.delivered: 7,
  };
}

class _FakeFulfillment extends ReportProvider<void, OrdersByFulfillment> {
  @override
  Future<OrdersByFulfillment> getSummary(Session session, void range) async => {
    FulfillmentType.delivery: 5,
    FulfillmentType.pickup: 2,
  };
}

/// Los reportes falsos no usan la sesión.
class _NoSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('El reporte no debería usar la sesión');
}
