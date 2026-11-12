import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/features/shared/brand.dart';
import 'package:neils/features/shared/brand_hero.dart';
import 'package:neils/features/shared/diagonal_band.dart';
import 'package:neils/theme/brand_colors.dart';
import 'package:neils/theme/neils_theme.dart';
import 'package:neils/theme/palette.dart';
import 'package:neils/theme/motion.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  Future<void> pump(WidgetTester tester, Widget child, {Size? size}) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: neilsTheme(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  const hero = BrandHero(
    titleStart: 'Tu negocio siempre abastecido ',
    titleAccent: "con Neil's.",
    body: 'Insumos gastronómicos de calidad.',
    actions: [Text('Ver catálogo')],
  );

  testWidgets('BrandHero muestra el titular con la parte en rojo', (
    tester,
  ) async {
    await pump(tester, hero, size: const Size(1280, 900));

    final title = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText() ==
                "Tu negocio siempre abastecido con Neil's.",
      ),
    );
    final spans = <TextSpan>[];
    title.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
    final accent = spans.singleWhere((span) => span.text == "con Neil's.");
    expect(accent.style?.color, NeilsPalette.light.brandText);
    expect(find.text('Insumos gastronómicos de calidad.'), findsOneWidget);
    expect(find.text('Ver catálogo'), findsOneWidget);
  });

  testWidgets('sin foto, la franja es roja con el logo blanco', (tester) async {
    await pump(tester, hero, size: const Size(1280, 900));

    final band = find.byType(DiagonalBand);
    expect(band, findsOneWidget);
    expect(
      find.descendant(of: band, matching: find.byType(NeilsLogo)),
      findsOneWidget,
    );
    final logo = tester.widget<Image>(
      find.descendant(of: band, matching: find.byType(Image)),
    );
    expect(
      (logo.image as AssetImage).assetName,
      'assets/images/neils_logo_white.png',
    );
    final block = tester.widget<ColoredBox>(
      find.descendant(of: band, matching: find.byType(ColoredBox)).first,
    );
    expect(block.color, NeilsColors.primary);
  });

  testWidgets('en el teléfono la franja va arriba', (tester) async {
    await pump(tester, hero, size: const Size(390, 844));

    final band = tester.getRect(find.byType(DiagonalBand));
    final title = tester.getRect(find.byType(RichText).first);
    expect(band.top, lessThan(title.top));
    expect(band.height, 160);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con la nota, la línea del horario', (tester) async {
    await pump(
      tester,
      const BrandHero(
        titleStart: 'Insumos para restaurantes ',
        titleAccent: 'y cafeterías',
        body: 'Embutidos y lácteos.',
        note: 'Atendemos de 8 a 20 h',
        actions: [],
      ),
      size: const Size(1280, 900),
    );

    expect(find.text('Atendemos de 8 a 20 h'), findsOneWidget);
  });

  testWidgets('la entrada: el titular sube desde transparente y la foto se '
      'asienta', (tester) async {
    await pump(
      tester,
      const BrandHero(
        titleStart: 'Insumos ',
        titleAccent: 'y más',
        body: 'Texto.',
        actions: [],
        entrance: true,
      ),
      size: const Size(1280, 900),
    );

    Opacity copy() => tester.widget<Opacity>(
      find
          .ancestor(of: find.text('Texto.'), matching: find.byType(Opacity))
          .first,
    );
    double photoScale() => tester
        .widget<Transform>(
          find
              .ancestor(
                of: find.byType(DiagonalBand),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .entry(0, 0);

    expect(copy().opacity, 0);
    expect(photoScale(), closeTo(1.03, 0.001));
    await tester.pump(NeilsMotion.entrance ~/ 2);
    expect(copy().opacity, allOf(greaterThan(0), lessThan(1)));
    await tester.pumpAndSettle();
    expect(copy().opacity, 1);
    expect(photoScale(), 1);
  });

  testWidgets('sin entrada, todo está desde el principio', (tester) async {
    await pump(tester, hero, size: const Size(1280, 900));

    expect(tester.hasRunningAnimations, isFalse);
  });
}
