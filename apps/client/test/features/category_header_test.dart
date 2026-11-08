import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/catalog/category.dart';
import 'package:neils/features/catalog/category_header.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  const category = Category(
    id: 'cat-embutidos',
    name: 'Embutidos y fiambres',
    // Cerca del máximo que acepta el panel (80 caracteres).
    description: 'Hot dogs, jamonadas, salchichas y chorizos para tu carta de todos los días.',
  );

  Future<void> pumpHeader(WidgetTester tester, double textScale) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: neilsTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: CategoryHeader(category: category),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 1.3]) {
    testWidgets('el nombre y la descripción entran con el texto al '
        '${(scale * 100).round()} %', (tester) async {
      await pumpHeader(tester, scale);

      expect(tester.takeException(), isNull);
      final header = tester.getRect(find.byType(CategoryHeader));
      for (final text in [category.name, category.description!]) {
        final rect = tester.getRect(find.text(text));
        expect(
          header.contains(rect.topLeft) && header.contains(rect.bottomRight),
          isTrue,
          reason: '"$text" en $rect, fuera de $header',
        );
      }
    });
  }

  testWidgets('en el teléfono mide al menos 120 de alto', (tester) async {
    await pumpHeader(tester, 1);

    expect(
      tester.getSize(find.byType(CategoryHeader)).height,
      greaterThanOrEqualTo(120),
    );
  });

  testWidgets('si la foto no carga, se ven el color y la inicial', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: neilsTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: CategoryHeader(
              category: Category(
                id: 'cat-embutidos',
                name: 'Embutidos',
                imageUrl:
                    '/images/categories/cat-embutidos/0123456789abcdef.jpg',
              ),
            ),
          ),
        ),
      ),
    );
    // En los tests, toda descarga falla (HTTP 400).
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('E'), findsOneWidget);
  });
}
