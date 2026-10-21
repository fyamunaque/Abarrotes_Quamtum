import 'package:serverpod/serverpod.dart';

import '../common/shopper.dart';
import '../generated/protocol.dart';

/// Lo que products y orders necesitan de las promociones: cuáles puede usar
/// un cliente y cuál le conviene. La implementa `PromotionsService`; ellos la
/// reciben por constructor y no saben de audiencias.
abstract interface class PromotionPricing {
  /// Las promociones vigentes en [now] que [shopper] puede usar.
  Expression eligibleWhere(
    PromotionTable promotion,
    DateTime now,
    Shopper shopper,
  );

  /// Para el `include` de un producto: la mejor (la más barata) de esas
  /// promociones, o ninguna.
  PromotionIncludeList bestFor(DateTime now, Shopper shopper);
}
