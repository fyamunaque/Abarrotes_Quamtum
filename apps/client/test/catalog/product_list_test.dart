import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/common/page_list.dart';

import '../fakes.dart';

void main() {
  final products = [
    for (var i = 1; i <= 5; i++)
      Product(
        id: 'p$i',
        name: 'Producto $i',
        priceCents: 100,
        stock: 1,
        category: i.isOdd ? groceries : dairy,
      ),
  ];

  late FakeCatalogRepository catalog;
  late ProviderContainer container;

  setUp(() {
    catalog = FakeCatalogRepository(productList: products, pageSize: 2);
    container = ProviderContainer.test(
      overrides: [catalogRepositoryProvider.overrideWithValue(catalog)],
    );
  });

  const CatalogQuery all = (categoryId: null, search: null);

  Future<PageList<Product>> load([String? categoryId, String? search]) =>
      container.read(
        productListProvider((categoryId: categoryId, search: search)).future,
      );

  List<String> ids(PageList<Product> list) => [
    for (final p in list.items) p.id,
  ];

  test('carga la primera página y sabe si hay más', () async {
    final list = await load();

    expect(ids(list), ['p1', 'p2']);
    expect(list.total, 5);
    expect(list.hasMore, isTrue);
  });

  test('"Ver más" agrega las páginas siguientes hasta el final', () async {
    await load();
    final notifier = container.read(productListProvider(all).notifier);

    await notifier.loadMore();
    await notifier.loadMore();
    final list = container.read(productListProvider(all)).value!;

    expect(ids(list), ['p1', 'p2', 'p3', 'p4', 'p5']);
    expect(list.hasMore, isFalse);
    await notifier.loadMore();
    expect(catalog.requests, [(null, 1), (null, 2), (null, 3)]);
  });

  test('cada categoría tiene su lista', () async {
    expect(ids(await load(groceries.id)), ['p1', 'p3']);
    expect(ids(await load(dairy.id)), ['p2', 'p4']);
  });

  test('lo buscado, dentro de la categoría', () async {
    expect(ids(await load(null, 'producto 3')), ['p3']);
    expect(ids(await load(groceries.id, 'producto')), ['p1', 'p3']);
    expect(catalog.searches.last, 'producto');
  });

  test('si "Ver más" falla, la lista queda como estaba y avisa', () async {
    await load();
    catalog.failure = const ApiFailure('Sin conexión');

    await expectLater(
      container.read(productListProvider(all).notifier).loadMore(),
      throwsA(isA<ApiFailure>()),
    );
    final list = container.read(productListProvider(all)).value!;
    expect(ids(list), ['p1', 'p2']);
    expect(list.loadingMore, isFalse);
  });
}
