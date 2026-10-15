import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/auth/login_screen.dart';
import 'package:neils/features/orders/order_tracker.dart';
import 'package:neils/orders/fulfillment.dart';
import 'package:neils/orders/order.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/orders/orders_providers.dart';
import 'package:neils/router/router.dart';
import 'package:neils/store/store_providers.dart';

import '../fakes.dart';
import '../support.dart';

/// Del carrito al pedido, con la sesión real y Firebase, el catálogo y los
/// pedidos en memoria.
void main() {
  useBundledFonts();

  late FakeAuthRepository auth;
  late FakeCatalogRepository catalog;
  late FakeOrderRepository orders;
  late FakeStoreRepository store;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository()
      ..addAccount('ana@tienda.pe', 'secreta', name: 'Ana Quispe');
    catalog = FakeCatalogRepository();
    orders = FakeOrderRepository(catalog);
    store = FakeStoreRepository();
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
          storeRepositoryProvider.overrideWithValue(store),
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

  testWidgets(
    'el carrito muestra un total estimado; el aviso, lo que cobró la tienda',
    (tester) async {
      auth = FakeAuthRepository()
        ..addAccount('ana@tienda.pe', 'secreta', signedIn: true);
      await pumpApp(tester, '/carrito');
      // Se agregó cuando el arroz tenía una promoción que ya terminó.
      container
          .read(cartProvider.notifier)
          .add(
            const Product(
              id: 'arroz',
              name: 'Arroz extra 5 kg',
              priceCents: 2490,
              promoPriceCents: 1990,
              stock: 40,
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text('Total estimado'), findsOneWidget);
      expect(find.text(formatSoles(1990)), findsWidgets);
      expect(
        find.text('El precio final lo confirma la tienda al hacer el pedido.'),
        findsOneWidget,
      );

      await confirm(tester, 'Av. Arequipa 123');

      expect(orders.orders.single.totalCents, 2490);
      expect(find.text('Total: ${formatSoles(2490)}'), findsOneWidget);
      expect(
        find.text('Algunos precios cambiaron desde que los agregaste:'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Arroz extra 5 kg: ${formatSoles(1990)} → ${formatSoles(2490)}',
        ),
        findsOneWidget,
      );
    },
  );

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

  group('recoger en tienda', () {
    setUp(() {
      auth = FakeAuthRepository()
        ..addAccount('ana@tienda.pe', 'secreta', signedIn: true);
    });

    Future<void> choosePickup(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Recoger en tienda'));
      await tester.tap(find.text('Recoger en tienda'));
      await tester.pumpAndSettle();
    }

    testWidgets('oculta la dirección, muestra la tienda y pide sin ella', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/carrito');
      container.read(cartProvider.notifier).add(rice);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Dirección de entrega'),
        findsOneWidget,
      );

      await choosePickup(tester);

      expect(
        find.widgetWithText(TextFormField, 'Dirección de entrega'),
        findsNothing,
      );
      expect(
        find.text("Recoges tu pedido en Neil's Food Services"),
        findsOneWidget,
      );
      for (final text in [
        'Av. Arequipa 1234, Lince',
        'Frente al parque',
        'Lun a sáb de 8 a 20 h',
        'Muestra tu código en caja.',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }

      await tester.ensureVisible(find.text('Confirmar pedido'));
      await tester.tap(find.text('Confirmar pedido'));
      await tester.pumpAndSettle();

      expect(orders.deliveries.single, (FulfillmentType.pickup, null));
      expect(location(router), startsWith('/mis-pedidos?nuevo='));
      // Pendiente: el código llega cuando la tienda lo confirma.
      expect(find.text('K7M2XQ'), findsNothing);
      expect(
        find.text(
          'Te damos tu código de recojo cuando la tienda confirme el pedido.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('si no cargan los datos de la tienda, se puede reintentar', (
      tester,
    ) async {
      store.failure = const ApiFailure('Sin conexión');
      await pumpApp(tester, '/carrito');
      container.read(cartProvider.notifier).add(rice);
      await tester.pumpAndSettle();
      await choosePickup(tester);

      expect(
        find.text('No se pudieron cargar los datos de la tienda.'),
        findsOneWidget,
      );
      store.failure = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Av. Arequipa 1234, Lince'), findsOneWidget);
    });

    Order pickupOrder(OrderStatus status) => Order(
      id: 'pedido-1',
      status: status,
      fulfillmentType: FulfillmentType.pickup,
      pickupCode: 'K7M2XQ',
      totalCents: 2490,
      createdAt: DateTime.utc(2026, 10, 14, 15),
      lines: const [],
    );

    testWidgets('confirmado: el código en grande, con la tienda', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      orders.orders.add(pickupOrder(OrderStatus.preparing));

      await pumpApp(tester, '/mis-pedidos');

      expect(find.text('Tu código de recojo'), findsOneWidget);
      expect(find.text('K7M2XQ'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Tu código de recojo: K 7 M 2 X Q'),
        findsOneWidget,
      );
      expect(find.text('Av. Arequipa 1234, Lince'), findsOneWidget);
      expect(find.text('Lun a sáb de 8 a 20 h'), findsOneWidget);
      expect(find.textContaining('Entrega en'), findsNothing);
      expect(find.text('¡Tu pedido está listo para recoger!'), findsNothing);
      final tracker = tester.widget<OrderTracker>(find.byType(OrderTracker));
      expect(tracker.fulfillmentType, FulfillmentType.pickup);
      expect(find.text('Preparando'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('en espera de recojo: el aviso destacado', (tester) async {
      orders.orders.add(pickupOrder(OrderStatus.readyForPickup));

      await pumpApp(tester, '/mis-pedidos');

      expect(find.text('¡Tu pedido está listo para recoger!'), findsOneWidget);
      expect(find.text('K7M2XQ'), findsOneWidget);
    });

    testWidgets('ya recogido: sin el código', (tester) async {
      orders.orders.add(pickupOrder(OrderStatus.delivered));

      await pumpApp(tester, '/mis-pedidos');

      expect(find.text('K7M2XQ'), findsNothing);
      expect(find.text('Recojo en tienda'), findsOneWidget);
      expect(find.text('Recogido'), findsOneWidget);
    });
  });

  testWidgets('"Actualizar" trae el estado nuevo y el seguimiento lo anima', (
    tester,
  ) async {
    auth = FakeAuthRepository()
      ..addAccount('ana@tienda.pe', 'secreta', signedIn: true);
    await orders.place(
      't',
      deliveryAddress: 'Av. Arequipa 123',
      lines: [(productId: 'arroz', quantity: 1, shownUnitPriceCents: null)],
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
