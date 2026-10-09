import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../report_provider.dart';
import '../reports.dart';

/// Cantidad de pedidos en cada estado, de cualquier fecha. Los estados sin
/// pedidos van en 0.
class OrderStatusReportProvider extends ReportProvider<void, OrdersByStatus> {
  const OrderStatusReportProvider();

  @override
  Future<OrdersByStatus> getSummary(Session session, void range) async {
    final rows = await session.db.unsafeQuery(
      'SELECT status, COUNT(*)::int AS count FROM orders GROUP BY status',
    );
    final counts = {for (final status in OrderStatus.values) status: 0};
    for (final row in rows.map((row) => row.toColumnMap())) {
      counts[OrderStatus.fromJson(row['status'] as String)] =
          row['count'] as int;
    }
    return counts;
  }
}
