import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../../inventory/stock_alerts.dart';
import '../report_provider.dart';

/// Productos activos con currentStock <= minStock, los más críticos primero.
/// La consulta y el orden son los de inventory (StockAlerts): stats no
/// define otra vez qué es "stock bajo".
class LowStockReportProvider extends ReportProvider<void, List<Product>> {
  const LowStockReportProvider(this._alerts);

  final StockAlerts _alerts;

  @override
  Future<List<Product>> getSummary(Session session, void range) =>
      _alerts.lowStock(session);
}
