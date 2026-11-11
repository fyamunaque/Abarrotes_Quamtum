import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/appearance/appearance.dart';
import 'package:neils/appearance/appearance_providers.dart';
import 'package:neils/appearance/appearance_repository.dart';
import 'package:neils/features/shared/appearance_controls.dart';
import 'package:neils/features/shared/brand.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';

import '../admin/panel_support.dart';
import '../support.dart';

/// Dónde se elige Sistema, Claro u Oscuro.
void main() {
  useBundledFonts();

  late ProviderContainer container;

  Future<void> pumpAlone(
    WidgetTester tester,
    Widget child, {
    ThemePreference stored = ThemePreference.light,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appearanceRepositoryProvider.overrideWithValue(
            MemoryAppearanceRepository(stored),
          ),
        ],
        child: MaterialApp(
          theme: neilsTheme(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    container = ProviderScope.containerOf(tester.element(find.byWidget(child)));
  }

  bool selected(WidgetTester tester, String label) =>
      tester.getSemantics(find.text(label)).flagsCollection.isSelected ==
      Tristate.isTrue;

  testWidgets('el selector marca la opción activa y la cambia', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpAlone(tester, const AppearanceSelector());

    expect(selected(tester, 'Claro'), isTrue);
    expect(selected(tester, 'Oscuro'), isFalse);
    expect(find.text('Sistema sigue al modo de tu teléfono.'), findsOneWidget);

    await tester.tap(find.text('Oscuro'));
    await tester.pump();

    expect(container.read(appearanceProvider), ThemePreference.dark);
    expect(selected(tester, 'Oscuro'), isTrue);
    semantics.dispose();
  });

  testWidgets('el botón abre el menú y cambia a oscuro', (tester) async {
    await pumpAlone(tester, const AppearanceButton());

    await tester.tap(find.byTooltip('Apariencia'));
    await tester.pumpAndSettle();
    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(container.read(appearanceProvider), ThemePreference.dark);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });

  testWidgets('el menú lateral muestra Apariencia', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
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
    await tester.pump();
    await tester.tap(find.byTooltip('Menú'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(AppearanceSelector),
      200,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Apariencia'), findsOneWidget);
  });

  testWidgets('la barra de escritorio tiene el botón', (tester) async {
    useWideScreen(tester);
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
    await tester.pump();

    expect(find.byType(AppearanceButton), findsOneWidget);
  });

  testWidgets('el panel tiene el botón', (tester) async {
    await pumpPanel(tester, at: '/admin');

    expect(find.byType(AppearanceButton), findsOneWidget);
  });

  testWidgets('el selector entra en 320 con el texto al 130 %', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // El ancho que le queda dentro del menú lateral de un teléfono de 320.
    await pumpAlone(
      tester,
      const SizedBox(width: 240, child: AppearanceSelector()),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    for (final label in ['Sistema', 'Claro', 'Oscuro']) {
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text(label),
                matching: find.byType(InkWell),
              ),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
    }
  });
}
