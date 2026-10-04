import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/features/admin/admin_shell.dart';
import 'package:neils/features/shared/brand.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

/// La barra con sesión en un teléfono: con staff, un nombre largo y todos los
/// botones, tiene que entrar sin desbordarse.
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

  for (final width in [320.0, 375.0, 600.0]) {
    testWidgets('a $width px la barra pública entra: la cuenta va en un menú', (
      tester,
    ) async {
      await pumpAt(tester, width, const PublicScaffold(child: Text('x')));
      expect(tester.takeException(), isNull);
      expect(find.text('Salir'), findsNothing);
      expect(find.byTooltip('Catálogo'), findsOneWidget);
      expect(find.byTooltip('Carrito'), findsOneWidget);

      await tester.tap(find.byTooltip('Tu cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Alejandra Quispe'), findsOneWidget);
      expect(find.text('alejandra@tienda.pe'), findsOneWidget);
      expect(find.text('Panel'), findsOneWidget);
      expect(find.text('Salir'), findsOneWidget);
    });

    testWidgets('a $width px la barra del panel entra', (tester) async {
      await pumpAt(tester, width, const AdminShell(child: Text('x')));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Tu cuenta'));
      await tester.pumpAndSettle();

      // Ya está en el panel: el menú no lo ofrece.
      expect(find.text('Panel'), findsNothing);
      expect(find.text('Salir'), findsOneWidget);
    });
  }

  testWidgets('"Salir" desde el menú cierra la sesión', (tester) async {
    final session = TestSession(staff);
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => session)],
        child: MaterialApp(
          theme: neilsTheme(),
          home: const PublicScaffold(child: Text('x')),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Tu cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(session.signedOut, isTrue);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('sin sesión, a 320 px entran el catálogo, el carrito e '
      '"Ingresar"', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
        ],
        child: MaterialApp(
          theme: neilsTheme(),
          home: const PublicScaffold(child: Text('x')),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  for (final width in [840.0, 1024.0]) {
    testWidgets('a $width px, el nombre y los botones en la barra', (
      tester,
    ) async {
      await pumpAt(tester, width, const PublicScaffold(child: Text('x')));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Tu cuenta'), findsNothing);
      expect(find.text('Catálogo'), findsOneWidget);
      expect(find.byTooltip('Carrito'), findsOneWidget);
      expect(find.text('Alejandra'), findsOneWidget);
      expect(find.text('Panel'), findsOneWidget);
      expect(find.text('Salir'), findsOneWidget);
    });
  }
}
