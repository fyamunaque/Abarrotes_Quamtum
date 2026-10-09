import 'package:abarrotes_server/src/categories/categories_routes.dart';
import 'package:abarrotes_server/src/categories/categories_service.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
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
        categoriesRoutes(const CategoriesService(), testVerifier(google)),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      await insertUser(session, 'uid-staff', UserRole.staff);
      await insertUser(session, 'uid-cliente', UserRole.customer);
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
        expect(body.first.keys, ['id', 'name']);
      });

      test('GET /categories/:id devuelve la categoría', () async {
        final category = await insertCategory('Bebidas');

        final (status, body) = await client.get('/categories/${category.id}');

        expect(status, 200);
        expect(body, {'id': category.id.toString(), 'name': 'Bebidas'});
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
  });
}
