import 'package:flutter_test/flutter_test.dart';
import 'package:neils/cart/cart.dart';
import 'package:neils/cart/cart_quote_provider.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/orders/quote.dart';

/// Si la cotización que llegó es la del carrito tal como está, para quien
/// mira ahora.
void main() {
  const rice = Product(
    id: 'arroz',
    name: 'Arroz extra 5 kg',
    priceCents: 2490,
    stock: 40,
  );
  final cart = Cart([const CartLine(rice, 2)]);

  Quote quote({String? owner, int quantity = 2}) => Quote(
    lines: const [],
    subtotalCents: 4980,
    discountCents: 0,
    totalCents: 4980,
    requested: [(productId: 'arroz', quantity: quantity)],
    owner: owner,
  );

  test('la del mismo carrito y la misma cuenta', () {
    final mine = quote(owner: 'ana@tienda.pe');
    expect(quoteFor(cart, mine, owner: 'ana@tienda.pe'), same(mine));
    final anonymous = quote();
    expect(quoteFor(cart, anonymous, owner: null), same(anonymous));
  });

  test('la de otra cuenta (o de antes de ingresar o salir) no sirve', () {
    expect(quoteFor(cart, quote(), owner: 'ana@tienda.pe'), isNull);
    expect(quoteFor(cart, quote(owner: 'ana@tienda.pe'), owner: null), isNull);
    expect(
      quoteFor(cart, quote(owner: 'ana@tienda.pe'), owner: 'luis@tienda.pe'),
      isNull,
    );
  });

  test('la de otras cantidades no sirve', () {
    expect(quoteFor(cart, quote(quantity: 3), owner: null), isNull);
  });
}
