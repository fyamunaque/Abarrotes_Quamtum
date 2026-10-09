import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/features/admin/admin_shell.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/brand_colors.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  Future<GoRouter> pumpPanel(
    WidgetTester tester, {
    double width = 1280,
    String at = '/admin/productos',
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(
            () => TestSession(signedInAs(UserRole.staff)),
          ),
        ],
        child: const NeilsApp(),
      ),
    );
    final router = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    ).read(routerProvider)..go(at);
    await tester.pumpAndSettle();
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  test('cada ruta marca su sección', () {
    expect(AdminSection.of('/admin'), AdminSection.home);
    expect(AdminSection.of('/admin/pedidos'), AdminSection.orders);
    expect(AdminSection.of('/admin/promociones/x'), AdminSection.promotions);
    expect(AdminSection.of('/admin/clientes-vip'), AdminSection.vip);
  });

  testWidgets('en escritorio, un riel a la izquierda con la sección marcada', (
    tester,
  ) async {
    final router = await pumpPanel(tester);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, AdminSection.products.index);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Pedidos'));
    await tester.pumpAndSettle();
    expect(location(router), '/admin/pedidos');
  });

  testWidgets('en el teléfono, una barra abajo', (tester) async {
    final router = await pumpPanel(tester, width: 375);

    expect(find.byType(NavigationRail), findsNothing);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AdminSection.products.index);

    await tester.tap(find.byIcon(Icons.sell_outlined));
    await tester.pumpAndSettle();
    expect(location(router), '/admin/promociones');
  });

  testWidgets('el panel usa la paleta calmada: lo elegido en naranja claro', (
    tester,
  ) async {
    await pumpPanel(tester);

    final theme = Theme.of(tester.element(find.byType(NavigationRail)));
    expect(theme.navigationRailTheme.indicatorColor, NeilsColors.primaryTint);
    expect(theme.chipTheme.selectedColor, NeilsColors.primaryTint);
    expect(theme.cardTheme.elevation, 0);
  });

  for (final width in [320.0, 375.0, 840.0, 1280.0]) {
    testWidgets('a $width px entra sin desbordarse', (tester) async {
      for (final section in AdminSection.values) {
        await pumpPanel(tester, width: width, at: section.path);
        expect(tester.takeException(), isNull, reason: section.path);
      }
    });
  }
}
