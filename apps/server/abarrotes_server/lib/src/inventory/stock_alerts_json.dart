import '../common/store_time.dart';
import '../generated/protocol.dart';
import 'stock_alerts.dart';

/// Los reportes de alertas tal como los devuelve la API (`LowStockReport` y
/// `ExpiringProductsReport` de packages/shared-types). Los usan
/// /inventory/alerts/* y /stats/*: el mismo reporte, el mismo JSON.

/// `{data}` con lo que falta para llegar al mínimo de cada producto.
Map<String, Object?> lowStockReportJson(List<Product> products) => {
  'data': [
    for (final product in products)
      {
        'id': product.id.toString(),
        'name': product.name,
        'sku': product.sku,
        'category': product.category!.name,
        'currentStock': product.currentStock,
        'minStock': product.minStock,
        'shortage': StockAlerts.shortage(product),
      },
  ],
};

/// `{days, until, data}` con los días que le quedan a cada producto (0 vence
/// hoy; negativo, ya venció).
Map<String, Object?> expiringReportJson(ExpiringProducts report) => {
  'days': report.days,
  'until': report.until,
  'data': [
    for (final product in report.products)
      {
        'id': product.id.toString(),
        'name': product.name,
        'sku': product.sku,
        'currentStock': product.currentStock,
        'expirationDate': calendarDay(product.expirationDate!),
        'daysLeft': daysBetween(
          report.today,
          calendarDay(product.expirationDate!),
        ),
      },
  ],
};
