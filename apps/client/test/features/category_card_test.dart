import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/catalog/category.dart';
import 'package:neils/features/catalog/category_card.dart';
import 'package:neils/theme/brand_colors.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  testWidgets('muestra el nombre, la inicial y la flecha, y se toca', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: neilsTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: CategoryCard(
                category: const Category(id: 'cat-1', name: 'Embutidos'),
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Embutidos'), findsOneWidget);
    expect(find.text('E'), findsOneWidget);
    final arrow = tester.widget<Icon>(find.byIcon(Icons.arrow_forward));
    expect(arrow.color, NeilsColors.primary);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(CategoryCard));
    expect(taps, 1);
  });

  testWidgets('con foto usa la foto', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: neilsTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: CategoryCard(
              category: const Category(
                id: 'cat-1',
                name: 'Embutidos',
                imageUrl: '/images/categories/cat-1/0123456789abcdef.jpg',
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      endsWith('/images/categories/cat-1/0123456789abcdef.jpg'),
    );
  });

  testWidgets('si la foto falla vuelve al color y la inicial', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: neilsTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: CategoryCard(
              category: const Category(
                id: 'cat-1',
                name: 'Embutidos',
                imageUrl: '/images/categories/cat-1/no-existe.jpg',
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    // En los tests las fotos de la red fallan (400): el errorBuilder.
    await tester.pumpAndSettle();

    expect(find.text('E'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
