import 'package:serverpod/serverpod.dart';

import '../common/store_time.dart';
import '../generated/protocol.dart';

/// Alertas de stock. Es el único lugar del servidor que sabe qué es "stock
/// bajo" o "por vencer": las rutas de inventory lo usan, y stats lo
/// reutilizará.
class StockAlerts {
  StockAlerts({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// Productos activos con currentStock <= minStock, los más críticos
  /// primero: los que tienen menos stock en proporción a su mínimo (agotados
  /// antes que casi en el mínimo), después los que más unidades necesitan.
  Future<List<Product>> lowStock(Session session) async {
    final products = await Product.db.find(
      session,
      where: (product) =>
          product.active.equals(true) &
          (product.currentStock <= product.minStock),
      include: Product.include(category: Category.include()),
    );
    return products..sort(_byUrgency);
  }

  /// Unidades que faltan para llegar al mínimo (0 si está justo en el mínimo).
  static int shortage(Product product) =>
      product.minStock - product.currentStock;

  /// Productos activos con stock que vencen de hoy (hora de Lima) a hoy +
  /// [days], incluidos los ya vencidos que siguen en el inventario: son los
  /// más urgentes. Los primeros en vencer, primero.
  Future<({String today, String until, List<Product> products})> expiring(
    Session session,
    int days,
  ) async {
    final today = storeDay(_now());
    final until = addDays(today, days);
    final products = await Product.db.find(
      session,
      where: (product) =>
          product.active.equals(true) &
          (product.currentStock > 0) &
          // Hasta `until` incluido. Sin fecha de vencimiento, no entra.
          (product.expirationDate < utcMidnight(addDays(until, 1))),
      orderByList: (product) => [
        product.expirationDate.asc(),
        product.name.asc(),
      ],
    );
    return (today: today, until: until, products: products);
  }

  /// Menor proporción de stock primero; con la misma proporción, el que más
  /// unidades necesita; después, por nombre.
  static int _byUrgency(Product a, Product b) {
    final byRatio = _stockRatio(a).compareTo(_stockRatio(b));
    if (byRatio != 0) return byRatio;
    final byShortage = shortage(b).compareTo(shortage(a));
    if (byShortage != 0) return byShortage;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  /// Qué fracción del mínimo queda: 0 si está agotado o si el mínimo es 0.
  static double _stockRatio(Product product) =>
      product.minStock > 0 ? product.currentStock / product.minStock : 0;
}
