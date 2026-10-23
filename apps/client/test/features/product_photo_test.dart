import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/config/api_config.dart';
import 'package:neils/features/catalog/product_photo.dart';
import 'package:neils/theme/brand_colors.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

/// La foto del producto: de dónde la pide y el marcador sin foto.
void main() {
  useBundledFonts();

  Future<void> pump(WidgetTester tester, ProductPhoto photo) =>
      tester.pumpWidget(
        MaterialApp(
          theme: neilsTheme(),
          home: Center(child: SizedBox(width: 200, height: 150, child: photo)),
        ),
      );

  String? requested(WidgetTester tester) =>
      switch (tester.widget<Image>(find.byType(Image)).image) {
        final NetworkImage image => image.url,
        _ => null,
      };

  testWidgets('una foto subida se pide al servidor de la app', (tester) async {
    await pump(
      tester,
      const ProductPhoto(
        '/images/products/p-1/0123456789abcdef.jpg',
        name: 'Arroz extra 5 kg',
      ),
    );

    expect(
      requested(tester),
      apiBaseUrl
          .resolve('/images/products/p-1/0123456789abcdef.jpg')
          .toString(),
    );
  });

  testWidgets('una URL externa se pide tal cual', (tester) async {
    await pump(
      tester,
      const ProductPhoto(
        'https://cdn.tienda.pe/arroz.jpg',
        name: 'Arroz extra 5 kg',
      ),
    );

    expect(requested(tester), 'https://cdn.tienda.pe/arroz.jpg');
  });

  testWidgets('sin foto: la inicial sobre el color de su categoría', (
    tester,
  ) async {
    await pump(
      tester,
      const ProductPhoto(null, name: 'arroz extra 5 kg', colorKey: 'cat-1'),
    );

    final (background, foreground) = PlaceholderColors.of('cat-1');
    expect(find.byType(Image), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox).last).color,
      background,
    );
    expect(tester.widget<Text>(find.text('A')).style?.color, foreground);
  });

  testWidgets('sin categoría, el color sale del nombre', (tester) async {
    await pump(tester, const ProductPhoto(null, name: 'Ñandú'));

    expect(find.text('Ñ'), findsOneWidget);
    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox).last).color,
      PlaceholderColors.of('Ñandú').$1,
    );
  });

  group('PlaceholderColors', () {
    test('una misma categoría tiene siempre el mismo color', () {
      expect(PlaceholderColors.of('cat-1'), PlaceholderColors.of('cat-1'));
      // El mismo par en la web y en Android: un hash propio, conocido.
      expect(PlaceholderColors.of(''), PlaceholderColors.pairs[7]);
      expect(
        PlaceholderColors.of('a'),
        PlaceholderColors.pairs[(7 * 31 + 97) % 8],
      );
    });

    test('las categorías del seed no quedan todas del mismo color', () {
      final colors = {
        for (final name in [
          'Abarrotes',
          'Lácteos y huevos',
          'Carnes y embutidos',
          'Frutas y verduras',
          'Panadería',
          'Bebidas',
          'Limpieza',
          'Cuidado personal',
          'Snacks y dulces',
        ])
          PlaceholderColors.of(name),
      };
      expect(colors.length, greaterThanOrEqualTo(5));
    });
  });
}
