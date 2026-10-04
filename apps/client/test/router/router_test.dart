import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/features/admin/admin_shell.dart';
import 'package:neils/features/auth/login_screen.dart';
import 'package:neils/features/catalog/catalog_screen.dart';
import 'package:neils/features/catalog/product_card.dart';
import 'package:neils/features/home/home_screen.dart';
import 'package:neils/features/orders/order_tracker.dart';
import 'package:neils/features/shared/not_found_screen.dart';
import 'package:neils/features/showcase/showcase_screen.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  late TestSession session;

  /// Arranca la app con [initial] como sesión y devuelve su router.
  Future<GoRouter> pumpApp(WidgetTester tester, Session initial) async {
    useWideScreen(tester);
    session = TestSession(initial);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => session)],
        child: const NeilsApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    );
    return container.read(routerProvider);
  }

  Future<void> goTo(WidgetTester tester, GoRouter router, String path) async {
    router.go(path);
    await tester.pumpAndSettle();
  }

  String currentPath(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('arranca en el inicio y navega por el flujo público', (
    tester,
  ) async {
    final router = await pumpApp(tester, const SignedOut());
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Ver el catálogo'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogScreen), findsOneWidget);
    expect(currentPath(router), '/catalogo');
  });

  testWidgets('/admin sin sesión lleva al ingreso', (tester) async {
    final router = await pumpApp(tester, const SignedOut());

    await goTo(tester, router, '/admin');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(currentPath(router), '/login?from=%2Fadmin');
  });

  testWidgets('/admin con una cuenta de cliente vuelve al inicio', (
    tester,
  ) async {
    final router = await pumpApp(tester, signedInAs(UserRole.customer));

    await goTo(tester, router, '/admin');

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AdminShell), findsNothing);
  });

  testWidgets('staff entra al panel y ve su primer nombre y su rol', (
    tester,
  ) async {
    final router = await pumpApp(tester, signedInAs(UserRole.staff));

    await goTo(tester, router, '/admin');

    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.text('Ana · staff'), findsOneWidget);
  });

  testWidgets('si la sesión se cierra dentro del panel, sale de /admin', (
    tester,
  ) async {
    final router = await pumpApp(tester, signedInAs(UserRole.admin));
    await goTo(tester, router, '/admin');
    expect(find.byType(AdminShell), findsOneWidget);

    session.set(const SignedOut());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(currentPath(router), '/login?from=%2Fadmin');
  });

  testWidgets('la vitrina existe en debug', (tester) async {
    final router = await pumpApp(tester, const SignedOut());

    await goTo(tester, router, '/vitrina');

    expect(find.byType(ShowcaseScreen), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(4));
    expect(find.byType(OrderTracker), findsOneWidget);
  });

  testWidgets('una ruta inexistente muestra "No encontramos esta página"', (
    tester,
  ) async {
    final router = await pumpApp(tester, const SignedOut());

    await goTo(tester, router, '/no-existe');

    expect(find.byType(NotFoundScreen), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Ir al inicio'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
