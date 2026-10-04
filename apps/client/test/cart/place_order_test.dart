import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/orders/orders_providers.dart';

import '../fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeCatalogRepository catalog;
  late FakeOrderRepository orders;
  late ProviderContainer container;
  late CartNotifier cart;

  setUp(() {
    auth = FakeAuthRepository()
      ..addAccount('ana@tienda.pe', 'secreta', signedIn: true);
    catalog = FakeCatalogRepository();
    orders = FakeOrderRepository(catalog);
    container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(FakeUserRepository(auth)),
        catalogRepositoryProvider.overrideWithValue(catalog),
        orderRepositoryProvider.overrideWithValue(orders),
      ],
    );
    cart = container.read(cartProvider.notifier);
  });

  test('hace el pedido con el token, vacía el carrito y lo devuelve', () async {
    cart
      ..add(rice, 2)
      ..add(oil);

    final order = await cart.placeOrder(deliveryAddress: 'Av. Arequipa 123');

    expect(order.status, OrderStatus.pendingConfirmation);
    expect(order.deliveryAddress, 'Av. Arequipa 123');
    expect(order.totalCents, 2 * 2490 + 890);
    expect(orders.tokens, ['token-${auth.current}']);
    expect(container.read(cartProvider).isEmpty, isTrue);
  });

  test('si el servidor lo rechaza, el carrito queda igual', () async {
    cart.add(oil, 3);
    orders.failure = const ApiFailure(
      'Stock insuficiente: Aceite vegetal 1 L tiene 2 unidades',
      status: 409,
    );

    await expectLater(
      cart.placeOrder(deliveryAddress: 'Av. Arequipa 123'),
      throwsA(isA<ApiFailure>()),
    );
    expect(container.read(cartProvider).quantityOf('aceite'), 3);
  });

  test('con el carrito vacío no llama al servidor', () async {
    await expectLater(
      cart.placeOrder(deliveryAddress: 'Av. Arequipa 123'),
      throwsA(isA<ApiFailure>()),
    );
    expect(orders.tokens, isEmpty);
  });

  test('después de pedir, "Mis pedidos" se vuelve a cargar', () async {
    container.listen(myOrdersProvider, (_, _) {});
    await flushEvents();
    expect((await container.read(myOrdersProvider.future)).items, isEmpty);

    cart.add(rice);
    final order = await cart.placeOrder(deliveryAddress: 'Av. Arequipa 123');

    final mine = await container.read(myOrdersProvider.future);
    expect([for (final o in mine.items) o.id], [order.id]);
  });
}
