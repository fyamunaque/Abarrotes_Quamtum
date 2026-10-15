import '../common/http_json.dart';
import '../common/store_time.dart';
import '../generated/protocol.dart';
import 'report_provider.dart';

/// Pedidos que cuentan como venta: los completados, es decir entregados a
/// domicilio o recogidos en tienda (`delivered` en los dos flujos). Un
/// pedido en camino o en espera todavía puede cancelarse.
const saleStatuses = [OrderStatus.delivered];

const defaultRangeDays = 30;
const maxRangeDays = 366;

/// Rango de un query `?from=&to=`: sin `to`, hasta hoy; sin `from`, los 30
/// días que terminan en `to`. Rechaza rangos invertidos o de más de un año.
DayRange resolveDayRange({
  String? from,
  String? to,
  required String today,
}) {
  final end = to ?? today;
  final start = from ?? addDays(end, -(defaultRangeDays - 1));
  final days = daysBetween(start, end) + 1;
  if (days < 1) {
    throw const ApiException.badRequest('from no puede ser posterior a to');
  }
  if (days > maxRangeDays) {
    throw const ApiException.badRequest(
      'El rango no puede superar $maxRangeDays días',
    );
  }
  return (from: start, to: end);
}

/// Límites del rango para comparar con `createdAt` en SQL: [inicio de
/// `from`, inicio del día siguiente a `to`) en la hora de la tienda. Van como
/// texto sin zona horaria, para compararlos con la columna `timestamp` (UTC)
/// sin que intervenga la zona horaria de la sesión de PostgreSQL.
({String start, String end}) utcBounds(DayRange range) {
  String sql(DateTime instant) =>
      instant.toUtc().toIso8601String().replaceAll('Z', '');
  return (
    start: sql(storeDayStart(range.from)),
    end: sql(storeDayStart(addDays(range.to, 1))),
  );
}
