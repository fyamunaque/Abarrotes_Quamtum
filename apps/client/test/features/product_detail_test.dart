import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/cart/cart.dart';
import 'package:neils/cart/cart_storage.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/features/catalog/product_detail_screen.dart';
import 'package:neils/features/catalog/promo_tag.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';

import '../fakes.dart';
import '../support.dart';

/// El detalle de un producto: lo que dice del stock, el código y "Editar".
void main() {
  useBundledFonts();

  Product ham({int stock = 37}) => Product(
    id: 'jamonada',
    sku: '3580',
    name: 'Jamonada especial',
    priceCents: 1290,
    stock: stock,
    category: groceries,
    offers: const [
      (
        type: 'buyXPayY',
        label: '2x1',
        title: null,
        description: '2x1 en este producto',
      ),
    ],
  );

  Future<void> pumpDetail(
    WidgetTester tester,
    Product product, {
    int inCart = 0,
  }) async {
    useWideScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(productList: [product]),
          ),
          cartStorageProvider.overrideWithValue(
            MemoryCartStorage(
              inCart == 0 ? const Cart() : Cart([CartLine(product, inCart)]),
            ),
          ),
        ],
        child: MaterialApp(
          theme: neilsTheme(),
          home: ProductDetailScreen(productId: product.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el detalle no muestra las unidades en stock', (tester) async {
    await pumpDetail(tester, ham());

    expect(find.text('Disponible'), findsOneWidget);
    expect(find.textContaining('37'), findsNothing);
  });

  testWidgets('con pocas avisa cuántas quedan', (tester) async {
    await pumpDetail(tester, ham(stock: 3));

    expect(find.text('Últimas 3'), findsOneWidget);
  });

  testWidgets('con el producto en el carrito dice Editar', (tester) async {
    await pumpDetail(tester, ham(), inCart: 2);

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Tienes 2 en el carrito.'), findsOneWidget);
  });

  testWidgets('muestra el código antes del nombre y la cinta', (tester) async {
    await pumpDetail(tester, ham());

    expect(find.text('3580 – Jamonada especial'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(PromoTag), matching: find.text('2x1')),
      findsOneWidget,
    );
  });
}
