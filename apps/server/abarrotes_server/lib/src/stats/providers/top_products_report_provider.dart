import 'package:serverpod/serverpod.dart';

import '../day_range.dart';
import '../report_provider.dart';
import '../reports.dart';

/// Productos más vendidos por unidades en los pedidos aceptados del rango.
class TopProductsReportProvider
    extends ReportProvider<TopProductsRange, TopProductsReport> {
  const TopProductsReportProvider();

  @override
  Future<TopProductsReport> getSummary(
    Session session,
    TopProductsRange range,
  ) async {
    final bounds = utcBounds(range.range);
    // A igual cantidad, primero el que más facturó; después, por nombre.
    final rows = await session.db.unsafeQuery(
      '''
      SELECT p.id::text AS "productId",
             p.name,
             p.sku,
             SUM(oi.quantity)::bigint AS quantity,
             SUM(oi.quantity * oi."unitPriceCents")::bigint AS revenue
      FROM order_items oi
      JOIN orders o ON o.id = oi."orderId"
      JOIN products p ON p.id = oi."productId"
      WHERE o.status = ANY(@statuses::text[])
        AND o."createdAt" >= @start::timestamp
        AND o."createdAt" < @end::timestamp
      GROUP BY p.id, p.name, p.sku
      ORDER BY SUM(oi.quantity) DESC,
               SUM(oi.quantity * oi."unitPriceCents") DESC,
               p.name
      LIMIT @limit
      ''',
      parameters: QueryParameters.named({
        'statuses': [for (final status in saleStatuses) status.name],
        'start': bounds.start,
        'end': bounds.end,
        'limit': range.limit,
      }),
    );

    return (
      range: range.range,
      products: [
        for (final row in rows.map((row) => row.toColumnMap()))
          (
            productId: row['productId'] as String,
            name: row['name'] as String,
            sku: row['sku'] as String,
            quantity: row['quantity'] as int,
            revenueCents: row['revenue'] as int,
          ),
      ],
    );
  }
}
