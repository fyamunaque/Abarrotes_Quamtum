import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/catalog/http_catalog_repository.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';

void main() {
  http.Response json(int status, Object? body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  HttpCatalogRepository repository(
    MockClientHandler handler, {
    String? token,
  }) => HttpCatalogRepository(
    ApiClient(MockClient(handler), baseUrl: Uri.parse('http://api.pe')),
    idToken: () async => token,
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

  test('lee la descripción y la foto de una categoría', () async {
    final categories = await repository(
      (_) async => json(200, [
        {
          'id': 'c-1',
          'name': 'Embutidos',
          'description': 'Hot dogs, jamonadas y más',
          'imageUrl': '/images/categories/c-1/0123456789abcdef.jpg',
        },
        {'id': 'c-2', 'name': 'Lácteos', 'description': null, 'imageUrl': null},
      ]),
    ).categories();

    expect(categories.first.description, 'Hot dogs, jamonadas y más');
    expect(
      categories.first.imageUrl,
      '/images/categories/c-1/0123456789abcdef.jpg',
    );
    expect(categories.last.description, isNull);
    expect(categories.last.imageUrl, isNull);
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

  test('con sesión, los productos van con el token: cada cliente ve su '
      'precio', () async {
    final sent = <http.BaseRequest>[];
    Future<http.Response> respond(http.Request request) async {
      sent.add(request);
      return request.url.path == '/products'
          ? json(200, {
              'data': [
                product(
                  promotion: {
                    'id': 'promo-vip',
                    'promoPrice': '7.9',
                    'startDate': '2026-10-04',
                    'endDate': '2026-11-02',
                    'title': 'Precio VIP',
                    'audience': 'vip',
                  },
                ),
              ],
              'meta': {'total': 1},
            })
          : json(200, product());
    }

    final vip = await repository(respond, token: 'token-ana').products();
    await repository(respond, token: 'token-ana').product('p-1');
    await repository(respond).products();

    expect(sent[0].headers['authorization'], 'Bearer token-ana');
    expect(sent[1].headers['authorization'], 'Bearer token-ana');
    expect(sent[2].headers, isNot(contains('authorization')));
    final oil = vip.items.single;
    expect(oil.vipPrice, isTrue);
    // Una de clientes elegidos también es un precio VIP.
    expect(
      Product.fromJson({
        'id': 'p-2',
        'name': 'Leche',
        'price': '4.2',
        'currentStock': 3,
        'promotion': {'promoPrice': '3.5', 'audience': 'selected'},
      }).vipPrice,
      isTrue,
    );
    expect(oil.finalPriceCents, 790);
  });

  /// Una de `promotions`, como la manda el servidor (`_offerJson`).
  Map<String, Object?> offer(
    String type,
    String label, {
    String audience = 'everyone',
    String? title,
    int? percent,
    int? buyQuantity,
    int? payQuantity,
    Map<String, Object?>? giftProduct,
    int? giftQuantity,
  }) => {
    'id': 'pr-$type',
    'type': type,
    'label': label,
    'audience': audience,
    'title': title,
    'startDate': '2026-10-01',
    'endDate': '2026-10-31',
    'promoPrice': null,
    'percent': percent,
    'buyQuantity': buyQuantity,
    'payQuantity': payQuantity,
    'giftProduct': giftProduct,
    'giftQuantity': giftQuantity,
  };

  test('lee unitPrice y las ofertas', () async {
    final page = await repository(
      (_) async => json(200, {
        'data': [
          {
            ...product(),
            'price': '4.5',
            'unitPrice': '3.6',
            'promotions': [
              offer('percentOff', '20 % menos', percent: 20),
              offer(
                'buyXPayY',
                '2x1',
                title: 'Semana del aceite',
                buyQuantity: 2,
                payQuantity: 1,
              ),
              offer('extraUnit', '2.ª al 30 %', buyQuantity: 2, percent: 30),
              offer(
                'gift',
                'Regalo: Sal 1 kg',
                buyQuantity: 2,
                giftProduct: {'id': 'sal', 'name': 'Sal 1 kg'},
                giftQuantity: 1,
              ),
            ],
          },
          // Solo un 2x1: el precio es el normal.
          {
            ...product(),
            'id': 'p-2',
            'unitPrice': '10.9',
            'promotions': [
              offer('buyXPayY', '3x2', buyQuantity: 3, payQuantity: 2),
            ],
          },
        ],
        'meta': {'total': 2},
      }),
    ).products();

    final [percent, onlyDeal] = page.items;
    expect((percent.finalPriceCents, percent.onSale), (360, true));
    expect(percent.vipPrice, isFalse);
    // El % va en el precio; las demás, como ofertas.
    expect(
      [for (final o in percent.offers) (o.type, o.label, o.title)],
      [
        ('buyXPayY', '2x1', 'Semana del aceite'),
        ('extraUnit', '2.ª al 30 %', null),
        ('gift', 'Regalo: Sal 1 kg', null),
      ],
    );
    expect(
      [for (final o in percent.offers) o.description],
      [
        '2x1 en este producto',
        'La 2.ª unidad con 30 % menos',
        'Regalo: Sal 1 kg por cada 2',
      ],
    );

    expect((onlyDeal.finalPriceCents, onlyDeal.onSale), (1090, false));
    expect([for (final o in onlyDeal.offers) o.label], ['3x2']);
  });

  test('un % solo para clientes VIP es precio VIP', () async {
    final page = await repository(
      (_) async => json(200, {
        'data': [
          {
            ...product(),
            'unitPrice': '9.81',
            'promotions': [
              offer('percentOff', '10 % menos', audience: 'vip', percent: 10),
            ],
          },
        ],
        'meta': {'total': 1},
      }),
    ).products();

    final vip = page.items.single;
    expect((vip.finalPriceCents, vip.vipPrice), (981, true));
    expect(vip.offers, isEmpty);
  });

  test('una promoción para todos no es VIP', () async {
    final page = await repository(
      (_) async => json(200, {
        'data': [
          product(
            promotion: {
              'id': 'promo-1',
              'promoPrice': '8.9',
              'startDate': '2026-10-04',
              'endDate': '2026-11-02',
              'title': null,
              'audience': 'everyone',
            },
          ),
        ],
        'meta': {'total': 1},
      }),
    ).products();

    expect(page.items.single.onSale, isTrue);
    expect(page.items.single.vipPrice, isFalse);
  });

  test('solo los productos en promoción: onSale=true', () async {
    late Uri url;
    await repository((request) async {
      url = request.url;
      return json(200, {
        'data': [],
        'meta': {'total': 0},
      });
    }).products(onSale: true);

    expect(url.queryParameters, {'page': '1', 'limit': '20', 'onSale': 'true'});
  });

  test('lo buscado va recortado, y en blanco no se manda', () async {
    final urls = <Uri>[];
    final repo = repository((request) async {
      urls.add(request.url);
      return json(200, {
        'data': [],
        'meta': {'total': 0},
      });
    });

    await repo.products(search: '  arroz  ');
    await repo.products(search: '   ');
    await repo.products(search: 'x' * 150);

    expect(urls[0].queryParameters['search'], 'arroz');
    expect(urls[1].queryParameters, isNot(contains('search')));
    expect(urls[2].queryParameters['search'], hasLength(100));
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
