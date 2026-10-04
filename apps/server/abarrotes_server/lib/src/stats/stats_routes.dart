import 'package:serverpod/serverpod.dart';

import '../auth/firebase_token_verifier.dart';
import '../auth/role_guard.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/money.dart';
import '../common/store_time.dart';
import '../generated/protocol.dart';
import '../inventory/stock_alerts.dart';
import '../inventory/stock_alerts_json.dart';
import 'day_range.dart';
import 'report_provider.dart';
import 'reports.dart';

/// Estadísticas del dashboard, solo para admin y staff. Las rutas traducen el
/// query a un rango y delegan: los cálculos viven en cada ReportProvider, que
/// llega por separado y como abstracción.
List<RouteEntry> statsRoutes({
  required ReportProvider<void, StatsOverview> overview,
  required ReportProvider<DayRange, SalesReport> sales,
  required ReportProvider<TopProductsRange, TopProductsReport> topProducts,
  required ReportProvider<void, List<Product>> lowStock,
  required ReportProvider<int, ExpiringProducts> expiring,
  required FirebaseTokenVerifier verifier,
  DateTime Function()? now,
}) {
  final clock = now ?? DateTime.now;
  Route staffOnly(ApiHandler handler) =>
      RoleGuard(staffRoles, ApiRoute(Method.get, handler), verifier: verifier);

  /// `?from=&to=` como rango; por defecto, los últimos 30 días.
  DayRange readRange(InputReader query) {
    final from = query.day('from', required: false);
    final to = query.day('to', required: false);
    query.check();
    return resolveDayRange(from: from, to: to, today: storeDay(clock()));
  }

  return [
    (
      '/stats/overview',
      staffOnly((session, request) async {
        InputReader.query(request, allowed: const {}).check();
        final report = await overview.getSummary(session, null);
        return jsonResponse(200, overviewJson(report));
      }),
    ),
    (
      '/stats/sales',
      staffOnly((session, request) async {
        final query = InputReader.query(request, allowed: const {'from', 'to'});
        final report = await sales.getSummary(session, readRange(query));
        return jsonResponse(200, salesReportJson(report));
      }),
    ),
    (
      '/stats/top-products',
      staffOnly((session, request) async {
        final query = InputReader.query(
          request,
          allowed: const {'from', 'to', 'limit'},
        );
        final limit =
            query.integer('limit', min: 1, max: 50, required: false) ?? 5;
        final range = readRange(query);
        final report = await topProducts.getSummary(session, (
          range: range,
          limit: limit,
        ));
        return jsonResponse(200, topProductsJson(report));
      }),
    ),
    (
      '/stats/low-stock',
      staffOnly((session, request) async {
        InputReader.query(request, allowed: const {}).check();
        return jsonResponse(
          200,
          lowStockReportJson(await lowStock.getSummary(session, null)),
        );
      }),
    ),
    (
      '/stats/expiring',
      staffOnly((session, request) async {
        final query = InputReader.query(request, allowed: const {'days'});
        final days =
            query.integer('days', min: 1, max: 365, required: false) ?? 7;
        query.check();
        return jsonResponse(
          200,
          expiringReportJson(await expiring.getSummary(session, days)),
        );
      }),
    ),
  ];
}

/// `SalesSummary` de shared-types: total y ticket promedio como texto.
Map<String, Object?> salesSummaryJson(SalesReport report) => {
  'from': report.range.from,
  'to': report.range.to,
  'total': formatMoney(report.totalCents),
  'orders': report.orders,
  // total / pedidos, redondeado a céntimos; "0" si no hubo pedidos.
  'averageTicket': report.orders > 0
      ? formatMoney((report.totalCents / report.orders).round())
      : '0',
};

/// `SalesReport` de shared-types: el resumen y un punto por día.
Map<String, Object?> salesReportJson(SalesReport report) => {
  ...salesSummaryJson(report),
  'timeZone': storeTimeZone,
  'daily': [
    for (final point in report.daily)
      {
        'date': point.date,
        'total': formatMoney(point.totalCents),
        'orders': point.orders,
      },
  ],
};

/// `StatsOverview` de shared-types, con los estados como en el modelo.
Map<String, Object?> overviewJson(StatsOverview report) => {
  'timeZone': storeTimeZone,
  'generatedAt': report.generatedAt.toUtc().toIso8601String(),
  'today': salesSummaryJson(report.today),
  'week': salesSummaryJson(report.week),
  'month': salesSummaryJson(report.month),
  'ordersByStatus': {
    for (final MapEntry(key: status, value: count)
        in report.ordersByStatus.entries)
      status.name: count,
  },
};

/// `TopProductsReport` de shared-types.
Map<String, Object?> topProductsJson(TopProductsReport report) => {
  'from': report.range.from,
  'to': report.range.to,
  'data': [
    for (final product in report.products)
      {
        'productId': product.productId,
        'name': product.name,
        'sku': product.sku,
        'quantity': product.quantity,
        'revenue': formatMoney(product.revenueCents),
      },
  ],
};
