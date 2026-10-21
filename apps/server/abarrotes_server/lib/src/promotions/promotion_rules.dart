import 'package:serverpod/serverpod.dart';

import '../common/store_time.dart';
import '../generated/protocol.dart';

/// Reglas de las promociones: la definición de "vigente" vive solo aquí.
/// products y orders la usan a través de `PromotionPricing`, que además
/// filtra por la audiencia del cliente.
///
/// Fechas: la API recibe y devuelve días de la tienda (hora de Lima), ambos
/// incluidos. Se guardan como instantes: startDate = 00:00 del primer día y
/// endDate = 00:00 del día siguiente al último (límite exclusivo). Así
/// "vigente" es start <= ahora < end.

/// Se deduce de la fecha y del interruptor `active`; no se guarda.
enum PromotionStatus { scheduled, active, expired, disabled }

/// Promociones encendidas cuyo periodo incluye [now].
Expression activePromotionWhere(PromotionTable promotion, DateTime now) =>
    promotion.active.equals(true) &
    (promotion.startDate <= now) &
    (promotion.endDate > now);

PromotionStatus promotionStatus(Promotion promotion, DateTime now) {
  if (!promotion.active) return PromotionStatus.disabled;
  if (now.isBefore(promotion.startDate)) return PromotionStatus.scheduled;
  if (!now.isBefore(promotion.endDate)) return PromotionStatus.expired;
  return PromotionStatus.active;
}

/// Filtro para listar las promociones que hoy tienen [status].
Expression promotionStatusWhere(
  PromotionTable promotion,
  PromotionStatus status,
  DateTime now,
) => switch (status) {
  PromotionStatus.disabled => promotion.active.equals(false),
  PromotionStatus.scheduled =>
    promotion.active.equals(true) & (promotion.startDate > now),
  PromotionStatus.expired =>
    promotion.active.equals(true) & (promotion.endDate <= now),
  PromotionStatus.active => activePromotionWhere(promotion, now),
};

/// Días de la tienda (ambos incluidos) → instantes que se guardan.
({DateTime startDate, DateTime endDate}) toStoredPeriod(
  String startDay,
  String endDay,
) => (
  startDate: storeDayStart(startDay),
  endDate: storeDayStart(addDays(endDay, 1)),
);

/// Instantes guardados → días de la tienda (ambos incluidos).
({String startDate, String endDate}) toDayPeriod(
  DateTime startDate,
  DateTime endDate,
) => (startDate: storeDay(startDate), endDate: addDays(storeDay(endDate), -1));
