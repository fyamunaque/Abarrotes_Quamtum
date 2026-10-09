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

  double scale(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byType(CartButton),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;

  testWidgets('al agregar, el contador sube y el carrito rebota', (
    tester,
  ) async {
    await pumpButton(tester);
    expect(find.byTooltip('Carrito'), findsOneWidget);

    container.read(cartProvider.notifier).add(rice, 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byTooltip('Carrito: 2'), findsOneWidget);
    expect(scale(tester), greaterThan(1));

    await tester.pumpAndSettle();
    expect(scale(tester), 1);
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

  testWidgets('con "reducir animaciones" no rebota', (tester) async {
    await pumpButton(tester, reduceMotion: true);

    container.read(cartProvider.notifier).add(rice);
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(scale(tester), 1);
    expect(find.byTooltip('Carrito: 1'), findsOneWidget);
  });
}
