import '../../common/money.dart';
import '../../orders/fulfillment.dart';
import '../../orders/order_status.dart';

/// Ventas de un periodo: lo cobrado en pedidos completados (entregados a
/// domicilio o recogidos en tienda), cuántos y el ticket promedio. Montos en
/// céntimos.
class SalesSummary {
  const SalesSummary({
    required this.totalCents,
    required this.orders,
    required this.averageTicketCents,
  });

  factory SalesSummary.fromJson(Object? json) => switch (json) {
    {
      'total': final String total,
      'orders': final int orders,
      'averageTicket': final String averageTicket,
    } =>
      SalesSummary(
        totalCents: parseCents(total),
        orders: orders,
        averageTicketCents: parseCents(averageTicket),
      ),
    _ => throw FormatException('No es un resumen de ventas', json),
  };

  final int totalCents;
  final int orders;
  final int averageTicketCents;
}

/// `GET /stats/overview`: ventas de hoy, la semana (desde el lunes) y el mes,
/// y cuántos pedidos hay en cada estado y de cada tipo de entrega.
class StatsOverview {
  const StatsOverview({
    required this.today,
    required this.week,
    required this.month,
    required this.ordersByStatus,
    this.ordersByFulfillment = const {},
  });

  factory StatsOverview.fromJson(Object? json) => switch (json) {
    {
      'today': final Object today,
      'week': final Object week,
      'month': final Object month,
      'ordersByStatus': final Map<String, Object?> byStatus,
    } =>
      StatsOverview(
        today: SalesSummary.fromJson(today),
        week: SalesSummary.fromJson(week),
        month: SalesSummary.fromJson(month),
        ordersByStatus: {
          for (final status in OrderStatus.values)
            status: byStatus[status.name] as int? ?? 0,
        },
        // Sin el campo (un servidor anterior), todos en 0.
        ordersByFulfillment: {
          for (final type in FulfillmentType.values)
            type: switch (json['ordersByFulfillment']) {
              final Map<String, Object?> byType =>
                byType[type.name] as int? ?? 0,
              _ => 0,
            },
        },
      ),
    _ => throw FormatException('No es un resumen del panel', json),
  };

  final SalesSummary today;
  final SalesSummary week;
  final SalesSummary month;
  final Map<OrderStatus, int> ordersByStatus;

  /// Cuántos pedidos hay de cada tipo de entrega, de cualquier fecha.
  final Map<FulfillmentType, int> ordersByFulfillment;
}

/// Las ventas de un día (`AAAA-MM-DD`, hora de Lima).
class DailySales {
  const DailySales({
    required this.date,
    required this.totalCents,
    required this.orders,
  });

  factory DailySales.fromJson(Object? json) => switch (json) {
    {
      'date': final String date,
      'total': final String total,
      'orders': final int orders,
    } =>
      DailySales(date: date, totalCents: parseCents(total), orders: orders),
    _ => throw FormatException('No es un día de ventas', json),
  };

  final String date;
  final int totalCents;
  final int orders;
}

/// `GET /stats/sales`: el resumen y un punto por día, también los días sin
/// ventas (en 0).
class SalesReport {
  const SalesReport({required this.summary, required this.daily});

  factory SalesReport.fromJson(Object? json) => switch (json) {
    {'daily': final List<Object?> daily} => SalesReport(
      summary: SalesSummary.fromJson(json),
      daily: [for (final day in daily) DailySales.fromJson(day)],
    ),
    _ => throw FormatException('No es un reporte de ventas', json),
  };

  final SalesSummary summary;
  final List<DailySales> daily;
}

/// Uno de los más vendidos (por unidades).
class TopProduct {
  const TopProduct({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.revenueCents,
  });

  factory TopProduct.fromJson(Object? json) => switch (json) {
    {
      'productId': final String productId,
      'name': final String name,
      'quantity': final int quantity,
      'revenue': final String revenue,
    } =>
      TopProduct(
        productId: productId,
        name: name,
        quantity: quantity,
        revenueCents: parseCents(revenue),
      ),
    _ => throw FormatException('No es un producto del top', json),
  };

  final String productId;
  final String name;
  final int quantity;
  final int revenueCents;
}

/// Un producto activo con el stock en su mínimo o por debajo.
class LowStockItem {
  const LowStockItem({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.minStock,
    required this.shortage,
  });

  factory LowStockItem.fromJson(Object? json) => switch (json) {
    {
      'id': final String id,
      'name': final String name,
      'currentStock': final int currentStock,
      'minStock': final int minStock,
      'shortage': final int shortage,
    } =>
      LowStockItem(
        id: id,
        name: name,
        currentStock: currentStock,
        minStock: minStock,
        shortage: shortage,
      ),
    _ => throw FormatException('No es una alerta de stock', json),
  };

  final String id;
  final String name;
  final int currentStock;
  final int minStock;

  /// Lo que falta para llegar al mínimo.
  final int shortage;
}

/// Un producto con stock que vence pronto (o ya venció).
class ExpiringItem {
  const ExpiringItem({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.expirationDate,
    required this.daysLeft,
  });

  factory ExpiringItem.fromJson(Object? json) => switch (json) {
    {
      'id': final String id,
      'name': final String name,
      'currentStock': final int currentStock,
      'expirationDate': final String expirationDate,
      'daysLeft': final int daysLeft,
    } =>
      ExpiringItem(
        id: id,
        name: name,
        currentStock: currentStock,
        expirationDate: expirationDate,
        daysLeft: daysLeft,
      ),
    _ => throw FormatException('No es una alerta de vencimiento', json),
  };

  final String id;
  final String name;
  final int currentStock;

  /// `AAAA-MM-DD`.
  final String expirationDate;

  /// 0 si vence hoy; negativo si ya venció.
  final int daysLeft;
}
