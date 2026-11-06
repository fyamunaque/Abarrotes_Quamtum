import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/features/shared/brand.dart';
import 'package:neils/features/shared/brand_hero.dart';
import 'package:neils/features/shared/diagonal_band.dart';
import 'package:neils/theme/brand_colors.dart';
import 'package:neils/theme/neils_theme.dart';

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
    expect(accent.style?.color, NeilsColors.primary);
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

  testWidgets('TrustBadges muestra los tres sellos', (tester) async {
    await pump(tester, const TrustBadges(), size: const Size(1280, 900));

    expect(find.text('Entrega confiable'), findsOneWidget);
    expect(find.text('Calidad garantizada'), findsOneWidget);
    expect(find.text('Atención personalizada'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    expect(find.byIcon(Icons.support_agent), findsOneWidget);
  });

  testWidgets('en el teléfono los sellos entran sin desbordarse', (
    tester,
  ) async {
    await pump(tester, const TrustBadges(), size: const Size(320, 700));

    expect(tester.takeException(), isNull);
    expect(find.text('Atención personalizada'), findsOneWidget);
  });
}
