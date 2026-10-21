import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/app.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/features/shared/verify_email_notice.dart';
import 'package:neils/router/router.dart';

import '../fakes.dart';
import '../support.dart';

/// El aviso para confirmar el correo y el refresco del perfil al volver a la
/// app, con la sesión real y Firebase y el servidor en memoria.
void main() {
  useBundledFonts();

  late FakeAuthRepository auth;
  late FakeUserRepository users;
  late FakeAccount ana;

  setUp(() {
    auth = FakeAuthRepository();
    users = FakeUserRepository(auth);
    ana = auth.addAccount(
      'ana@gmail.com',
      'secreta',
      name: 'Ana',
      signedIn: true,
      emailVerified: false,
    );
  });

  Future<void> pumpApp(WidgetTester tester, {String at = '/'}) async {
    useWideScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userRepositoryProvider.overrideWithValue(users),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: const NeilsApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(NeilsApp)))
        .read(routerProvider)
        .go(at);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sin confirmar el correo: un aviso genérico para mandar el correo y '
    'confirmarlo',
    (tester) async {
      await pumpApp(tester);

      expect(
        find.text('Verifica tu correo para completar tu cuenta.'),
        findsOneWidget,
      );
      // No dice qué se gana al verificar.
      final notice = find.byType(VerifyEmailNotice);
      expect(
        find.descendant(of: notice, matching: find.textContaining('oferta')),
        findsNothing,
      );
      expect(
        find.descendant(of: notice, matching: find.textContaining('VIP')),
        findsNothing,
      );

      await tester.tap(find.text('Enviar el correo'));
      await tester.pumpAndSettle();
      expect(auth.verificationEmails, 1);
      expect(
        find.textContaining('Te enviamos un correo a ana@gmail.com'),
        findsOneWidget,
      );

      // Todavía no lo abrió.
      await tester.tap(find.text('Ya lo verifiqué'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Todavía no vemos tu correo confirmado'),
        findsOneWidget,
      );

      // Lo confirmó: el aviso desaparece.
      ana.emailVerified = true;
      await tester.tap(find.text('Ya lo verifiqué'));
      await tester.pumpAndSettle();
      expect(find.byType(VerifyEmailNotice), findsNothing);
    },
  );

  testWidgets('con el correo confirmado no hay aviso', (tester) async {
    ana.emailVerified = true;
    await pumpApp(tester, at: '/catalogo');

    expect(find.byType(VerifyEmailNotice), findsNothing);
  });

  testWidgets('al volver a la app vuelve a pedir el perfil', (tester) async {
    await pumpApp(tester);
    final calls = users.calls;

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(users.calls, calls);

    // Mientras tanto confirmó el correo (y un admin lo hizo VIP).
    ana.emailVerified = true;
    users.vips.add(ana.uid);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(users.calls, calls + 1);
    expect(find.byType(VerifyEmailNotice), findsNothing);
  });
}
