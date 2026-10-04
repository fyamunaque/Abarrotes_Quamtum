import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

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
