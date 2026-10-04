import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/auth/auth_repository.dart';
import 'package:neils/features/admin/admin_shell.dart';
import 'package:neils/features/auth/login_screen.dart';
import 'package:neils/features/catalog/catalog_screen.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';

import '../fakes.dart';
import '../support.dart';

/// Ingreso, registro y salida con la app completa: el router, la sesión real
/// y Firebase y el servidor en memoria.
void main() {
  useBundledFonts();

  late FakeAuthRepository auth;
  late FakeUserRepository users;

  setUp(() {
    auth = FakeAuthRepository();
    users = FakeUserRepository(auth);
  });

  /// Arranca la app, va a [at] y devuelve el router. Con [settle] en false no
  /// espera a que todo se resuelva (para ver los estados de carga).
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String at = '/login',
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userRepositoryProvider.overrideWithValue(users),
        ],
        child: const NeilsApp(),
      ),
    );
    final router = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    ).read(routerProvider);
    router.go(at);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return router;
  }

  String currentPath(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  Finder button(String label) => find.widgetWithText(FilledButton, label);

  Future<void> fillLogin(WidgetTester tester, String email, String password) =>
      tester
          .enterText(field('Correo'), email)
          .then((_) => tester.enterText(field('Contraseña'), password));

  group('ingresar', () {
    testWidgets(
      'un cliente termina en el catálogo, con su nombre en la barra',
      (tester) async {
        auth.addAccount('ana@tienda.pe', 'secreta', name: 'Ana Quispe');
        final router = await pumpApp(tester);

        await fillLogin(tester, 'ana@tienda.pe', 'secreta');
        await tester.tap(button('Ingresar'));
        await tester.pumpAndSettle();

        expect(currentPath(router), '/catalogo');
        expect(find.byType(CatalogScreen), findsOneWidget);
        expect(find.text('Ana'), findsOneWidget);
        expect(find.text('Salir'), findsOneWidget);
        expect(find.text('Panel'), findsNothing);
      },
    );

    testWidgets('admin y staff terminan en el panel', (tester) async {
      final admin = auth.addAccount('jefa@tienda.pe', 'secreta', name: 'Rosa');
      users.roles[admin.uid] = UserRole.admin;
      final router = await pumpApp(tester);

      await fillLogin(tester, 'jefa@tienda.pe', 'secreta');
      await tester.tap(button('Ingresar'));
      await tester.pumpAndSettle();

      expect(currentPath(router), '/admin');
      expect(find.byType(AdminShell), findsOneWidget);
      expect(find.text('Rosa · admin'), findsOneWidget);
    });

    testWidgets('si el panel lo mandó a ingresar, vuelve a esa ruta', (
      tester,
    ) async {
      final staff = auth.addAccount('caja@tienda.pe', 'secreta', name: 'Luis');
      users.roles[staff.uid] = UserRole.staff;
      final router = await pumpApp(tester, at: '/admin?seccion=pedidos');
      expect(currentPath(router), '/login?from=%2Fadmin%3Fseccion%3Dpedidos');

      await fillLogin(tester, 'caja@tienda.pe', 'secreta');
      await tester.tap(button('Ingresar'));
      await tester.pumpAndSettle();

      expect(currentPath(router), '/admin?seccion=pedidos');
    });

    testWidgets('con la contraseña incorrecta muestra el error y se queda', (
      tester,
    ) async {
      auth.addAccount('ana@tienda.pe', 'secreta');
      final router = await pumpApp(tester);

      await fillLogin(tester, 'ana@tienda.pe', 'otra');
      await tester.tap(button('Ingresar'));
      await tester.pumpAndSettle();

      expect(currentPath(router), '/login');
      expect(
        find.text('El correo o la contraseña no son correctos.'),
        findsOneWidget,
      );
    });

    testWidgets('mientras espera, el botón muestra progreso y no se repite', (
      tester,
    ) async {
      auth.addAccount('ana@tienda.pe', 'secreta');
      final router = await pumpApp(tester);
      users.hold = Completer();

      await fillLogin(tester, 'ana@tienda.pe', 'secreta');
      await tester.tap(button('Ingresar'));
      await tester.pump();

      final submit = find.byType(FilledButton);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(
        find.descendant(
          of: submit,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      users.hold!.complete();
      await tester.pumpAndSettle();
      expect(currentPath(router), '/catalogo');
      expect(users.calls, 1);
    });

    testWidgets('si el servidor no responde, lo dice y no deja la sesión '
        'a medias', (tester) async {
      auth.addAccount('ana@tienda.pe', 'secreta');
      users.failure = const AuthFailure(
        'El servidor no está disponible. Intenta más tarde.',
      );
      final router = await pumpApp(tester);

      await fillLogin(tester, 'ana@tienda.pe', 'secreta');
      await tester.tap(button('Ingresar'));
      await tester.pumpAndSettle();

      expect(currentPath(router), '/login');
      expect(find.textContaining('no está disponible'), findsOneWidget);
      expect(auth.current, isNull);
    });

    testWidgets('valida los campos antes de llamar a Firebase', (tester) async {
      await pumpApp(tester);

      await tester.tap(button('Ingresar'));
      await tester.pump();
      expect(find.text('Escribe tu correo.'), findsOneWidget);
      expect(find.text('Escribe tu contraseña.'), findsOneWidget);

      await fillLogin(tester, 'ana@', 'x');
      await tester.tap(button('Ingresar'));
      await tester.pump();
      expect(find.text('Ese correo no es válido.'), findsOneWidget);
      expect(auth.current, isNull);
      expect(users.calls, 0);
    });
  });

  group('registrarse', () {
    testWidgets('crea un cliente con su nombre y termina en el catálogo', (
      tester,
    ) async {
      final router = await pumpApp(tester, at: '/registro');

      await tester.enterText(field('Nombre'), 'Ana Quispe');
      await tester.enterText(field('Correo'), 'ana@tienda.pe');
      await tester.enterText(field('Contraseña'), '123456');
      await tester.tap(button('Crear cuenta'));
      await tester.pumpAndSettle();

      expect(currentPath(router), '/catalogo');
      expect(find.text('Ana'), findsOneWidget);
      expect((await users.me('token-${auth.current}')).name, 'Ana Quispe');
    });

    testWidgets('pide nombre y una contraseña de 6 caracteres', (tester) async {
      await pumpApp(tester, at: '/registro');

      await tester.enterText(field('Correo'), 'ana@tienda.pe');
      await tester.enterText(field('Contraseña'), '12345');
      await tester.tap(button('Crear cuenta'));
      await tester.pump();

      expect(find.text('Escribe tu nombre.'), findsOneWidget);
      expect(find.text('Usa al menos 6 caracteres.'), findsOneWidget);
      expect(auth.current, isNull);
    });

    testWidgets('un correo ya registrado muestra el error', (tester) async {
      auth.addAccount('ana@tienda.pe', 'secreta');
      await pumpApp(tester, at: '/registro');

      await tester.enterText(field('Nombre'), 'Ana');
      await tester.enterText(field('Correo'), 'ana@tienda.pe');
      await tester.enterText(field('Contraseña'), '123456');
      await tester.tap(button('Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ya hay una cuenta'), findsOneWidget);
    });
  });

  group('sesión abierta', () {
    testWidgets('al abrir /admin espera la sesión y después muestra el panel', (
      tester,
    ) async {
      final staff = auth.addAccount(
        'caja@tienda.pe',
        'secreta',
        name: 'Luis',
        signedIn: true,
      );
      users.roles[staff.uid] = UserRole.staff;
      users.hold = Completer();
      final router = await pumpApp(tester, at: '/admin', settle: false);

      expect(currentPath(router), '/admin');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      users.hold!.complete();
      await tester.pumpAndSettle();
      expect(currentPath(router), '/admin');
      expect(find.text('Luis · staff'), findsOneWidget);
    });

    testWidgets('"Salir" en el panel cierra la cuenta y lleva al ingreso', (
      tester,
    ) async {
      final admin = auth.addAccount(
        'jefa@tienda.pe',
        'secreta',
        name: 'Rosa',
        signedIn: true,
      );
      users.roles[admin.uid] = UserRole.admin;
      final router = await pumpApp(tester, at: '/admin');
      expect(find.byType(AdminShell), findsOneWidget);

      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();

      expect(auth.current, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(currentPath(router), '/login?from=%2Fadmin');
    });

    testWidgets('"Salir" en la tienda deja la página y vuelve "Ingresar"', (
      tester,
    ) async {
      auth.addAccount('ana@tienda.pe', 'secreta', name: 'Ana', signedIn: true);
      final router = await pumpApp(tester, at: '/catalogo');
      expect(find.text('Ana'), findsOneWidget);

      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();

      expect(currentPath(router), '/catalogo');
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.text('Ana'), findsNothing);
    });

    testWidgets('staff ve el acceso al panel desde la tienda', (tester) async {
      final staff = auth.addAccount(
        'caja@tienda.pe',
        'secreta',
        name: 'Luis',
        signedIn: true,
      );
      users.roles[staff.uid] = UserRole.staff;
      final router = await pumpApp(tester, at: '/catalogo');

      await tester.tap(find.text('Panel'));
      await tester.pumpAndSettle();

      expect(currentPath(router), '/admin');
    });
  });
}
