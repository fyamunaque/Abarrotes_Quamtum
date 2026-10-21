import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/cart/cart.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/cart/cart_storage.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

import '../support.dart';

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
  late TestSession session;

  setUp(() {
    session = TestSession(const SignedOut());
    container = ProviderContainer.test(
      overrides: [sessionProvider.overrideWith(() => session)],
    );
    cart = container.read(cartProvider.notifier);
  });

  List<(String, int)> lines() => [
    for (final line in container.read(cartProvider).lines)
      (line.product.id, line.quantity),
  ];

  group('precios VIP', () {
    const vipOil = Product(
      id: 'aceite',
      name: 'Aceite',
      priceCents: 1090,
      promoPriceCents: 790,
      vipPrice: true,
      stock: 3,
    );
    final vip = SignedIn(
      signedInAs(UserRole.customer).user.copyWith(isVip: true),
    );

    ProviderContainer start(Session initial, {Cart saved = const Cart()}) {
      session = TestSession(initial);
      return ProviderContainer.test(
        overrides: [
          sessionProvider.overrideWith(() => session),
          cartStorageProvider.overrideWithValue(MemoryCartStorage(saved)),
        ],
      );
    }

    int priceOf(ProviderContainer container) =>
        container.read(cartProvider).lines.single.product.finalPriceCents;

    test('un VIP los ve; si deja de serlo, vuelven al precio normal', () {
      final container = start(vip);
      container.read(cartProvider.notifier).add(vipOil);
      expect(priceOf(container), 790);

      session.set(SignedIn(vip.user.copyWith(isVip: false)));

      expect(priceOf(container), 1090);
      expect(
        container.read(cartProvider).lines.single.product.vipPrice,
        isFalse,
      );
    });

    test('al cerrar sesión también', () {
      final container = start(vip);
      container.read(cartProvider.notifier).add(vipOil, 2);

      session.set(const SignedOut());

      expect(priceOf(container), 1090);
      expect(container.read(cartProvider).count, 2);
    });

    test('un carrito guardado con precios VIP, abierto sin cuenta VIP', () {
      final container = start(
        const SignedOut(),
        saved: const Cart([CartLine(vipOil, 1)]),
      );

      expect(priceOf(container), 1090);
    });

    test('mientras la sesión carga no toca nada', () {
      final container = start(
        const SessionLoading(),
        saved: const Cart([CartLine(vipOil, 1)]),
      );
      expect(priceOf(container), 790);

      session.set(vip);
      expect(priceOf(container), 790);
    });
  });

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
