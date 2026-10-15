import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/store/store_routes.dart';
import 'package:abarrotes_server/src/store/store_settings_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/staff_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Datos de la tienda', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late User admin;

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        storeRoutes(const StoreSettingsService(), testGuards(google)),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      admin = await insertStaff(session, 'uid-admin');
      await insertStaff(
        session,
        'uid-encargada',
        permissions: {Permission.storeManage},
      );
      await insertStaff(session, 'uid-cajera', roleName: 'Cajera');
      await insertUser(session, 'uid-cliente');
    });

    const store = {
      'name': "Neil's Food Services",
      'address': 'Av. Arequipa 1234, Lince',
      'reference': 'Frente al parque',
      'phone': '987654321',
      'openingHours': 'Lun a sáb de 8 a 20 h',
      'pickupInstructions': 'Muestra tu código en caja.',
    };

    test('sin cargar todavía, el GET público da los de por defecto', () async {
      final (status, body) = await client.get('/store');

      expect(status, 200);
      expect(body, {
        'name': "Neil's Food Services",
        'address': '',
        'reference': null,
        'phone': null,
        'openingHours': null,
        'pickupInstructions': null,
        'updatedAt': null,
      });
      expect(await StoreSettings.db.count(session), 0);
    });

    test(
      'con store.manage se cargan y después se editan: una sola fila',
      () async {
        final (created, first) = await client.patch(
          '/store',
          store,
          as: 'uid-encargada',
        );
        expect(created, 200);
        expect(first, {...store, 'updatedAt': isA<String>()});

        final (edited, second) = await client.patch('/store', {
          'openingHours': 'Todos los días de 7 a 22 h',
          'reference': null,
        }, as: 'uid-admin');
        expect(edited, 200);
        expect(second['openingHours'], 'Todos los días de 7 a 22 h');
        expect(second['reference'], isNull);
        expect(second['address'], store['address']);

        final rows = await StoreSettings.db.find(session);
        expect(rows, hasLength(1));
        expect(rows.single.updatedByUserId, admin.id);
        final (_, public) = await client.get('/store');
        expect(public['openingHours'], 'Todos los días de 7 a 22 h');
      },
    );

    test('nombre y dirección no quedan vacíos; el resto se valida', () async {
      // La primera vez falta la dirección.
      final (status, error) = await client.patch('/store', {
        'phone': '987654321',
      }, as: 'uid-admin');
      expect(
        (status, error['message']),
        (
          400,
          'Falta la dirección de la tienda',
        ),
      );

      final (_, invalid) = await client.patch('/store', {
        'name': '',
        'address': null,
        'phone': '9' * 31,
        'color': 'rojo',
      }, as: 'uid-admin');
      expect(invalid['message'], [
        'La propiedad color no está permitida',
        'name debe ser un texto no vacío',
        'address no puede ser null',
        'phone admite como máximo 30 caracteres',
      ]);
      expect(await StoreSettings.db.count(session), 0);
    });

    test('editar pide store.manage; ver no pide nada', () async {
      expect((await client.patch('/store', store)).$1, 401);
      expect(
        (await client.patch('/store', store, as: 'uid-cliente')).$1,
        403,
      );
      expect((await client.patch('/store', store, as: 'uid-cajera')).$1, 403);
      expect((await client.get('/store', as: 'uid-cliente')).$1, 200);
    });
  });
}
