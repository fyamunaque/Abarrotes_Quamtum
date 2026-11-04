import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/legal/legal_texts.dart';
import 'package:neils/promo_codes/my_promo_code.dart';
import 'package:neils/promo_codes/my_promo_codes_providers.dart';
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
  late FakeMyPromoCodesRepository codes;

  setUp(() {
    auth = FakeAuthRepository();
    users = FakeUserRepository(auth);
    codes = FakeMyPromoCodesRepository(available: {'VERANO-10': summerCode});
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
          myPromoCodesRepositoryProvider.overrideWithValue(codes),
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

  group('Mis códigos', () {
    Finder codeField() => find.widgetWithText(TextField, 'Escribe tu código');

    Future<void> activate(WidgetTester tester, String code) async {
      await tester.enterText(codeField(), code);
      await tester.ensureVisible(find.text('Activar'));
      await tester.tap(find.text('Activar'));
      await tester.pumpAndSettle();
    }

    testWidgets('activar un código lo agrega a la lista', (tester) async {
      auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
      await pumpApp(tester, '/mi-cuenta');
      expect(find.text('Todavía no activaste ningún código.'), findsOneWidget);

      await activate(tester, 'verano-10');

      expect(codes.redeemed, ['VERANO-10']);
      expect(find.text('VERANO-10'), findsOneWidget);
      expect(find.text('2x1 en Arroz extra 5 kg'), findsOneWidget);
      expect(find.text('Te quedan 2 usos'), findsOneWidget);
      expect(find.textContaining('Vence el 30 nov'), findsOneWidget);
      expect(find.text('Activaste el código VERANO-10.'), findsOneWidget);
    });

    testWidgets('el error del servidor queda en el campo', (tester) async {
      auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
      await pumpApp(tester, '/mi-cuenta');

      await activate(tester, 'NO-EXISTE');

      expect(
        find.text('El código no existe o ya no está vigente'),
        findsOneWidget,
      );
      expect(find.text('Todavía no activaste ningún código.'), findsOneWidget);
      // Al escribir otro, el error se va.
      await tester.enterText(codeField(), 'VERANO');
      await tester.pump();
      expect(
        find.text('El código no existe o ya no está vigente'),
        findsNothing,
      );
    });

    testWidgets('al volver a Mi cuenta, la lista está al día', (tester) async {
      auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
      codes.codes.add(summerCode);
      final router = await pumpApp(tester, '/mi-cuenta');
      expect(find.text('VERANO-10'), findsOneWidget);

      // Un pedido gastó su último uso: el servidor ya no lo trae.
      router.go('/catalogo');
      await tester.pumpAndSettle();
      codes.codes.clear();
      router.go('/mi-cuenta');
      await tester.pumpAndSettle();

      expect(find.text('VERANO-10'), findsNothing);
      expect(find.text('Todavía no activaste ningún código.'), findsOneWidget);
    });

    testWidgets('sin límite de usos y con compra mínima', (tester) async {
      auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
      codes.codes.add(
        MyPromoCode(
          code: 'CLIENTES-TOP',
          expiresAt: DateTime.utc(2026, 11, 10, 15),
          minPurchaseCents: 3000,
          promotions: const ['20 % menos en Leche evaporada 400 g'],
        ),
      );
      await pumpApp(tester, '/mi-cuenta');

      expect(find.text('Sin límite de usos'), findsOneWidget);
      expect(find.textContaining('Con compras desde'), findsOneWidget);
      expect(find.textContaining('Vence el 10 nov'), findsOneWidget);
    });

    testWidgets('en el teléfono entra sin desbordes', (tester) async {
      auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
      codes.codes.add(summerCode);
      await pumpApp(tester, '/mi-cuenta');
      tester.view.physicalSize = const Size(320, 1200);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('VERANO-10'), findsOneWidget);
    });
  });

  testWidgets('sin sesión, lleva al ingreso', (tester) async {
    final router = await pumpApp(tester, '/mi-cuenta');
    expect(location(router), '/login?from=%2Fmi-cuenta');
  });
}
