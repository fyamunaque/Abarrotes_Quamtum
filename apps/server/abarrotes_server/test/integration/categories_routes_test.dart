import 'package:abarrotes_server/src/categories/categories_routes.dart';
import 'package:abarrotes_server/src/categories/categories_service.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:image/image.dart' as img;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/staff_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Rutas de categorías', (sessionBuilder, _) {
    late Session session;
    late TestClient client;

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        categoriesRoutes(CategoriesService(), testGuards(google)),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      await insertStaff(session, 'uid-staff');
      await insertUser(session, 'uid-cliente');
    });

    Future<Category> insertCategory(String name) =>
        Category.db.insertRow(session, Category(name: name));

    Future<void> insertProduct(Category category) => Product.db.insertRow(
      session,
      Product(
        name: 'Arroz',
        sku: 'ARROZ-1',
        priceCents: 450,
        categoryId: category.id!,
        active: false,
      ),
    );

    group('lectura pública', () {
      test('GET /categories lista por nombre sin token', () async {
        await insertCategory('Lácteos');
        await insertCategory('Abarrotes');

        final (status, body) = await client.get('/categories');

        expect(status, 200);
        expect((body as List).map((c) => c['name']), ['Abarrotes', 'Lácteos']);
        expect(body.first.keys, ['id', 'name', 'description', 'imageUrl']);
      });

      test('GET /categories/:id devuelve la categoría', () async {
        final category = await insertCategory('Bebidas');

        final (status, body) = await client.get('/categories/${category.id}');

        expect(status, 200);
        expect(body, {
          'id': category.id.toString(),
          'name': 'Bebidas',
          'description': null,
          'imageUrl': null,
        });
      });

      test('un id inexistente es 404 y uno mal formado, 400', () async {
        expect(
          (await client.get(
            '/categories/0199a000-0000-7000-8000-000000000000',
          )).$1,
          404,
        );
        expect((await client.get('/categories/123')).$1, 400);
      });
    });

    group('escritura (admin y staff)', () {
      test('POST crea la categoría sin espacios alrededor', () async {
        final (status, body) = await client.post('/categories', {
          'name': '  Limpieza  ',
        }, as: 'uid-staff');

        expect(status, 201);
        expect(body['name'], 'Limpieza');
        expect(await Category.db.count(session), 1);
      });

      test('un cliente recibe 403 y sin token, 401', () async {
        expect(
          (await client.post('/categories', {
            'name': 'X',
          }, as: 'uid-cliente')).$1,
          403,
        );
        expect((await client.post('/categories', {'name': 'X'})).$1, 401);
        expect(await Category.db.count(session), 0);
      });

      test('un nombre repetido, sin distinguir mayúsculas, es 409', () async {
        await insertCategory('Bebidas');

        final (status, body) = await client.post('/categories', {
          'name': 'BEBIDAS',
        }, as: 'uid-staff');

        expect(status, 409);
        expect(body['message'], 'Ya existe la categoría "Bebidas"');
      });

      test('valida el body y junta los errores', () async {
        final (status, body) = await client.post('/categories', {
          'name': '',
          'color': 'rojo',
        }, as: 'uid-staff');

        expect(status, 400);
        expect(body['message'], [
          'La propiedad color no está permitida',
          'name debe ser un texto no vacío',
        ]);
      });

      test(
        'PATCH renombra, y cambiar solo mayúsculas no choca consigo misma',
        () async {
          final category = await insertCategory('bebidas');

          final (status, body) = await client.patch(
            '/categories/${category.id}',
            {'name': 'Bebidas'},
            as: 'uid-staff',
          );

          expect((status, body['name']), (200, 'Bebidas'));
        },
      );

      test('PATCH al nombre de otra categoría es 409', () async {
        await insertCategory('Bebidas');
        final other = await insertCategory('Gaseosas');

        expect(
          (await client.patch('/categories/${other.id}', {
            'name': 'bebidas',
          }, as: 'uid-staff')).$1,
          409,
        );
      });

      test(
        'GET /categories/summary cuenta los productos de cada una, también '
        'los inactivos',
        () async {
          final embutidos = await insertCategory('Embutidos');
          await insertCategory('Lácteos');
          await insertProduct(embutidos);

          final (status, body) = await client.get(
            '/categories/summary',
            as: 'uid-staff',
          );

          expect(status, 200);
          expect(
            [
              for (final row in body as List)
                (row['name'], row['productCount']),
            ],
            [('Embutidos', 1), ('Lácteos', 0)],
          );
          expect(
            (body.first as Map).keys,
            ['id', 'name', 'description', 'imageUrl', 'productCount'],
          );
        },
      );

      test('GET /categories/summary sin categories.manage es 403', () async {
        final (status, _) = await client.get(
          '/categories/summary',
          as: 'uid-cliente',
        );

        expect(status, 403);
      });

      test('DELETE borra una categoría vacía (204)', () async {
        final category = await insertCategory('Temporal');

        expect(
          await client.delete('/categories/${category.id}', as: 'uid-staff'),
          (204, null),
        );
        expect(await Category.db.count(session), 0);
      });

      test(
        'DELETE de una categoría con productos (aunque inactivos) es 409',
        () async {
          final category = await insertCategory('Abarrotes');
          await insertProduct(category);

          final (status, body) = await client.delete(
            '/categories/${category.id}',
            as: 'uid-staff',
          );

          expect(status, 409);
          expect(
            body['message'],
            'La categoría tiene 1 producto: muévelos a otra antes de eliminarla',
          );
        },
      );

      test('PATCH y DELETE de una categoría inexistente son 404', () async {
        const missing = '/categories/0199a000-0000-7000-8000-000000000000';

        expect(
          (await client.patch(missing, {'name': 'X'}, as: 'uid-staff')).$1,
          404,
        );
        expect((await client.delete(missing, as: 'uid-staff')).$1, 404);
      });
    });

    group('foto y descripción', () {
      test('crea con descripción y la devuelve', () async {
        final (status, body) = await client.post('/categories', {
          'name': 'Embutidos',
          'description': 'Hot dogs, jamonadas y más',
        }, as: 'uid-staff');

        expect(status, 201);
        expect(body['description'], 'Hot dogs, jamonadas y más');
        expect(body['imageUrl'], isNull);
      });

      test('la descripción tiene hasta 80 caracteres', () async {
        final (status, body) = await client.post('/categories', {
          'name': 'Embutidos',
          'description': 'x' * 81,
        }, as: 'uid-staff');

        expect(status, 400);
        expect(body['message'], [
          'description admite como máximo 80 caracteres',
        ]);
        expect(await Category.db.count(session), 0);
      });

      test('PATCH cambia la descripción y vacía o null la borra', () async {
        final category = await insertCategory('Lácteos');
        final path = '/categories/${category.id}';

        final (_, changed) = await client.patch(path, {
          'description': 'Leches, yogures y derivados',
        }, as: 'uid-staff');
        expect(changed['description'], 'Leches, yogures y derivados');
        expect(changed['name'], 'Lácteos');

        final (_, emptied) = await client.patch(path, {
          'description': '',
        }, as: 'uid-staff');
        expect(emptied['description'], isNull);

        await client.patch(path, {'description': 'Otra'}, as: 'uid-staff');
        final (_, nulled) = await client.patch(path, {
          'description': null,
        }, as: 'uid-staff');
        expect(nulled['description'], isNull);
      });

      // Una foto ancha, más grande que lo que se guarda.
      final photo = img.encodePng(
        img.Image(width: 2000, height: 1000)..clear(img.ColorRgb8(200, 40, 30)),
      );

      Future<String> upload(Category category) async {
        final (status, body) = await client.putBytes(
          '/categories/${category.id}/image',
          photo,
          as: 'uid-staff',
        );
        expect(status, 200);
        return body['imageUrl'] as String;
      }

      test('sube una foto y la sirve', () async {
        final category = await insertCategory('Embutidos');

        final url = await upload(category);

        expect(url, startsWith('/images/categories/${category.id}/'));
        expect(
          (await client.get('/categories/${category.id}')).$2['imageUrl'],
          url,
        );
        final response = await client.getRaw(url);
        expect(response.statusCode, 200);
        expect(response.headers['content-type'], startsWith('image/jpeg'));
        expect(
          response.headers['cache-control'],
          'public, max-age=31536000, immutable',
        );
        final served = img.decodeJpg(response.bodyBytes)!;
        expect((served.width, served.height), (1200, 600));
      });

      test('reemplazar la foto borra la anterior', () async {
        final category = await insertCategory('Embutidos');

        final first = await upload(category);
        final second = await upload(category);

        expect(second, isNot(first));
        expect((await client.getRaw(first)).statusCode, 404);
        expect((await client.getRaw(second)).statusCode, 200);
      });

      test('borrar la categoría borra su foto', () async {
        final category = await insertCategory('Embutidos');
        final url = await upload(category);

        final (status, _) = await client.delete(
          '/categories/${category.id}',
          as: 'uid-staff',
        );

        expect(status, 204);
        expect((await client.getRaw(url)).statusCode, 404);
      });

      test('DELETE de la foto la quita y la borra', () async {
        final category = await insertCategory('Embutidos');
        final url = await upload(category);

        final (status, body) = await client.delete(
          '/categories/${category.id}/image',
          as: 'uid-staff',
        );

        expect(status, 200);
        expect(body['imageUrl'], isNull);
        expect(
          (await client.get('/categories/${category.id}')).$2['imageUrl'],
          isNull,
        );
        expect((await client.getRaw(url)).statusCode, 404);
      });

      test('quitar la foto de una categoría sin foto no cambia nada', () async {
        final category = await insertCategory('Embutidos');

        final (status, body) = await client.delete(
          '/categories/${category.id}/image',
          as: 'uid-staff',
        );

        expect(status, 200);
        expect(body['name'], 'Embutidos');
        expect(body['imageUrl'], isNull);
      });

      test('quitar la foto sin categories.manage es 403', () async {
        final category = await insertCategory('Embutidos');
        await upload(category);

        final (status, _) = await client.delete(
          '/categories/${category.id}/image',
          as: 'uid-cliente',
        );

        expect(status, 403);
      });

      test('lo que no es una imagen es 400', () async {
        final category = await insertCategory('Embutidos');

        final (status, body) = await client.putBytes(
          '/categories/${category.id}/image',
          List.filled(500, 7),
          as: 'uid-staff',
        );

        expect(status, 400);
        expect(
          body['message'],
          'La foto tiene que ser una imagen JPEG, PNG o WebP',
        );
      });

      test('sin categories.manage es 403', () async {
        final category = await insertCategory('Embutidos');

        final (status, _) = await client.putBytes(
          '/categories/${category.id}/image',
          photo,
          as: 'uid-cliente',
        );

        expect(status, 403);
      });

      test('una foto que no existe es 404', () async {
        final category = await insertCategory('Embutidos');

        final response = await client.getRaw(
          '/images/categories/${category.id}/0123456789abcdef.jpg',
        );

        expect(response.statusCode, 404);
      });

      group('la foto desde una URL', () {
        const external = 'https://cdn.tienda.pe/embutidos.jpg';

        test('POST crea con la URL de una imagen', () async {
          final (status, body) = await client.post('/categories', {
            'name': 'Embutidos',
            'imageUrl': external,
          }, as: 'uid-staff');

          expect(status, 201);
          expect(body['imageUrl'], external);
          final saved = await Category.db.findFirstRow(session);
          expect(saved!.imageUrl, external);
        });

        test(
          'tiene que ser una URL http(s), de hasta 2000 caracteres',
          () async {
            for (final (url, message) in [
              ('embutidos.jpg', 'imageUrl debe ser una URL http(s)'),
              (
                'ftp://cdn.tienda.pe/a.jpg',
                'imageUrl debe ser una URL http(s)',
              ),
              (
                'https://cdn.tienda.pe/${'a' * 2000}.jpg',
                'imageUrl admite como máximo 2000 caracteres',
              ),
            ]) {
              final (status, body) = await client.post('/categories', {
                'name': 'Embutidos',
                'imageUrl': url,
              }, as: 'uid-staff');

              expect(status, 400, reason: url);
              expect(body['message'], [message], reason: url);
            }
            expect(await Category.db.count(session), 0);
          },
        );

        test('POST no acepta la ruta de una foto subida', () async {
          final (status, body) = await client.post('/categories', {
            'name': 'Embutidos',
            'imageUrl': '/images/categories/otra/0123456789abcdef.jpg',
          }, as: 'uid-staff');

          expect(status, 400);
          expect('$body', contains('se sube después'));
          expect(await Category.db.count(session), 0);
        });

        test('PATCH a una URL externa o a null borra la subida', () async {
          final category = await insertCategory('Embutidos');
          final path = '/categories/${category.id}';
          final uploaded = await upload(category);

          final (status, body) = await client.patch(path, {
            'imageUrl': external,
          }, as: 'uid-staff');
          expect((status, body['imageUrl']), (200, external));
          expect((await client.getRaw(uploaded)).statusCode, 404);

          final again = await upload(category);
          final (cleared, clearedBody) = await client.patch(path, {
            'imageUrl': null,
          }, as: 'uid-staff');
          expect((cleared, clearedBody['imageUrl']), (200, null));
          expect((await client.getRaw(again)).statusCode, 404);
        });

        test('PATCH puede reenviar la foto que tiene, pero no otra', () async {
          final category = await insertCategory('Embutidos');
          final path = '/categories/${category.id}';
          final url = await upload(category);

          final (same, sameBody) = await client.patch(path, {
            'name': 'Embutidos y fiambres',
            'imageUrl': url,
          }, as: 'uid-staff');
          expect((same, sameBody['imageUrl']), (200, url));
          expect(sameBody['name'], 'Embutidos y fiambres');
          expect((await client.getRaw(url)).statusCode, 200);

          final (other, otherBody) = await client.patch(path, {
            'imageUrl':
                '/images/categories/${category.id}/0123456789abcdef.jpg',
          }, as: 'uid-staff');
          expect(other, 400);
          expect('$otherBody', contains('súbela'));
          expect(
            (await Category.db.findById(session, category.id!))!.imageUrl,
            url,
          );
        });

        test('PATCH sin imageUrl no toca la foto', () async {
          final category = await insertCategory('Embutidos');
          final url = await upload(category);

          final (status, body) = await client.patch(
            '/categories/${category.id}',
            {'description': 'Hot dogs y jamonadas'},
            as: 'uid-staff',
          );

          expect((status, body['imageUrl']), (200, url));
          expect((await client.getRaw(url)).statusCode, 200);
        });
      });
    });
  });
}
