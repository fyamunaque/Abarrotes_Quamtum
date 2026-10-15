import '../generated/protocol.dart';
import 'report_provider.dart';

/// Los datos de cada reporte. Los montos van en céntimos; las rutas los
/// pasan al JSON que lee el panel (ver stats_routes.dart).

/// Ventas de un día.
typedef SalesPoint = ({String date, int totalCents, int orders});

/// Ventas de un rango: totales y un punto por día, también los días sin
/// ventas.
typedef SalesReport = ({
  DayRange range,
  int totalCents,
  int orders,
  List<SalesPoint> daily,
});

/// Cantidad de pedidos en cada estado; los estados sin pedidos van en 0.
typedef OrdersByStatus = Map<OrderStatus, int>;

/// Cantidad de pedidos de cada tipo de entrega; los tipos sin pedidos van
/// en 0.
typedef OrdersByFulfillment = Map<FulfillmentType, int>;

/// Resumen del dashboard.
typedef StatsOverview = ({
  DateTime generatedAt,
  SalesReport today,
  SalesReport week,
  SalesReport month,
  OrdersByStatus ordersByStatus,
  OrdersByFulfillment ordersByFulfillment,
});

typedef TopProductsRange = ({DayRange range, int limit});

typedef TopProduct = ({
  String productId,
  String name,
  String sku,
  int quantity,
  int revenueCents,
});

typedef TopProductsReport = ({DayRange range, List<TopProduct> products});
