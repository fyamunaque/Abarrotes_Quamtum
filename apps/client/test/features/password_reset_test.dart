import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/app.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/auth/auth_repository.dart';
import 'package:neils/features/shared/brand.dart';
import 'package:neils/router/router.dart';

import '../fakes.dart';
import '../support.dart';

/// "¿Olvidaste tu contraseña?" en Ingresar, y el ingreso a dos columnas en
/// escritorio.
void main() {
  useBundledFonts();

  late FakeAuthRepository auth;

  setUp(() {
    auth = FakeAuthRepository()
      ..addAccount('ana@tienda.pe', 'secreta', name: 'Ana Quispe');
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    String at = '/login',
    double width = 1280,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userRepositoryProvider.overrideWithValue(FakeUserRepository(auth)),
        ],
        child: const NeilsApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(NeilsApp)))
        .read(routerProvider)
        .go(at);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder finder) =>
      find.descendant(of: find.byType(AlertDialog), matching: finder);

  Finder dialogEmail() =>
      inDialog(find.widgetWithText(TextFormField, 'Correo'));

  Future<void> openReset(WidgetTester tester, {String email = ''}) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), email);
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.tap(
      inDialog(find.widgetWithText(FilledButton, 'Enviar enlace')),
    );
    await tester.pumpAndSettle();
  }

  const sentMessage =
      'Si hay una cuenta con ese correo, te enviamos un enlace para crear una '
      'contraseña nueva. Revisa también el spam.';

  group('¿Olvidaste tu contraseña?', () {
    testWidgets('abre el diálogo con el correo ya escrito', (tester) async {
      await pumpApp(tester);
      await openReset(tester, email: ' ana@tienda.pe ');

      expect(find.text('Recuperar la contraseña'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(dialogEmail()).controller!.text,
        'ana@tienda.pe',
      );
    });

    testWidgets('manda el enlace y lo dice', (tester) async {
      await pumpApp(tester);
      await openReset(tester, email: 'ana@tienda.pe');
      await send(tester);

      expect(auth.passwordResets, ['ana@tienda.pe']);
      expect(find.text('Revisa tu correo'), findsOneWidget);
      expect(find.text(sentMessage), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('un correo sin cuenta recibe el mismo mensaje', (tester) async {
      await pumpApp(tester);
      await openReset(tester);
      await tester.enterText(dialogEmail(), 'nadie@tienda.pe');
      await send(tester);

      expect(auth.passwordResets, ['nadie@tienda.pe']);
      expect(find.text(sentMessage), findsOneWidget);
    });

    testWidgets('un correo mal escrito: el error, sin llamar a Firebase', (
      tester,
    ) async {
      await pumpApp(tester);
      await openReset(tester, email: 'ana@');
      await send(tester);

      expect(inDialog(find.text('Ese correo no es válido.')), findsOneWidget);
      expect(auth.passwordResets, isEmpty);
    });

    testWidgets('si Firebase falla, su mensaje en el diálogo', (tester) async {
      auth.resetFailure = const AuthFailure(
        'Demasiados intentos. Espera unos minutos y vuelve a intentar.',
      );
      await pumpApp(tester);
      await openReset(tester, email: 'ana@tienda.pe');
      await send(tester);

      expect(
        inDialog(
          find.text(
            'Demasiados intentos. Espera unos minutos y vuelve a intentar.',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Recuperar la contraseña'), findsOneWidget);
    });

    testWidgets('"Cancelar" cierra sin mandar nada', (tester) async {
      await pumpApp(tester);
      await openReset(tester, email: 'ana@tienda.pe');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(auth.passwordResets, isEmpty);
    });
  });

  group('en escritorio', () {
    Finder brandPanel() => find.text('Sigue tu pedido');

    testWidgets('Ingresar y Crear una cuenta, con el panel de la marca', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(brandPanel(), findsOneWidget);
      // El panel a la izquierda y el formulario a la derecha.
      expect(
        tester.getCenter(brandPanel()).dx,
        lessThan(
          tester.getCenter(find.widgetWithText(FilledButton, 'Ingresar')).dx,
        ),
      );
      // El logo grande del panel y el de la barra.
      expect(find.byType(NeilsLogo), findsNWidgets(2));

      await pumpApp(tester, at: '/registro');
      expect(brandPanel(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('por debajo de 900 px, solo el formulario', (tester) async {
      await pumpApp(tester, width: 899);
      expect(brandPanel(), findsNothing);

      await pumpApp(tester, width: 375);
      expect(brandPanel(), findsNothing);
      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
