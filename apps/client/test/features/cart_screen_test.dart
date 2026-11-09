import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/cart/cart_quote_provider.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/catalog/line_total_pill.dart';
import 'package:neils/orders/order.dart';
import 'package:neils/orders/order_repository.dart';
import 'package:neils/orders/orders_providers.dart';
import 'package:neils/orders/quote.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

import '../fakes.dart' show FakeCatalogRepository, FakeOrderRepository;
import '../support.dart';

void main() {
  useBundledFonts();

  const rice = Product(
    id: 'arroz',
    name: 'Arroz extra 5 kg',
    priceCents: 2490,
    stock: 40,
  );
  const oil = Product(
    id: 'aceite',
    name: 'Aceite vegetal 1 L',
    priceCents: 1090,
    promoPriceCents: 890,
    stock: 3,
  );

  late ProviderContainer container;
  late FakeOrderRepository orders;

  setUp(() => orders = FakeOrderRepository(FakeCatalogRepository()));

  /// La app en /carrito, con [lines] ya en el carrito.
  Future<GoRouter> pumpCart(
    WidgetTester tester, [
    List<(Product, int)> lines = const [],
  ]) async {
    useWideScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
          orderRepositoryProvider.overrideWithValue(orders),
        ],
        child: const NeilsApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    );
    for (final (product, quantity) in lines) {
      container.read(cartProvider.notifier).add(product, quantity);
    }
    final router = container.read(routerProvider)..go('/carrito');
    await tester.pumpAndSettle();
    return router;
  }

  Finder lineOf(String name) => find.ancestor(
    of: find.text(name),
    matching: find.byWidgetPredicate(
      (widget) => widget.key is ValueKey<String>,
    ),
  );

  Future<void> tapIn(
    WidgetTester tester,
    String product,
    String tooltip,
  ) async {
    await tester.tap(
      find.descendant(of: lineOf(product), matching: find.byTooltip(tooltip)),
    );
    await tester.pumpAndSettle();
  }

  group('la cotización', () {
    /// Dos arroces con su 2x1 y, si [gift], una sal de regalo.
    Quote riceTwoForOne(
      List<QuoteLineRequest> lines, {
      bool gift = false,
      List<String> notices = const [],
    }) => Quote(
      lines: [
        OrderLine(
          productId: 'arroz',
          name: 'Arroz extra 5 kg',
          quantity: lines.single.quantity,
          listUnitPriceCents: 2490,
          unitPriceCents: 2490,
          lineTotalCents: 2490,
          promotions: const [(label: '2x1', savedCents: 2490)],
        ),
        if (gift)
          const OrderLine(
            productId: 'sal',
            name: 'Sal 1 kg',
            quantity: 1,
            listUnitPriceCents: 150,
            unitPriceCents: 0,
            lineTotalCents: 0,
            isGift: true,
            promotions: [(label: 'Regalo: Sal 1 kg', savedCents: 150)],
          ),
      ],
      subtotalCents: 4980,
      discountCents: 2490,
      totalCents: 2490,
      notices: notices,
    );

    /// Lo que tarda en pedirse la cotización después del último cambio.
    Future<void> waitForQuote(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    testWidgets('el carrito muestra el 2x1 y el total cotizado', (
      tester,
    ) async {
      orders.quoteWith = riceTwoForOne;
      await pumpCart(tester, [(rice, 2)]);
      await waitForQuote(tester);

      expect(find.text('2x1 −${formatSoles(2490)}'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text(formatSoles(4980)), findsOneWidget);
      expect(find.text('Descuentos'), findsOneWidget);
      expect(find.text('−${formatSoles(2490)}'), findsOneWidget);
      // La línea y el total.
      expect(find.text(formatSoles(2490)), findsNWidgets(2));
    });

    testWidgets('el regalo aparece como línea', (tester) async {
      orders.quoteWith = (lines) => riceTwoForOne(lines, gift: true);
      await pumpCart(tester, [(rice, 2)]);
      await waitForQuote(tester);

      expect(find.text('1 × Sal 1 kg'), findsOneWidget);
      expect(find.text('Regalo'), findsOneWidget);
    });

    testWidgets('el regalo va con su etiqueta y S/ 0.00', (tester) async {
      orders.quoteWith = (lines) => riceTwoForOne(lines, gift: true);
      await pumpCart(tester, [(rice, 2)]);
      await waitForQuote(tester);

      final gift = find.ancestor(
        of: find.text('1 × Sal 1 kg'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: gift, matching: find.text('Regalo')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.descendant(of: gift, matching: find.byType(LineTotalPill)),
          matching: find.text(formatSoles(0)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('el aviso de regalo sin stock', (tester) async {
      orders.quoteWith = (lines) => riceTwoForOne(
        lines,
        notices: ['Sal 1 kg ya no está disponible para regalo'],
      );
      await pumpCart(tester, [(rice, 2)]);
      await waitForQuote(tester);

      expect(
        find.text('Sal 1 kg ya no está disponible para regalo'),
        findsOneWidget,
      );
    });

    testWidgets('si la cotización falla, la estimación con aviso', (
      tester,
    ) async {
      orders.quoteFailure = const ApiFailure('No se pudo');
      await pumpCart(tester, [(rice, 2)]);
      await waitForQuote(tester);

      expect(
        find.text(
          'No pudimos calcular las promociones. El total final se confirma '
          'al pedir.',
        ),
        findsOneWidget,
      );
      // La línea y el total, con los precios de hoy.
      expect(find.text(formatSoles(4980)), findsNWidgets(2));
      expect(find.text('Descuentos'), findsNothing);
    });

    testWidgets('la línea del código y el aviso de compra mínima', (
      tester,
    ) async {
      orders.quoteWith = (lines) => Quote(
        lines: [
          OrderLine(
            productId: 'arroz',
            name: 'Arroz extra 5 kg',
            quantity: lines.single.quantity,
            listUnitPriceCents: 2490,
            unitPriceCents: 2490,
            lineTotalCents: 2490,
            promotions: const [
              (label: 'Código VERANO-10: 2x1', savedCents: 2490),
            ],
          ),
        ],
        subtotalCents: 4980,
        discountCents: 2490,
        totalCents: 2490,
        notices: ['Con ${formatSoles(1240)} más se aplica tu código OTONO'],
      );
      await pumpCart(tester, [(rice, 2)]);
      await waitForQuote(tester);

      expect(
        find.text('Código VERANO-10: 2x1 −${formatSoles(2490)}'),
        findsOneWidget,
      );
      expect(
        find.text('Con ${formatSoles(1240)} más se aplica tu código OTONO'),
        findsOneWidget,
      );
      expect(find.text('¿Tienes un código?'), findsOneWidget);
    });

    testWidgets('un producto que ya no está: su aviso y lo demás cotizado', (
      tester,
    ) async {
      // El servidor deja afuera el aceite y lo avisa.
      orders.quoteWith = (lines) => Quote(
        lines: [
          OrderLine(
            productId: 'arroz',
            name: 'Arroz extra 5 kg',
            quantity: lines.first.quantity,
            listUnitPriceCents: 2490,
            unitPriceCents: 2490,
            lineTotalCents: 2490,
            promotions: const [(label: '2x1', savedCents: 2490)],
          ),
        ],
        subtotalCents: 4980,
        discountCents: 2490,
        totalCents: 2490,
        notices: const ['Ya no está disponible: Aceite vegetal 1 L'],
      );
      await pumpCart(tester, [(rice, 2), (oil, 1)]);
      await waitForQuote(tester);

      expect(
        find.text('Ya no está disponible: Aceite vegetal 1 L'),
        findsOneWidget,
      );
      expect(find.text('2x1 −${formatSoles(2490)}'), findsOneWidget);
      expect(find.text('Descuentos'), findsOneWidget);
    });

    testWidgets('si falla después de una buena, no queda la anterior', (
      tester,
    ) async {
      orders.quoteWith = riceTwoForOne;
      await pumpCart(tester, [(rice, 2)]);
      await waitForQuote(tester);
      expect(find.text('Descuentos'), findsOneWidget);

      // Se vuelve a pedir con el mismo carrito (p. ej. al activar un
      // código) y esta vez falla.
      orders.quoteFailure = const ApiFailure('No se pudo');
      container.invalidate(cartQuoteProvider);
      await waitForQuote(tester);

      expect(
        find.text(
          'No pudimos calcular las promociones. El total final se confirma '
          'al pedir.',
        ),
        findsOneWidget,
      );
      expect(find.text('Descuentos'), findsNothing);
      expect(find.text(formatSoles(4980)), findsNWidgets(2));
    });

    testWidgets('cambiar la cantidad vuelve a cotizar', (tester) async {
      await pumpCart(tester, [(rice, 1)]);
      await waitForQuote(tester);
      expect(orders.quotes, hasLength(1));

      final add = find.descendant(
        of: lineOf('Arroz extra 5 kg'),
        matching: find.byTooltip('Agregar uno'),
      );
      await tester.tap(add);
      await tester.pump();
      await tester.tap(add);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 390));
      expect(orders.quotes, hasLength(1));

      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      // Una sola, con la cantidad del final.
      expect(orders.quotes, hasLength(2));
      expect(orders.quotes.last.$1.single.quantity, 3);
    });
  });

  testWidgets('vacío: lo dice y lleva al catálogo', (tester) async {
    final router = await pumpCart(tester);

    expect(find.text('Tu carrito está vacío.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Ver el catálogo'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/catalogo');
  });

  testWidgets('muestra cada línea con su precio de hoy y el total', (
    tester,
  ) async {
    await pumpCart(tester, [(rice, 2), (oil, 1)]);

    expect(find.text('S/ 24.90 c/u'), findsOneWidget);
    expect(find.text('S/ 8.90 c/u'), findsOneWidget);
    expect(find.text('S/ 49.80'), findsOneWidget);
    expect(find.text('S/ 58.70'), findsOneWidget);
    expect(find.byTooltip('Carrito: 3'), findsOneWidget);
  });

  testWidgets(
    'cada línea muestra el código, la pastilla con su total y Quitar',
    (tester) async {
      const ham = Product(
        id: 'jamonada',
        sku: '3580',
        name: 'Jamonada especial',
        priceCents: 440,
        stock: 20,
      );
      await pumpCart(tester, [(ham, 3)]);

      final line = lineOf('3580 – Jamonada especial');
      expect(line, findsOneWidget);
      expect(
        find.descendant(
          of: find.descendant(of: line, matching: find.byType(LineTotalPill)),
          matching: find.text(formatSoles(1320)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: line,
          matching: find.byTooltip('Quitar del carrito'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('− y + cambian la cantidad dentro de los límites', (
    tester,
  ) async {
    await pumpCart(tester, [(oil, 1)]);
    IconButton button(String tooltip) => tester.widget<IconButton>(
      find.descendant(
        of: lineOf('Aceite vegetal 1 L'),
        matching: find.widgetWithIcon(
          IconButton,
          tooltip == 'Agregar uno' ? Icons.add : Icons.remove,
        ),
      ),
    );

    expect(button('Quitar uno').onPressed, isNull);
    await tapIn(tester, 'Aceite vegetal 1 L', 'Agregar uno');
    await tapIn(tester, 'Aceite vegetal 1 L', 'Agregar uno');

    // El aceite tiene 3 en stock: no se puede pedir más.
    expect(container.read(cartProvider).quantityOf('aceite'), 3);
    expect(button('Agregar uno').onPressed, isNull);
    expect(find.text('S/ 26.70'), findsNWidgets(2)); // línea y total

    await tapIn(tester, 'Aceite vegetal 1 L', 'Quitar uno');
    expect(container.read(cartProvider).quantityOf('aceite'), 2);
  });

  testWidgets('quitar una línea; sin líneas, el carrito queda vacío', (
    tester,
  ) async {
    await pumpCart(tester, [(rice, 1), (oil, 1)]);

    await tapIn(tester, 'Arroz extra 5 kg', 'Quitar del carrito');
    expect(find.text('Arroz extra 5 kg'), findsNothing);
    expect(find.text('S/ 8.90'), findsNWidgets(2));

    await tapIn(tester, 'Aceite vegetal 1 L', 'Quitar del carrito');
    expect(find.text('Tu carrito está vacío.'), findsOneWidget);
    expect(find.byTooltip('Carrito'), findsOneWidget);
  });
}
