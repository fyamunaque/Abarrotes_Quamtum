import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../report_provider.dart';
import '../reports.dart';

/// Cantidad de pedidos de cada tipo de entrega (a domicilio o recojo en
/// tienda), de cualquier fecha y estado, como "pedidos por estado". Los
/// tipos sin pedidos van en 0.
class FulfillmentReportProvider
    extends ReportProvider<void, OrdersByFulfillment> {
  const FulfillmentReportProvider();

  @override
  Future<OrdersByFulfillment> getSummary(Session session, void range) async {
    final rows = await session.db.unsafeQuery(
      'SELECT "fulfillmentType", COUNT(*)::int AS count FROM orders '
      'GROUP BY "fulfillmentType"',
    );
    final counts = {for (final type in FulfillmentType.values) type: 0};
    for (final row in rows.map((row) => row.toColumnMap())) {
      counts[FulfillmentType.fromJson(row['fulfillmentType'] as String)] =
          row['count'] as int;
    }
    return counts;
  }
}
