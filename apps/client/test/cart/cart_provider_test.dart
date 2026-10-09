import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/catalog/product.dart';

void main() {
  const rice = Product(id: 'arroz', name: 'Arroz', priceCents: 2490, stock: 40);
  const oil = Product(
    id: 'aceite',
    name: 'Aceite',
    priceCents: 1090,
    promoPriceCents: 890,
    stock: 3,
  );

  late ProviderContainer container;
  late CartNotifier cart;

  setUp(() {
    container = ProviderContainer.test();
    cart = container.read(cartProvider.notifier);
  });

  List<(String, int)> lines() => [
    for (final line in container.read(cartProvider).lines)
      (line.product.id, line.quantity),
  ];

  test('empieza vacío', () {
    final empty = container.read(cartProvider);
    expect(empty.isEmpty, isTrue);
    expect(empty.count, 0);
    expect(empty.totalCents, 0);
  });

  test('agrega y suma si el producto ya estaba, en orden de llegada', () {
    cart.add(rice);
    cart.add(oil, 2);
    cart.add(rice, 2);

    expect(lines(), [('arroz', 3), ('aceite', 2)]);
    expect(container.read(cartProvider).count, 5);
  });

  test('el total usa el precio de hoy: el de la promoción si la hay', () {
    cart.add(rice, 2);
    cart.add(oil, 1);

    expect(container.read(cartProvider).totalCents, 2 * 2490 + 890);
  });

  test('no pasa del stock ni de 999', () {
    expect(cart.add(oil, 5), 3);
    expect(cart.add(oil), 3);

    cart.add(
      const Product(id: 'agua', name: 'Agua', priceCents: 350, stock: 5000),
      1200,
    );
    expect(lines(), [('aceite', 3), ('agua', 999)]);
  });

  test('un producto sin stock no entra', () {
    expect(
      cart.add(const Product(id: 'x', name: 'X', priceCents: 1, stock: 0)),
      0,
    );
    expect(container.read(cartProvider).isEmpty, isTrue);
  });

  test('cambiar la cantidad la deja entre 1 y el máximo', () {
    cart.add(oil);

    cart.setQuantity('aceite', 2);
    expect(lines(), [('aceite', 2)]);
    cart.setQuantity('aceite', 0);
    expect(lines(), [('aceite', 1)]);
    cart.setQuantity('aceite', 9);
    expect(lines(), [('aceite', 3)]);
    cart.setQuantity('no-esta', 2);
    expect(lines(), [('aceite', 3)]);
  });

  test('quitar y vaciar', () {
    cart.add(rice);
    cart.add(oil);

    cart.remove('arroz');
    expect(lines(), [('aceite', 1)]);
    cart.clear();
    expect(container.read(cartProvider).isEmpty, isTrue);
  });
}
