import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/catalog/http_catalog_repository.dart';
import 'package:neils/common/api_client.dart';

void main() {
  http.Response json(int status, Object? body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  HttpCatalogRepository repository(MockClientHandler handler) =>
      HttpCatalogRepository(
        ApiClient(MockClient(handler), baseUrl: Uri.parse('http://api.pe')),
      );

  /// Un producto como lo manda el servidor (productJson en apps/server).
  Map<String, Object?> product({Object? promotion}) => {
    'id': 'p-1',
    'name': 'Aceite vegetal 1 L',
    'description': 'Para cocinar y freír.',
    'sku': 'ACE-1L',
    'price': '10.9',
    'imageUrl': null,
    'active': true,
    'currentStock': 25,
    'minStock': 5,
    'expirationDate': null,
    'createdAt': '2026-10-04T13:25:12.749Z',
    'categoryId': 'c-1',
    'category': {'id': 'c-1', 'name': 'Abarrotes'},
    'promotion': promotion,
  };

  test('categorías', () async {
    final categories = await repository(
      (_) async => json(200, [
        {'id': 'c-1', 'name': 'Abarrotes'},
        {'id': 'c-2', 'name': 'Lácteos'},
      ]),
    ).categories();

    expect(
      [for (final c in categories) (c.id, c.name)],
      [('c-1', 'Abarrotes'), ('c-2', 'Lácteos')],
    );
  });

  test('productos: página, tamaño y categoría en el query', () async {
    late Uri url;
    final page = await repository((request) async {
      url = request.url;
      return json(200, {
        'data': [
          product(
            promotion: {
              'id': 'promo-1',
              'promoPrice': '8.9',
              'startDate': '2026-10-04',
              'endDate': '2026-11-02',
            },
          ),
        ],
        'meta': {'total': 41, 'page': 3, 'limit': 20},
      });
    }).products(categoryId: 'c-1', page: 3);

    expect(url.path, '/products');
    expect(url.queryParameters, {
      'page': '3',
      'limit': '20',
      'categoryId': 'c-1',
    });
    expect(page.total, 41);
    final oil = page.items.single;
    expect(oil.name, 'Aceite vegetal 1 L');
    expect(oil.priceCents, 1090);
    expect(oil.promoPriceCents, 890);
    expect(oil.finalPriceCents, 890);
    expect(oil.stock, 25);
    expect(oil.description, 'Para cocinar y freír.');
    expect(oil.category?.name, 'Abarrotes');
  });

  test(
    'sin categoría no manda categoryId; sin promoción, el precio normal',
    () async {
      late Uri url;
      final page = await repository((request) async {
        url = request.url;
        return json(200, {
          'data': [product()],
          'meta': {'total': 1},
        });
      }).products();

      expect(url.queryParameters, {'page': '1', 'limit': '20'});
      expect(page.items.single.onSale, isFalse);
      expect(page.items.single.finalPriceCents, 1090);
    },
  );

  test('un producto que no existe: ApiFailure 404', () {
    expect(
      repository((_) async => json(404, {'message': 'Producto no encontrado'}))
          .product('p-x'),
      throwsA(isA<ApiFailure>().having((f) => f.status, 'status', 404)),
    );
  });

  test('una respuesta con otra forma: "algo inesperado"', () {
    final failure = throwsA(
      isA<ApiFailure>().having(
        (f) => f.message,
        'message',
        'El servidor respondió algo inesperado.',
      ),
    );
    expect(
      repository((_) async => json(200, {'items': []})).products(),
      failure,
    );
    expect(
      repository((_) async => json(200, {...product(), 'price': 10.9}))
          .product('p-1'),
      failure,
    );
  });
}
