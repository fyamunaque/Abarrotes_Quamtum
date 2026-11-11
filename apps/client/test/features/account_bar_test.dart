import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/features/admin/admin_shell.dart';
import 'package:neils/features/shared/brand.dart';
import 'package:neils/features/shared/store_search_field.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/brand_colors.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

/// La barra de la tienda y la del panel: con staff, un nombre largo y todos
/// los botones, tienen que entrar sin desbordarse.
void main() {
  useBundledFonts();

  const staff = SignedIn(
    SessionUser(
      id: 'u-1',
      name: 'Alejandra Quispe',
      email: 'alejandra@tienda.pe',
      role: UserRole.staff,
    ),
  );

  Future<void> pumpAt(WidgetTester tester, double width, Widget screen) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => TestSession(staff))],
        child: MaterialApp(theme: neilsTheme(), home: screen),
      ),
    );
    await tester.pump();
  }

  /// La tienda con un router: la portada y el catálogo.
  Future<GoRouter> pumpStore(
    WidgetTester tester, {
    double width = 1280,
    Session session = staff,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const PublicScaffold(child: Text('portada')),
        ),
        GoRoute(
          path: '/catalogo',
          builder: (_, _) => const PublicScaffold(child: Text('catálogo')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => TestSession(session))],
        child: MaterialApp.router(theme: neilsTheme(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  for (final width in [320.0, 375.0, 600.0]) {
    testWidgets('a $width px la barra pública entra: menú, logo y carrito', (
      tester,
    ) async {
      await pumpAt(tester, width, const PublicScaffold(child: Text('x')));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Menú'), findsOneWidget);
      expect(find.byType(NeilsLogo), findsOneWidget);
      expect(find.byTooltip('Carrito'), findsOneWidget);
      // La cuenta va en el menú.
      expect(find.text('Salir'), findsNothing);
    });

    testWidgets('a $width px la barra del panel entra', (tester) async {
      await pumpAt(
        tester,
        width,
        const AdminShell(location: '/admin', child: Text('x')),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Tu cuenta'));
      await tester.pumpAndSettle();

      // Ya está en el panel: el menú no lo ofrece.
      expect(find.text('Panel'), findsNothing);
      expect(find.text('Salir'), findsOneWidget);
    });
  }

  for (final width in [840.0, 1024.0]) {
    testWidgets('a $width px, las secciones y la cuenta en su menú', (
      tester,
    ) async {
      await pumpAt(tester, width, const PublicScaffold(child: Text('x')));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Menú'), findsNothing);
      for (final section in ['Inicio', 'Catálogo', 'Promociones']) {
        expect(find.text(section), findsOneWidget);
      }
      expect(find.byTooltip('Carrito'), findsOneWidget);
      expect(find.text('Salir'), findsNothing);

      await tester.tap(find.byTooltip('Tu cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsOneWidget);
      expect(find.text('Salir'), findsOneWidget);
    });
  }

  testWidgets('a 1280 px, las secciones, el nombre y los botones', (
    tester,
  ) async {
    await pumpAt(tester, 1280, const PublicScaffold(child: Text('x')));

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Menú'), findsNothing);
    expect(find.byTooltip('Tu cuenta'), findsNothing);
    for (final section in ['Inicio', 'Catálogo', 'Promociones']) {
      expect(find.text(section), findsOneWidget);
    }
    expect(find.byTooltip('Carrito'), findsOneWidget);
    expect(find.text('Mis pedidos'), findsOneWidget);
    expect(find.text('Alejandra'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Salir'), findsOneWidget);
  });

  testWidgets('en la portada, Inicio va en rojo', (tester) async {
    await pumpStore(tester);

    Color? colorOf(String section) =>
        tester.widget<Text>(find.text(section)).style?.color;
    expect(colorOf('Inicio'), NeilsColors.primary);
    expect(colorOf('Catálogo'), isNot(NeilsColors.primary));
  });

  testWidgets('el buscador de la barra lleva al catálogo con lo buscado', (
    tester,
  ) async {
    final router = await pumpStore(tester);

    await tester.enterText(find.byType(StoreSearchField), 'arroz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/catalogo?q=arroz',
    );
  });

  testWidgets('sin cuenta, en escritorio dice Ingresar', (tester) async {
    await pumpStore(tester, session: const SignedOut());

    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Mis pedidos'), findsNothing);
  });
}
