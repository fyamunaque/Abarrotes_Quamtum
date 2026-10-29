import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/legal/legal_texts.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';

import '../fakes.dart';
import '../support.dart';

/// "Mi cuenta": el celular, el DNI y los términos, y el ingreso de una cuenta
/// incompleta, que pasa por aquí.
void main() {
  useBundledFonts();

  late FakeAuthRepository auth;
  late FakeUserRepository users;

  setUp(() {
    auth = FakeAuthRepository();
    users = FakeUserRepository(auth);
  });

  Future<GoRouter> pumpApp(WidgetTester tester, String at) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    ).read(routerProvider)..go(at);
    await tester.pumpAndSettle();
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(field('Correo'), 'ana@tienda.pe');
    await tester.enterText(field('Contraseña'), 'secreta');
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();
  }

  testWidgets('una cuenta de antes, sin celular ni términos, los completa al '
      'ingresar y sigue a donde iba', (tester) async {
    final ana = auth.addAccount('ana@tienda.pe', 'secreta', name: 'Ana');
    users.profiles[ana.uid] = const FakeProfile();
    final router = await pumpApp(tester, '/login');

    await signIn(tester);
    expect(location(router), '/mi-cuenta?from=%2Fcatalogo');
    expect(find.textContaining('Para hacer pedidos, completa'), findsOneWidget);

    await save(tester);
    expect(find.text('Escribe tu celular.'), findsOneWidget);
    expect(find.textContaining('Para continuar, acepta'), findsOneWidget);

    await tester.enterText(field('Celular'), '987654321');
    await tester.tap(find.byType(Checkbox));
    await save(tester);

    expect(location(router), '/catalogo');
    expect(users.profileUpdates.single, (
      phone: '987654321',
      dni: null,
      clearDni: false,
      acceptTerms: true,
    ));
    expect(users.profileOf(ana.uid).isComplete, isTrue);
  });

  testWidgets('el personal con la cuenta incompleta va al panel', (
    tester,
  ) async {
    final rosa = auth.addAccount('ana@tienda.pe', 'secreta', name: 'Rosa');
    users
      ..roles[rosa.uid] = UserRole.admin
      ..profiles[rosa.uid] = const FakeProfile();
    final router = await pumpApp(tester, '/login');

    await signIn(tester);
    expect(location(router), '/admin');
  });

  testWidgets('una cuenta completa: sus datos, cambia el DNI y lo borra', (
    tester,
  ) async {
    final ana = auth.addAccount(
      'ana@tienda.pe',
      'secreta',
      name: 'Ana Quispe',
      signedIn: true,
    );
    users.profiles[ana.uid] = FakeProfile(
      phone: '987654321',
      dni: '45678912',
      termsVersion: termsVersion,
      termsAcceptedAt: DateTime.utc(2026, 10, 28, 15),
    );
    final router = await pumpApp(tester, '/mi-cuenta');

    expect(find.text('Ana Quispe'), findsWidgets);
    expect(find.text('ana@tienda.pe'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(field('Celular')).controller!.text,
      '987654321',
    );
    expect(find.textContaining('Aceptaste los términos'), findsOneWidget);
    // Los términos ya están aceptados: sin la casilla.
    expect(find.byType(Checkbox), findsNothing);

    await tester.enterText(field('DNI (opcional)'), '');
    await save(tester);

    expect(location(router), '/mi-cuenta');
    expect(find.text('Guardamos tus datos.'), findsOneWidget);
    expect(users.profileUpdates.single.clearDni, isTrue);
    expect(users.profileOf(ana.uid).dni, isNull);
  });

  testWidgets('un DNI de otra cuenta: el error en su campo', (tester) async {
    auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
    users.takenDnis.add('45678912');
    await pumpApp(tester, '/mi-cuenta');

    await tester.enterText(field('DNI (opcional)'), '45678912');
    await save(tester);

    expect(
      find.text('Ese DNI ya está registrado en otra cuenta.'),
      findsOneWidget,
    );
  });

  testWidgets('from de afuera de la app no se sigue', (tester) async {
    auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
    final router = await pumpApp(
      tester,
      '/mi-cuenta?from=https://otro.sitio/robar',
    );

    await save(tester);

    expect(router.routerDelegate.currentConfiguration.uri.path, '/mi-cuenta');
    expect(find.text('Guardamos tus datos.'), findsOneWidget);
  });

  testWidgets('sin sesión, lleva al ingreso', (tester) async {
    final router = await pumpApp(tester, '/mi-cuenta');
    expect(location(router), '/login?from=%2Fmi-cuenta');
  });
}
