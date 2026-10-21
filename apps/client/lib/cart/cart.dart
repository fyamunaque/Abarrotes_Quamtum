import '../catalog/product.dart';

/// Una línea del carrito: el producto tal como estaba al agregarlo, y cuántos.
class CartLine {
  const CartLine(this.product, this.quantity);

  final Product product;
  final int quantity;

  int get totalCents => product.finalPriceCents * quantity;
}

/// El carrito: una línea por producto, en el orden en que se agregaron.
///
/// Los precios son los del catálogo al agregar (para un VIP, los VIP): el
/// total es una estimación. El servidor cobra los de ese momento al hacer el
/// pedido y avisa si alguno cambió.
class Cart {
  const Cart([this.lines = const []]);

  final List<CartLine> lines;

  bool get isEmpty => lines.isEmpty;

  /// Unidades en total (el número del ícono de la barra).
  int get count => lines.fold(0, (sum, line) => sum + line.quantity);

  int get totalCents => lines.fold(0, (sum, line) => sum + line.totalCents);

  CartLine? lineOf(String productId) =>
      lines.where((line) => line.product.id == productId).firstOrNull;

  int quantityOf(String productId) => lineOf(productId)?.quantity ?? 0;
}
