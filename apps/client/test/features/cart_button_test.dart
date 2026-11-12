import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/features/shared/cart_button.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

import '../fakes.dart';
import '../support.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpButton(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        // El carrito mira la sesión (los precios VIP).
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
        ],
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const MaterialApp(
            home: Scaffold(body: Center(child: CartButton())),
          ),
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(CartButton)),
    );
  }

  /// Las escalas que hay dentro del botón (ninguna, si no rebota).
  Iterable<double> scales(WidgetTester tester) => tester
      .widgetList<ScaleTransition>(
        find.descendant(
          of: find.byType(CartButton),
          matching: find.byType(ScaleTransition),
        ),
      )
      .map((t) => t.scale.value);

  Iterable<double> fades(WidgetTester tester) => tester
      .widgetList<FadeTransition>(
        find.descendant(
          of: find.byType(CartButton),
          matching: find.byType(FadeTransition),
        ),
      )
      .map((t) => t.opacity.value);

  testWidgets('el número del carrito cambia con un fundido, sin rebote', (
    tester,
  ) async {
    await pumpButton(tester);
    container.read(cartProvider.notifier).add(rice);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Carrito: 1'), findsOneWidget);

    container.read(cartProvider.notifier).add(rice, 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byTooltip('Carrito: 3'), findsOneWidget);
    expect(scales(tester).where((s) => s > 1), isEmpty);
    // A mitad del fundido: el número nuevo entra y el de antes sale.
    expect(fades(tester).where((o) => o > 0 && o < 1), isNotEmpty);

    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('al quitar no rebota', (tester) async {
    await pumpButton(tester);
    container.read(cartProvider.notifier).add(rice, 2);
    await tester.pumpAndSettle();

    container.read(cartProvider.notifier).remove(rice.id);
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byTooltip('Carrito'), findsOneWidget);
  });

  testWidgets('con reducir animaciones, el número cambia en el acto', (
    tester,
  ) async {
    await pumpButton(tester, reduceMotion: true);
    container.read(cartProvider.notifier).add(rice);
    await tester.pumpAndSettle();

    container.read(cartProvider.notifier).add(rice);
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.byTooltip('Carrito: 2'), findsOneWidget);
  });
}
