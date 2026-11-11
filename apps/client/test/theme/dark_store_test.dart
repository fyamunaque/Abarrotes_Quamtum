import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/category.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/catalog/category_photo.dart';
import 'package:neils/features/catalog/line_total_pill.dart';
import 'package:neils/features/catalog/price_tag.dart';
import 'package:neils/features/home/home_screen.dart';
import 'package:neils/features/shared/cart_bar.dart';
import 'package:neils/offers/offers_providers.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';
import 'package:neils/theme/palette.dart';

import '../fakes.dart';
import '../support.dart';

/// Las piezas de la tienda en el modo oscuro: toman los colores de la paleta
/// oscura, no las constantes de la marca (que son las del claro).
void main() {
  useBundledFonts();

  const dark = NeilsPalette.dark;

  Future<void> pumpDark(WidgetTester tester, Widget child) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: neilsTheme(Brightness.dark),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );

  Color? textColor(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color ??
      DefaultTextStyle.of(tester.element(find.text(text))).style.color;

  testWidgets('la barra del carrito en oscuro: fondo rojo y texto blanco', (
    tester,
  ) async {
    await pumpDark(
      tester,
      CartBar(label: 'Continuar', totalCents: 1320, count: 3, onPressed: () {}),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(CartBar),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, dark.brandFill);
    expect(textColor(tester, 'Continuar'), dark.onBrand);
  });

  testWidgets('la pastilla del total en oscuro usa money sobre moneyTint', (
    tester,
  ) async {
    await pumpDark(tester, const LineTotalPill(2640));

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(LineTotalPill),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).color, dark.moneyTint);
    expect(textColor(tester, formatSoles(2640)), dark.money);
  });

  testWidgets('el precio en oferta en oscuro usa brandText', (tester) async {
    await pumpDark(
      tester,
      PriceTag(
        const Product(
          id: 'hot-dog',
          name: 'Hot dog de pollo',
          priceCents: 263,
          promoPriceCents: 220,
          stock: 4,
        ),
      ),
    );

    expect(textColor(tester, formatSoles(220)), dark.brandText);
  });

  testWidgets('la categoría sin foto en oscuro usa su par oscuro', (
    tester,
  ) async {
    const category = Category(id: 'cat-embutidos', name: 'Embutidos');
    await pumpDark(
      tester,
      const SizedBox(
        width: 160,
        height: 120,
        child: CategoryPhoto(category: category),
      ),
    );

    final (fondo, letra) = dark.placeholderFor(category.id);
    final box = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(CategoryPhoto),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(box.color, fondo);
    expect(textColor(tester, 'E'), letra);
  });

  testWidgets('la portada en oscuro entra en 320 sin desbordes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(
            () => TestSession(signedInAs(UserRole.customer)),
          ),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(frequentList: const [rice]),
          ),
          offersRepositoryProvider.overrideWithValue(FakeOffersRepository()),
        ],
        child: MaterialApp(
          theme: neilsTheme(Brightness.dark),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      Theme.of(tester.element(find.byType(HomeScreen))).brightness,
      Brightness.dark,
    );
  });
}
