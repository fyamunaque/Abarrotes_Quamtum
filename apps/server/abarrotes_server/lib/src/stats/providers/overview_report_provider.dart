import 'package:serverpod/serverpod.dart';

import '../../common/store_time.dart';
import '../report_provider.dart';
import '../reports.dart';

/// Resumen del dashboard: ventas de hoy, de la semana (desde el lunes) y del
/// mes, y los pedidos por estado y por tipo de entrega. No consulta la base:
/// compone otros reportes, que recibe como abstracciones.
class OverviewReportProvider extends ReportProvider<void, StatsOverview> {
  OverviewReportProvider({
    required this.sales,
    required this.orderStatus,
    required this.fulfillment,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ReportProvider<DayRange, SalesReport> sales;
  final ReportProvider<void, OrdersByStatus> orderStatus;
  final ReportProvider<void, OrdersByFulfillment> fulfillment;
  final DateTime Function() _now;

  @override
  Future<StatsOverview> getSummary(Session session, void range) async {
    final now = _now().toUtc();
    final today = storeDay(now);
    return (
      generatedAt: now,
      today: await sales.getSummary(session, (from: today, to: today)),
      week: await sales.getSummary(session, (
        from: startOfWeek(today),
        to: today,
      )),
      month: await sales.getSummary(session, (
        from: startOfMonth(today),
        to: today,
      )),
      ordersByStatus: await orderStatus.getSummary(session, null),
      ordersByFulfillment: await fulfillment.getSummary(session, null),
    );
  }
}
