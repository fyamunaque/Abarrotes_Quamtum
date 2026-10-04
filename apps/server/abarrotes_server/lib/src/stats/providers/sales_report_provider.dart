import 'package:serverpod/serverpod.dart';

import '../../common/store_time.dart';
import '../day_range.dart';
import '../report_provider.dart';
import '../reports.dart';

/// Ventas de un rango de días: totales y un punto por día, también los días
/// sin ventas. Cuentan solo los pedidos que la tienda aceptó (saleStatuses).
class SalesReportProvider extends ReportProvider<DayRange, SalesReport> {
  const SalesReportProvider();

  @override
  Future<SalesReport> getSummary(Session session, DayRange range) async {
    final bounds = utcBounds(range);
    // Agrupa en la base por día de la tienda: createdAt se guarda en UTC sin
    // zona horaria.
    final rows = await session.db.unsafeQuery(
      '''
      SELECT to_char(("createdAt" AT TIME ZONE 'UTC') AT TIME ZONE @timeZone,
                     'YYYY-MM-DD') AS day,
             COUNT(*)::int AS orders,
             SUM("totalCents")::bigint AS total
      FROM orders
      WHERE status = ANY(@statuses::text[])
        AND "createdAt" >= @start::timestamp
        AND "createdAt" < @end::timestamp
      GROUP BY day
      ORDER BY day
      ''',
      parameters: QueryParameters.named({
        'timeZone': storeTimeZone,
        'statuses': [for (final status in saleStatuses) status.name],
        'start': bounds.start,
        'end': bounds.end,
      }),
    );

    final byDay = {
      for (final row in rows.map((row) => row.toColumnMap()))
        row['day'] as String: row,
    };
    final daily = [
      for (final date in eachDay(range.from, range.to))
        (
          date: date,
          totalCents: (byDay[date]?['total'] as int?) ?? 0,
          orders: (byDay[date]?['orders'] as int?) ?? 0,
        ),
    ];
    return (
      range: range,
      totalCents: daily.fold(0, (sum, point) => sum + point.totalCents),
      orders: daily.fold(0, (sum, point) => sum + point.orders),
      daily: daily,
    );
  }
}
