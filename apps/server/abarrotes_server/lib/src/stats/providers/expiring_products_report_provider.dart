import 'package:serverpod/serverpod.dart';

import '../../inventory/stock_alerts.dart';
import '../report_provider.dart';

/// Productos activos con stock que vencen de hoy a hoy + [days] (hora de
/// Lima), incluidos los ya vencidos. La consulta es la de inventory
/// (StockAlerts).
class ExpiringProductsReportProvider
    extends ReportProvider<int, ExpiringProducts> {
  const ExpiringProductsReportProvider(this._alerts);

  final StockAlerts _alerts;

  @override
  Future<ExpiringProducts> getSummary(Session session, int days) =>
      _alerts.expiring(session, days);
}
