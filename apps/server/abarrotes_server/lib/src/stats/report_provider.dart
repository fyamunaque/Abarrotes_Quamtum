import 'package:serverpod/serverpod.dart';

/// Estrategia de reporte. Cada tipo de reporte es una clase independiente que
/// solo sabe calcular el suyo (ver providers/). Las rutas y los reportes
/// compuestos (overview) dependen de esta abstracción y reciben cada
/// implementación por constructor: cambiar cómo se calcula un reporte no toca
/// a quien lo usa.
abstract class ReportProvider<TRange, TData> {
  const ReportProvider();

  Future<TData> getSummary(Session session, TRange range);
}

/// Rango de días de calendario de la tienda, ambos incluidos: "2026-10-01".
typedef DayRange = ({String from, String to});
