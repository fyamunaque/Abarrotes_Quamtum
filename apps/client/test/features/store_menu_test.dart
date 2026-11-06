import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/features/shared/brand.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

/// El menú de la tienda en el teléfono: las secciones y la cuenta.
void main() {
  useBundledFonts();

  late TestSession session;

  Future<void> openMenu(WidgetTester tester, Session initial) async {
    session = TestSession(initial);
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
    await tester.pump();
    await tester.tap(find.byTooltip('Menú'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin cuenta: las secciones e Ingresar', (tester) async {
    await openMenu(tester, const SignedOut());

    for (final item in ['Inicio', 'Catálogo', 'Promociones', 'Ingresar']) {
      expect(find.text(item), findsOneWidget, reason: item);
    }
    expect(find.text('Mis pedidos'), findsNothing);
    expect(find.text('Mi cuenta'), findsNothing);
    expect(find.text('Salir'), findsNothing);
  });

  testWidgets('con cuenta: saluda, Mis pedidos, Mi cuenta y Salir', (
    tester,
  ) async {
    await openMenu(tester, signedInAs(UserRole.customer));

    expect(find.text('¡Hola, Ana!'), findsOneWidget);
    expect(find.text('Mis pedidos'), findsOneWidget);
    expect(find.text('Mi cuenta'), findsOneWidget);
    expect(find.text('Salir'), findsOneWidget);
    expect(find.text('Panel de la tienda'), findsNothing);
    expect(find.text('Ingresar'), findsNothing);
  });

  testWidgets('con personal: también el panel', (tester) async {
    await openMenu(tester, signedInAs(UserRole.staff));

    expect(find.text('Panel de la tienda'), findsOneWidget);
  });

  testWidgets('"Salir" cierra la sesión', (tester) async {
    await openMenu(tester, signedInAs(UserRole.customer));

    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(session.signedOut, isTrue);
  });
}
