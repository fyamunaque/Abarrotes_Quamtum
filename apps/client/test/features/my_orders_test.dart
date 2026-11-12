import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/app.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/features/orders/order_tracker.dart';
import 'package:neils/orders/fulfillment.dart';
import 'package:neils/orders/order.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/orders/orders_providers.dart';
import 'package:neils/router/router.dart';
import 'package:neils/router/routes.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/store/store_providers.dart';
import 'package:neils/theme/palette.dart';

import '../fakes.dart';
import '../support.dart';

/// Mis pedidos: desde 1100 px, la lista a la izquierda y el pedido elegido a
/// la derecha; más angosto, los pedidos uno debajo del otro.
void main() {
  useBundledFonts();

  final inProgress = Order(
    id: 'pedido-1',
    number: 1024,
    status: OrderStatus.outForDelivery,
    fulfillmentType: FulfillmentType.delivery,
    deliveryAddress: 'Av. Arequipa 5904, Lince',
    deliveryCode: 'K7M2XQ',
    totalCents: 2490,
    createdAt: DateTime.utc(2026, 11, 5, 15),
    lines: const [],
  );
  final delivered = Order(
    id: 'pedido-2',
    number: 1023,
    status: OrderStatus.delivered,
    fulfillmentType: FulfillmentType.delivery,
    deliveryAddress: 'Av. Arequipa 5904, Lince',
    totalCents: 1320,
    createdAt: DateTime.utc(2026, 11, 2, 15),
    lines: const [],
  );

  Future<void> pumpOrders(WidgetTester tester, {required double width}) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final catalog = FakeCatalogRepository();
    final orders = FakeOrderRepository(catalog)
      ..orders.addAll([inProgress, delivered]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(
            () => TestSession(signedInAs(UserRole.customer)),
          ),
          // El token de la cuenta abierta, para pedir sus pedidos.
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository()
              ..addAccount('ana@tienda.pe', 'secreta', signedIn: true),
          ),
          catalogRepositoryProvider.overrideWithValue(catalog),
          orderRepositoryProvider.overrideWithValue(orders),
          storeRepositoryProvider.overrideWithValue(FakeStoreRepository()),
        ],
        child: const NeilsApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(NeilsApp)))
        .read(routerProvider)
        .go(Routes.myOrders);
    await tester.pumpAndSettle();
  }

  final list = find.byKey(const ValueKey('lista-de-pedidos'));
  final chosen = find.byKey(const ValueKey('pedido-elegido'));

  testWidgets('desde 1100 px, la lista y el pedido elegido lado a lado', (
    tester,
  ) async {
    await pumpOrders(tester, width: 1280);

    // La lista con los dos; a la derecha, el primero con su seguimiento.
    for (final title in ['Pedido N.º 1024', 'Pedido N.º 1023']) {
      expect(
        find.descendant(of: list, matching: find.text(title)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: chosen, matching: find.text('Pedido N.º 1024')),
      findsOneWidget,
    );
    expect(find.byType(OrderTracker), findsOneWidget);
    expect(
      tester.getRect(chosen).left,
      greaterThan(tester.getRect(list).right),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar otro pedido lo muestra a la derecha', (tester) async {
    await pumpOrders(tester, width: 1280);

    await tester.tap(
      find.descendant(of: list, matching: find.text('Pedido N.º 1023')),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: chosen, matching: find.text('Pedido N.º 1023')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chosen, matching: find.text('Pedido N.º 1024')),
      findsNothing,
    );
  });

  testWidgets('en el teléfono sigue la lista', (tester) async {
    await pumpOrders(tester, width: 390);

    expect(list, findsNothing);
    expect(chosen, findsNothing);
    expect(find.text('Pedido N.º 1024'), findsOneWidget);
    expect(find.text('Pedido N.º 1023', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el código de entrega va sobre el panel cálido', (tester) async {
    await pumpOrders(tester, width: 390);

    final box = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('K7M2XQ'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (box.decoration as BoxDecoration).color,
      NeilsPalette.light.surfaceAlt,
    );
  });
}
