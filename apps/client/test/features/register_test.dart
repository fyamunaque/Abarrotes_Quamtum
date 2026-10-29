import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/features/auth/auth_form.dart';
import 'package:neils/router/router.dart';

import '../fakes.dart';
import '../support.dart';

/// Crear una cuenta: la contraseña fuerte, el celular, el DNI opcional y los
/// términos, con la app completa y Firebase y el servidor en memoria.
void main() {
  useBundledFonts();

  late FakeAuthRepository auth;
  late FakeUserRepository users;

  setUp(() {
    auth = FakeAuthRepository();
    users = FakeUserRepository(auth);
  });

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
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
    ).read(routerProvider)..go('/registro');
    await tester.pumpAndSettle();
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> fill(
    WidgetTester tester, {
    String name = 'Ana Quispe',
    String email = 'ana@tienda.pe',
    String phone = '987 654 321',
    String dni = '',
    String password = 'abarrotes2026',
    String? repeat,
    bool accept = true,
  }) async {
    await tester.enterText(field('Nombre'), name);
    await tester.enterText(field('Correo'), email);
    await tester.enterText(field('Celular'), phone);
    await tester.enterText(field('DNI (opcional)'), dni);
    await tester.enterText(field('Contraseña'), password);
    await tester.enterText(field('Repetir contraseña'), repeat ?? password);
    if (accept) {
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
    }
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Crear cuenta');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('crea la cuenta, guarda el celular, el DNI y los términos', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    await fill(tester, dni: '45678912');
    await submit(tester);

    expect(location(router), '/catalogo');
    expect(users.profileUpdates, [
      (
        phone: '987 654 321',
        dni: '45678912',
        clearDni: false,
        acceptTerms: true,
      ),
    ]);
    final user = await users.me('token-${auth.current}');
    expect(user.name, 'Ana Quispe');
    expect(user.phone, '987654321');
    expect(user.dni, '45678912');
    expect(user.profileComplete, isTrue);
  });

  testWidgets('sin DNI también: es opcional y dice para qué sirve', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    expect(find.textContaining('tu cuenta queda más protegida'), findsOne);

    await fill(tester);
    await submit(tester);

    expect(location(router), '/catalogo');
    expect(users.profileUpdates.single.dni, isNull);
  });

  testWidgets('pide celular, una contraseña de 8 y aceptar los términos', (
    tester,
  ) async {
    await pumpApp(tester);
    await submit(tester);

    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    expect(find.text('Escribe tu celular.'), findsOneWidget);
    expect(find.text('Usa al menos 8 caracteres.'), findsOneWidget);
    expect(
      find.text(
        'Para continuar, acepta los términos de uso y la política de '
        'privacidad.',
      ),
      findsOneWidget,
    );
    expect(auth.current, isNull);
  });

  testWidgets('la contraseña: letras y números, y la misma dos veces', (
    tester,
  ) async {
    await pumpApp(tester);
    await fill(tester, password: 'abarrotes', repeat: 'abarrotes');
    await submit(tester);
    expect(find.text('Combina letras y números.'), findsOneWidget);

    await fill(tester, password: 'abarrotes2026', repeat: 'abarrotes2025');
    await submit(tester);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(auth.current, isNull);
  });

  testWidgets('celular y DNI con su formato', (tester) async {
    await pumpApp(tester);
    await fill(tester, phone: '812 345 678', dni: '1234');
    await submit(tester);

    expect(
      find.text('Usa un celular de 9 dígitos que empiece con 9.'),
      findsOneWidget,
    );
    expect(find.text('El DNI tiene 8 dígitos.'), findsOneWidget);
    expect(auth.current, isNull);
  });

  testWidgets('el indicador de seguridad cambia mientras se escribe', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.textContaining('Seguridad:'), findsNothing);

    await tester.enterText(field('Contraseña'), 'abc');
    await tester.pump();
    expect(find.textContaining('Seguridad: débil'), findsOneWidget);

    await tester.enterText(field('Contraseña'), 'abarrotes2026');
    await tester.pump();
    expect(find.textContaining('Seguridad: media'), findsOneWidget);

    await tester.enterText(field('Contraseña'), 'Abarrotes-2026');
    await tester.pump();
    expect(find.text('Seguridad: fuerte'), findsOneWidget);
  });

  test('qué tan segura es una contraseña', () {
    expect(PasswordStrength.of(''), PasswordStrength.weak);
    expect(PasswordStrength.of('12345678'), PasswordStrength.weak);
    expect(PasswordStrength.of('abcdefgh'), PasswordStrength.weak);
    expect(PasswordStrength.of('abcdefg1'), PasswordStrength.medium);
    // Una sola de: 12 o más, mayúsculas y minúsculas, un símbolo.
    expect(PasswordStrength.of('abcdefghijk1'), PasswordStrength.medium);
    expect(PasswordStrength.of('Abcdefghijk1'), PasswordStrength.strong);
    expect(PasswordStrength.of('abcdefg1!*'), PasswordStrength.medium);
    expect(PasswordStrength.of('Abcdefg1!'), PasswordStrength.strong);
  });

  testWidgets('los términos se leen en un diálogo sin perder lo escrito', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.enterText(field('Nombre'), 'Ana Quispe');

    await tester.ensureVisible(find.text('Términos de uso'));
    await tester.tap(find.text('Términos de uso'));
    await tester.pumpAndSettle();
    expect(find.text('Pedidos y precios'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Política de privacidad'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ley N.° 29733'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Quispe'), findsOneWidget);
  });

  testWidgets('con un DNI de otra cuenta, la cuenta queda creada y "Mi cuenta" '
      'lo dice', (tester) async {
    users.takenDnis.add('45678912');
    final router = await pumpApp(tester);
    await fill(tester, dni: '45678912');
    await submit(tester);

    expect(location(router), '/mi-cuenta?from=%2Fcatalogo');
    expect(auth.current, isNotNull);
    expect(
      find.text('Ese DNI ya está registrado en otra cuenta.'),
      findsOneWidget,
    );
    // Lo escrito sigue ahí, con los términos ya marcados.
    expect(
      tester.widget<TextFormField>(field('Celular')).controller!.text,
      '987 654 321',
    );

    await tester.enterText(field('DNI (opcional)'), '11112222');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(location(router), '/catalogo');
    final user = await users.me('token-${auth.current}');
    expect(user.dni, '11112222');
    expect(user.profileComplete, isTrue);
  });

  testWidgets('un correo ya registrado muestra el error', (tester) async {
    auth.addAccount('ana@tienda.pe', 'secreta');
    await pumpApp(tester);
    await fill(tester);
    await submit(tester);

    expect(find.textContaining('Ya hay una cuenta'), findsOneWidget);
  });
}
