import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/features/auth/login_screen.dart';
import 'package:neils/features/orders/order_tracker.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/orders/orders_providers.dart';
import 'package:neils/router/router.dart';

import '../fakes.dart';
import '../support.dart';

/// Del carrito al pedido, con la sesión real y Firebase, el catálogo y los
/// pedidos en memoria.
void main() {
  useBundledFonts();

  late FakeAuthRepository auth;
  late FakeCatalogRepository catalog;
  late FakeOrderRepository orders;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository()
      ..addAccount('ana@tienda.pe', 'secreta', name: 'Ana Quispe');
    catalog = FakeCatalogRepository();
    orders = FakeOrderRepository(catalog);
  });

  Future<GoRouter> pumpApp(
    WidgetTester tester,
    String at, {
    Map<String, String> addresses = const {},
  }) async {
    useWideScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userRepositoryProvider.overrideWithValue(
            FakeUserRepository(auth)..addresses.addAll(addresses),
          ),
          catalogRepositoryProvider.overrideWithValue(catalog),
          orderRepositoryProvider.overrideWithValue(orders),
        ],
        child: const NeilsApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    );
    final router = container.read(routerProvider)..go(at);
    await tester.pumpAndSettle();
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'ana@tienda.pe',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'secreta',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester, String address) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dirección de entrega'),
      address,
    );
    await tester.ensureVisible(find.text('Confirmar pedido'));
    await tester.tap(find.text('Confirmar pedido'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin cuenta: ingresar, volver al carrito y hacer el pedido', (
    tester,
  ) async {
    final router = await pumpApp(tester, '/carrito');
    container.read(cartProvider.notifier)
      ..add(rice, 2)
      ..add(oil);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ingresar para confirmar'));
    await tester.pumpAndSettle();
    expect(location(router), '/login?from=%2Fcarrito');
    expect(find.byType(LoginScreen), findsOneWidget);

    await signIn(tester);
    expect(location(router), '/carrito');
    expect(container.read(cartProvider).count, 3);

    await confirm(tester, 'Av. Arequipa 123, Lince');

    final order = orders.orders.single;
    expect(location(router), '/mis-pedidos?nuevo=${order.id}');
    expect(order.deliveryAddress, 'Av. Arequipa 123, Lince');
    expect(order.totalCents, 2 * 2490 + 890);
    expect(
      find.text('Recibimos tu pedido. La tienda lo va a confirmar.'),
      findsOneWidget,
    );
    expect(find.text('S/ 58.70'), findsOneWidget);
    expect(find.text('2 × Arroz extra 5 kg'), findsOneWidget);
    expect(
      tester.widget<OrderTracker>(find.byType(OrderTracker)).status,
      OrderStatus.pendingConfirmation,
    );
    expect(container.read(cartProvider).isEmpty, isTrue);
    expect(find.byTooltip('Carrito'), findsOneWidget);
  });

  testWidgets('propone la dirección del perfil', (tester) async {
    auth = FakeAuthRepository();
    final ana = auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
    await pumpApp(
      tester,
      '/carrito',
      addresses: {ana.uid: 'Jr. Cusco 456, Breña'},
    );
    container.read(cartProvider.notifier).add(rice);
    await tester.pumpAndSettle();

    expect(find.text('Jr. Cusco 456, Breña'), findsOneWidget);
  });

  testWidgets('pide la dirección antes de llamar al servidor', (tester) async {
    auth = FakeAuthRepository()
      ..addAccount('ana@tienda.pe', 'secreta', signedIn: true);
    await pumpApp(tester, '/carrito');
    container.read(cartProvider.notifier).add(rice);
    await tester.pumpAndSettle();

    await confirm(tester, '   ');

    expect(find.text('Escribe a dónde llevamos el pedido.'), findsOneWidget);
    expect(orders.tokens, isEmpty);
  });

  testWidgets('si no hay stock, lo dice y el carrito sigue igual', (
    tester,
  ) async {
    auth = FakeAuthRepository()
      ..addAccount('ana@tienda.pe', 'secreta', signedIn: true);
    orders.failure = const ApiFailure(
      'Stock insuficiente: Aceite vegetal 1 L tiene 2 unidades',
      status: 409,
    );
    final router = await pumpApp(tester, '/carrito');
    container.read(cartProvider.notifier).add(oil, 3);
    await tester.pumpAndSettle();

    await confirm(tester, 'Av. Arequipa 123');

    expect(location(router), '/carrito');
    expect(
      find.text('Stock insuficiente: Aceite vegetal 1 L tiene 2 unidades'),
      findsOneWidget,
    );
    expect(container.read(cartProvider).quantityOf('aceite'), 3);
  });

  testWidgets('/mis-pedidos sin cuenta lleva al ingreso y vuelve', (
    tester,
  ) async {
    final router = await pumpApp(tester, '/mis-pedidos');
    expect(location(router), '/login?from=%2Fmis-pedidos');

    await signIn(tester);

    expect(location(router), '/mis-pedidos');
    expect(find.text('Todavía no hiciste pedidos.'), findsOneWidget);
  });

  testWidgets('"Actualizar" trae el estado nuevo y el seguimiento lo anima', (
    tester,
  ) async {
    auth = FakeAuthRepository()
      ..addAccount('ana@tienda.pe', 'secreta', signedIn: true);
    await orders.place(
      't',
      deliveryAddress: 'Av. Arequipa 123',
      lines: [(productId: 'arroz', quantity: 1)],
    );
    await pumpApp(tester, '/mis-pedidos');
    OrderTracker tracker() =>
        tester.widget<OrderTracker>(find.byType(OrderTracker));
    expect(tracker().status, OrderStatus.pendingConfirmation);

    orders.setStatus('pedido-1', OrderStatus.confirmed);
    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pump();
    await tester.pump();

    expect(tracker().status, OrderStatus.confirmed);
    // La misma tarjeta, con el estado nuevo: la línea se está llenando.
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });
}
