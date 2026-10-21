import 'dart:convert';

import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/products/products_routes.dart';
import 'package:abarrotes_server/src/products/products_service.dart';
import 'package:abarrotes_server/src/promotions/promotion_rules.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promotions_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  final today = storeDay(testNow);

  withServerpod('Rutas de productos', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late Category abarrotes;
    late Category lacteos;
    late Product arroz;
    late Product aceite;

    Future<Product> insertProduct(
      String name,
      String sku,
      Category category, {
      bool active = true,
    }) => Product.db.insertRow(
      session,
      Product(
        name: name,
        sku: sku,
        priceCents: 450,
        categoryId: category.id!,
        active: active,
        currentStock: 10,
        minStock: 2,
      ),
    );

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        productsRoutes(
          ProductsService(pricing: testPromotions(), now: () => testNow),
          testVerifier(google),
          shoppers: testShoppers,
        ),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      await insertUser(session, 'uid-staff', UserRole.staff);
      await insertUser(session, 'uid-cliente', UserRole.customer);
      abarrotes = await Category.db.insertRow(
        session,
        Category(name: 'Abarrotes'),
      );
      lacteos = await Category.db.insertRow(session, Category(name: 'Lácteos'));
      arroz = await insertProduct('Arroz Costeño', 'DEMO-ARROZ', abarrotes);
      aceite = await insertProduct(
        'Aceite Primor',
        'DEMO-ACEITE',
        abarrotes,
        active: false,
      );
      await insertProduct('Leche Gloria', 'DEMO-LECHE', lacteos);
    });

    Future<Promotion> insertPromotion(
      Product product, {
      required String from,
      required String to,
      bool active = true,
      int promoPriceCents = 390,
      PromotionAudience audience = PromotionAudience.everyone,
    }) {
      final period = toStoredPeriod(from, to);
      return Promotion.db.insertRow(
        session,
        Promotion(
          productId: product.id!,
          promoPriceCents: promoPriceCents,
          startDate: period.startDate,
          endDate: period.endDate,
          active: active,
          audience: audience,
          title: audience == PromotionAudience.vip ? 'Solo VIP' : null,
        ),
      );
    }

    List<String> names(dynamic page) => [
      for (final product in page['data'] as List) product['name'] as String,
    ];

    group('GET /products (público)', () {
      test(
        'solo activos, por nombre, paginados y con la forma que lee la app',
        () async {
          final (status, body) = await client.get('/products?limit=1');

          expect(status, 200);
          expect(names(body), ['Arroz Costeño']);
          expect(body['meta'], {
            'total': 2,
            'page': 1,
            'limit': 1,
            'totalPages': 2,
          });
          expect(body['data'].single, {
            'id': arroz.id.toString(),
            'name': 'Arroz Costeño',
            'description': null,
            'sku': 'DEMO-ARROZ',
            'price': '4.5',
            'imageUrl': null,
            'active': true,
            'currentStock': 10,
            'minStock': 2,
            'expirationDate': null,
            'createdAt': isA<String>(),
            'categoryId': abarrotes.id.toString(),
            'category': {'id': abarrotes.id.toString(), 'name': 'Abarrotes'},
            'promotion': null,
          });
        },
      );

      test(
        'filtra por categoría y busca por nombre o SKU sin mayúsculas',
        () async {
          expect(
            names((await client.get('/products?categoryId=${lacteos.id}')).$2),
            ['Leche Gloria'],
          );
          expect(names((await client.get('/products?search=gloria')).$2), [
            'Leche Gloria',
          ]);
          expect(names((await client.get('/products?search=demo-arr')).$2), [
            'Arroz Costeño',
          ]);
          // % y _ se buscan literalmente.
          expect(names((await client.get('/products?search=%25')).$2), isEmpty);
        },
      );

      test('includeInactive solo tiene efecto para admin y staff', () async {
        const path = '/products?includeInactive=true';

        expect(names((await client.get(path)).$2), hasLength(2));
        expect(
          names((await client.get(path, as: 'uid-cliente')).$2),
          hasLength(2),
        );
        expect(names((await client.get(path, as: 'uid-staff')).$2), [
          'Aceite Primor',
          'Arroz Costeño',
          'Leche Gloria',
        ]);
      });

      test(
        'muestra la promoción vigente y onSale deja solo las ofertas',
        () async {
          final current = await insertPromotion(
            arroz,
            from: today,
            to: addDays(today, 6),
          );
          // Ni las futuras ni las apagadas cuentan.
          await insertPromotion(
            arroz,
            from: addDays(today, 10),
            to: addDays(today, 12),
          );
          final leche = (await Product.db.findFirstRow(
            session,
            where: (p) => p.sku.equals('DEMO-LECHE'),
          ))!;
          await insertPromotion(leche, from: today, to: today, active: false);

          final (_, body) = await client.get('/products');
          final byName = {
            for (final product in body['data'] as List)
              product['name']: product,
          };
          expect(byName['Arroz Costeño']['promotion'], {
            'id': current.id.toString(),
            'promoPrice': '3.9',
            'startDate': today,
            'endDate': addDays(today, 6),
            'title': null,
            'audience': 'everyone',
          });
          expect(byName['Leche Gloria']['promotion'], isNull);

          expect(names((await client.get('/products?onSale=true')).$2), [
            'Arroz Costeño',
          ]);
        },
      );

      test('query inválido o con propiedades extra es 400', () async {
        final (status, body) = await client.get(
          '/products?limit=500&categoryId=x&color=rojo',
        );

        expect(status, 400);
        expect(body['message'], [
          'La propiedad color no está permitida',
          'limit debe estar entre 1 y 100',
          'categoryId debe ser un UUID',
        ]);
      });
    });

    group('promociones según el cliente', () {
      late Product leche;
      late Promotion arrozVip;
      late Promotion lecheVip;

      setUp(() async {
        leche = (await Product.db.findFirstRow(
          session,
          where: (p) => p.sku.equals('DEMO-LECHE'),
        ))!;
        final week = addDays(today, 6);
        // Arroz: para todos a 3.9 y VIP a 3.5. Leche: para todos a 3.0 y una
        // VIP más cara (4.0), que no le conviene ni al VIP.
        await insertPromotion(arroz, from: today, to: week);
        arrozVip = await insertPromotion(
          arroz,
          from: today,
          to: week,
          promoPriceCents: 350,
          audience: PromotionAudience.vip,
        );
        await insertPromotion(
          leche,
          from: today,
          to: week,
          promoPriceCents: 300,
        );
        lecheVip = await insertPromotion(
          leche,
          from: today,
          to: week,
          promoPriceCents: 400,
          audience: PromotionAudience.vip,
        );
        final admin = await insertUser(session, 'uid-admin', UserRole.admin);
        await insertUser(session, 'uid-vip', UserRole.customer);
        await insertVips(session, admin, ['vip@tienda.pe']);
      });

      Map<String, dynamic> promotionsByName(dynamic page) => {
        for (final product in page['data'] as List)
          product['name'] as String: product['promotion'],
      };

      test('quien no es VIP ve la de todos y nada de la VIP', () async {
        for (final (status, body) in [
          await client.get('/products'),
          await client.get('/products', as: 'uid-cliente'),
          // VIP sin el correo verificado.
          await client.get(
            '/products',
            as: 'uid-vip',
            email: 'vip@tienda.pe',
            emailVerified: false,
          ),
        ]) {
          expect(status, 200);
          final promotions = promotionsByName(body);
          expect(promotions['Arroz Costeño']['promoPrice'], '3.9');
          expect(promotions['Leche Gloria']['promoPrice'], '3');
          final json = jsonEncode(body);
          expect(json, isNot(contains(arrozVip.id.toString())));
          expect(json, isNot(contains('vip')));
        }
      });

      test('un VIP ve la más barata de las que puede usar', () async {
        final (status, body) = await client.get(
          '/products',
          as: 'uid-vip',
          email: 'vip@tienda.pe',
        );

        expect(status, 200);
        final promotions = promotionsByName(body);
        expect(promotions['Arroz Costeño'], {
          'id': arrozVip.id.toString(),
          'promoPrice': '3.5',
          'startDate': today,
          'endDate': addDays(today, 6),
          'title': 'Solo VIP',
          'audience': 'vip',
        });
        expect(promotions['Leche Gloria']['promoPrice'], '3');
        expect(promotions['Leche Gloria']['audience'], 'everyone');

        final (_, one) = await client.get(
          '/products/${arroz.id}',
          as: 'uid-vip',
          email: 'vip@tienda.pe',
        );
        expect(one['promotion']['promoPrice'], '3.5');
        final (_, anonymous) = await client.get('/products/${arroz.id}');
        expect(anonymous['promotion']['promoPrice'], '3.9');
      });

      test(
        'onSale cuenta solo las promociones que el cliente puede usar',
        () async {
          // Sin la de todos, la leche solo tiene la VIP.
          await Promotion.db.deleteWhere(
            session,
            where: (p) =>
                p.productId.equals(leche.id) &
                p.audience.equals(PromotionAudience.everyone),
          );

          final (_, anonymous) = await client.get('/products?onSale=true');
          final (_, vip) = await client.get(
            '/products?onSale=true',
            as: 'uid-vip',
            email: 'vip@tienda.pe',
          );

          expect(names(anonymous), ['Arroz Costeño']);
          expect(anonymous['meta']['total'], 1);
          expect(names(vip), ['Arroz Costeño', 'Leche Gloria']);
          expect(
            promotionsByName(vip)['Leche Gloria']['id'],
            lecheVip.id.toString(),
          );
        },
      );
    });

    group('GET /products/:id (público)', () {
      test('un producto activo se ve sin token', () async {
        final (status, body) = await client.get('/products/${arroz.id}');

        expect((status, body['sku']), (200, 'DEMO-ARROZ'));
      });

      test('uno inactivo es 404 salvo para admin y staff', () async {
        final path = '/products/${aceite.id}';

        expect((await client.get(path)).$1, 404);
        expect((await client.get(path, as: 'uid-cliente')).$1, 404);
        expect((await client.get(path, as: 'uid-staff')).$1, 200);
      });
    });

    group('escritura (admin y staff)', () {
      final nuevo = {
        'name': '  Azúcar Rubia  ',
        'sku': 'AZUCAR-1',
        'price': 3.2,
        'categoryId': null,
      };

      Future<ApiResult> create(Map<String, Object?> changes) =>
          client.post('/products', {
            ...nuevo,
            'categoryId': abarrotes.id.toString(),
            ...changes,
          }, as: 'uid-staff');

      test('POST crea con valores por defecto (activo, stock 0)', () async {
        final (status, body) = await create({
          'expirationDate': '2027-03-31',
          'imageUrl': 'https://cdn.tienda.pe/azucar.png',
        });

        expect(status, 201);
        expect(body['name'], 'Azúcar Rubia');
        expect(body['price'], '3.2');
        expect(body['active'], isTrue);
        expect(body['currentStock'], 0);
        expect(body['expirationDate'], '2027-03-31T00:00:00.000Z');
        expect(body['category']['name'], 'Abarrotes');
      });

      test('un cliente recibe 403 y sin token, 401', () async {
        expect(
          (await client.post('/products', nuevo, as: 'uid-cliente')).$1,
          403,
        );
        expect((await client.post('/products', nuevo)).$1, 401);
      });

      test('SKU repetido es 409 y categoría inexistente, 400', () async {
        final duplicated = await create({'sku': 'DEMO-ARROZ'});
        final noCategory = await create({
          'categoryId': '0199a000-0000-7000-8000-000000000000',
        });

        expect(duplicated.$1, 409);
        expect(
          duplicated.$2['message'],
          'Ya existe un producto con el SKU DEMO-ARROZ',
        );
        expect(noCategory.$2['message'], 'La categoría indicada no existe');
      });

      test('valida el body: decimales, URL, stock y obligatorios', () async {
        final (status, body) = await client.post('/products', {
          'price': 3.255,
          'imageUrl': 'azucar.png',
          'currentStock': -1,
        }, as: 'uid-staff');

        expect(status, 400);
        expect(body['message'], [
          'name es obligatorio',
          'sku es obligatorio',
          'price debe ser un número con 2 decimales como máximo',
          'imageUrl debe ser una URL http(s)',
          'currentStock debe ser mayor o igual a 0',
          'categoryId es obligatorio',
        ]);
      });

      test(
        'PATCH cambia solo lo que llega y null borra campos opcionales',
        () async {
          await Product.db.updateRow(
            session,
            arroz.copyWith(description: 'Grano largo'),
          );

          final (status, body) = await client.patch('/products/${arroz.id}', {
            'price': 4.8,
            'description': null,
            'categoryId': lacteos.id.toString(),
          }, as: 'uid-staff');

          expect(status, 200);
          expect(body['price'], '4.8');
          expect(body['description'], isNull);
          expect(body['category']['name'], 'Lácteos');
          expect(body['name'], 'Arroz Costeño');
          expect(body['currentStock'], 10);
        },
      );

      test('PATCH no edita el stock (eso es de inventory)', () async {
        final (status, body) = await client.patch('/products/${arroz.id}', {
          'currentStock': 99,
        }, as: 'uid-staff');

        expect(status, 400);
        expect(body['message'], [
          'La propiedad currentStock no está permitida',
        ]);
      });

      test(
        'PATCH a un SKU ajeno es 409 y a un producto inexistente, 404',
        () async {
          expect(
            (await client.patch('/products/${arroz.id}', {
              'sku': 'DEMO-LECHE',
            }, as: 'uid-staff')).$1,
            409,
          );
          expect(
            (await client.patch(
              '/products/0199a000-0000-7000-8000-000000000000',
              {'name': 'X'},
              as: 'uid-staff',
            )).$1,
            404,
          );
        },
      );

      test(
        'DELETE desactiva el producto (baja lógica) y lo devuelve',
        () async {
          final (status, body) = await client.delete(
            '/products/${arroz.id}',
            as: 'uid-staff',
          );

          expect((status, body['active']), (200, false));
          expect((await client.get('/products/${arroz.id}')).$1, 404);
          expect(await Product.db.count(session), 3);
        },
      );
    });
  });
}
