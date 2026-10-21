// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:abarrotes_server/src/auth/firebase_identity.dart';
import 'package:abarrotes_server/src/auth/guards.dart';
import 'package:abarrotes_server/src/common/api_route.dart';
import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/inventory/inventory_routes.dart';
import 'package:abarrotes_server/src/inventory/inventory_service.dart';
import 'package:abarrotes_server/src/inventory/stock_alerts.dart';
import 'package:abarrotes_server/src/orders/orders_routes.dart';
import 'package:abarrotes_server/src/orders/orders_service.dart';
import 'package:abarrotes_server/src/products/products_routes.dart';
import 'package:abarrotes_server/src/products/products_service.dart';
import 'package:abarrotes_server/src/staff/db_authorization_service.dart';
import 'package:abarrotes_server/src/staff/staff_bootstrap.dart';
import 'package:abarrotes_server/src/users/users_routes.dart';
import 'package:abarrotes_server/src/users/users_service.dart';
import 'package:serverpod/serverpod.dart' hide Order;
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promotions_setup.dart';
import '../support/staff_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Permisos del personal', (sessionBuilder, _) {
    late Session session;

    setUp(() => session = sessionBuilder.build());

    FirebaseIdentity identity(String email, {bool verified = true}) =>
        FirebaseIdentity(uid: 'uid', email: email, emailVerified: verified);

    group('los roles iniciales', () {
      test(
        'Administrador de sistema y las plantillas Almacenero y Cajera',
        () async {
          final admin = await roleNamed(session, administratorRoleName);
          final almacenero = await roleNamed(session, 'Almacenero');
          final cajera = await roleNamed(session, 'Cajera');

          expect(admin.isSystem, isTrue);
          expect(almacenero.isSystem, isFalse);
          expect(almacenero.permissions.toSet(), {
            Permission.productsView,
            Permission.inventoryView,
            Permission.inventoryAdjust,
            Permission.statsView,
          });
          expect(cajera.permissions.toSet(), {
            Permission.productsView,
            Permission.ordersView,
            Permission.ordersUpdateStatus,
            Permission.customersView,
          });
        },
      );

      test('ensureRoles no duplica nada', () async {
        await const StaffBootstrap().ensureRoles(session);
        final count = await Role.db.count(session);

        await const StaffBootstrap().ensureRoles(session);

        expect(await Role.db.count(session), count);
      });
    });

    group('DbAuthorizationService', () {
      const authorization = DbAuthorizationService();

      test('el Administrador tiene todos los permisos', () async {
        await insertStaff(session, 'uid-ana');

        final access = await authorization.accessOf(
          session,
          identity('UID-ANA@tienda.pe'),
        );

        expect(access.roleName, administratorRoleName);
        expect(access.permissions, Permission.values.toSet());
      });

      test('sin ser del personal o sin verificar el correo, nada', () async {
        await insertStaff(session, 'uid-ana');

        final stranger = await authorization.accessOf(
          session,
          identity('luis@tienda.pe'),
        );
        final unverified = await authorization.accessOf(
          session,
          identity('uid-ana@tienda.pe', verified: false),
        );

        expect(stranger.isStaff, isFalse);
        expect(stranger.permissions, isEmpty);
        expect(unverified.permissions, isEmpty);
      });

      test(
        'dado de baja o con el rol inactivo, nada: rige en el momento',
        () async {
          await insertStaff(
            session,
            'uid-ana',
            permissions: {Permission.ordersView},
          );
          final ana = identity('uid-ana@tienda.pe');
          expect(
            await authorization.hasPermission(
              session,
              ana,
              Permission.ordersView,
            ),
            isTrue,
          );

          final role = (await Role.db.findFirstRow(
            session,
            where: (role) => role.name.equals('Rol de uid-ana'),
          ))!;
          await Role.db.updateRow(session, role.copyWith(active: false));
          expect(
            await authorization.hasPermission(
              session,
              ana,
              Permission.ordersView,
            ),
            isFalse,
          );

          await Role.db.updateRow(session, role.copyWith(active: true));
          await StaffMember.db.updateWhere(
            session,
            columnValues: (member) => [member.active(false)],
            where: (member) => member.email.equals('uid-ana@tienda.pe'),
          );
          expect(
            await authorization.hasPermission(
              session,
              ana,
              Permission.ordersView,
            ),
            isFalse,
          );
        },
      );
    });

    group('RequirePermission', () {
      late TestClient client;

      setUp(() async {
        final guards = testGuards(google);
        final server = await serveRoutes(() => session, [
          (
            '/secreto',
            guards.require(
              Permission.statsView,
              ApiRoute(Method.get, (session, request) async {
                return jsonResponse(200, {
                  'user': request.currentUser.firebaseUid,
                  'role': request.staffAccess.roleName,
                });
              }),
            ),
          ),
        ]);
        client = TestClient(server, google);
        addTearDown(server.close);
      });

      test('sin token 401; sin cuenta o sin el permiso, 403', () async {
        await insertUser(session, 'uid-cliente');
        await insertStaff(session, 'uid-cajera', roleName: 'Cajera');

        expect((await client.get('/secreto')).$1, 401);
        expect((await client.get('/secreto', as: 'uid-nadie')).$1, 403);
        expect((await client.get('/secreto', as: 'uid-cliente')).$1, 403);
        expect((await client.get('/secreto', as: 'uid-cajera')).$1, 403);
        expect(
          (await client.get(
            '/secreto',
            as: 'uid-cajera',
            emailVerified: false,
          )).$1,
          403,
        );
      });

      test('con el permiso deja pasar, con el usuario y su acceso', () async {
        await insertStaff(session, 'uid-almacen', roleName: 'Almacenero');

        final (status, body) = await client.get('/secreto', as: 'uid-almacen');

        expect(status, 200);
        expect(body, {'user': 'uid-almacen', 'role': 'Almacenero'});
      });
    });

    group('cada rol, sus rutas', () {
      late TestClient client;
      late Product rice;
      late Order order;

      setUp(() async {
        final guards = testGuards(google);
        final server = await serveRoutes(() => session, [
          ...inventoryRoutes(
            const InventoryService(),
            StockAlerts(now: () => testNow),
            guards,
          ),
          ...ordersRoutes(
            OrdersService(pricing: testPromotions(), now: () => testNow),
            guards,
            shoppers: testShoppers,
          ),
          ...productsRoutes(
            ProductsService(pricing: testPromotions(), now: () => testNow),
            guards,
            shoppers: testShoppers,
          ),
          ...usersRoutes(const UsersService(), guards, shoppers: testShoppers),
        ]);
        client = TestClient(server, google);
        addTearDown(server.close);

        await insertStaff(session, 'uid-almacen', roleName: 'Almacenero');
        await insertStaff(session, 'uid-cajera', roleName: 'Cajera');
        await insertStaff(
          session,
          'uid-ver',
          permissions: {Permission.ordersView},
        );
        final customer = await insertUser(session, 'uid-cliente');
        final category = await Category.db.insertRow(
          session,
          Category(name: 'Abarrotes'),
        );
        rice = await Product.db.insertRow(
          session,
          Product(
            name: 'Arroz',
            sku: 'ARROZ',
            priceCents: 450,
            currentStock: 10,
            categoryId: category.id!,
          ),
        );
        await Product.db.insertRow(
          session,
          Product(
            name: 'Aceite de baja',
            sku: 'ACEITE',
            priceCents: 900,
            active: false,
            categoryId: category.id!,
          ),
        );
        order = await Order.db.insertRow(
          session,
          Order(
            status: OrderStatus.pendingConfirmation,
            totalCents: 450,
            deliveryAddress: 'Av. Arequipa 123',
            customerId: customer.id!,
          ),
        );
        await OrderItem.db.insertRow(
          session,
          OrderItem(
            orderId: order.id!,
            productId: rice.id!,
            quantity: 1,
            unitPriceCents: 450,
          ),
        );
      });

      Future<int> adjust(String as, {bool emailVerified = true}) async =>
          (await client.post(
            '/inventory/movements',
            {
              'productId': rice.id.toString(),
              'type': 'incoming',
              'quantity': 5,
            },
            as: as,
            emailVerified: emailVerified,
          )).$1;

      Future<int> confirm(String as) async => (await client.patch(
        '/orders/${order.id}/status',
        {'status': 'confirmed'},
        as: as,
      )).$1;

      test(
        'el Almacenero ajusta el inventario, pero no toca pedidos',
        () async {
          expect(await adjust('uid-almacen'), 201);
          expect((await client.get('/orders', as: 'uid-almacen')).$1, 403);
          expect(await confirm('uid-almacen'), 403);
        },
      );

      test('la Cajera confirma pedidos, pero no ve el inventario', () async {
        expect(await confirm('uid-cajera'), 200);
        expect(
          (await client.get('/inventory/movements', as: 'uid-cajera')).$1,
          403,
        );
      });

      test('una Cajera recibe 403 en inventory.adjust', () async {
        final (status, body) = await client.post('/inventory/movements', {
          'productId': rice.id.toString(),
          'type': 'incoming',
          'quantity': 5,
        }, as: 'uid-cajera');

        expect(status, 403);
        expect(body['message'], 'Tu rol no tiene permiso para esta acción');
        expect(
          (await Product.db.findById(session, rice.id!))!.currentStock,
          10,
        );
        expect(await InventoryMovement.db.count(session), 0);
      });

      test(
        'un correo sin verificar no obtiene permisos de personal',
        () async {
          await insertStaff(session, 'uid-admin');

          // Ni el Administrador ni la Cajera: con el correo sin verificar son
          // como un cliente.
          for (final as in ['uid-admin', 'uid-cajera']) {
            expect(await adjust(as, emailVerified: false), 403);
            expect(
              (await client.get('/orders', as: as, emailVerified: false)).$1,
              403,
            );
            expect(
              (await client.get(
                '/customers',
                as: as,
                emailVerified: false,
              )).$1,
              403,
            );
            final (_, products) = await client.get(
              '/products?includeInactive=true',
              as: as,
              emailVerified: false,
            );
            expect(products['data'], hasLength(1));
          }
          expect(await InventoryMovement.db.count(session), 0);

          // Con el correo verificado, el mismo rol vuelve a valer.
          expect(await adjust('uid-admin'), 201);
          expect((await client.get('/orders', as: 'uid-cajera')).$1, 200);
        },
      );

      test('el listado de clientes, solo con customers.view', () async {
        final (status, found) = await client.get(
          '/customers?search=CLIENTE',
          as: 'uid-cajera',
        );

        expect(status, 200);
        expect(found['data'], [
          {
            'id': isA<String>(),
            'name': 'Usuario uid-cliente',
            'email': 'uid-cliente@tienda.pe',
            'phone': null,
            'address': null,
            'emailVerified': false,
            'createdAt': isA<String>(),
          },
        ]);
        expect(found['meta']['total'], 1);
        expect((await client.get('/customers', as: 'uid-almacen')).$1, 403);
        expect((await client.get('/customers', as: 'uid-ver')).$1, 403);
        expect((await client.get('/customers', as: 'uid-cliente')).$1, 403);
        expect((await client.get('/customers')).$1, 401);
      });

      test('el listado de clientes va por nombre y por páginas', () async {
        Future<List<String>> names(String query) async => [
          for (final customer
              in (await client.get(
                    '/customers$query',
                    as: 'uid-cajera',
                  )).$2['data']
                  as List)
            customer['name'] as String,
        ];

        expect(await names('?limit=2&page=2'), [
          'Usuario uid-cliente',
          'Usuario uid-ver',
        ]);
        // El correo también se busca; un % se busca tal cual.
        expect(await names('?search=almacen%40tienda'), [
          'Usuario uid-almacen',
        ]);
        expect(await names('?search=%25'), isEmpty);
        expect(
          (await client.get('/customers?orden=nombre', as: 'uid-cajera')).$1,
          400,
        );
      });

      test('el contacto del cliente solo va con customers.view', () async {
        final (_, cajera) = await client.get('/orders', as: 'uid-cajera');
        final (status, onlyOrders) = await client.get('/orders', as: 'uid-ver');

        expect(cajera['data'][0]['customer'], {
          'id': isA<String>(),
          'name': 'Usuario uid-cliente',
          'email': 'uid-cliente@tienda.pe',
          'phone': null,
        });
        expect(status, 200);
        expect(onlyOrders['data'][0]['customer'], isNull);
        expect(onlyOrders['data'][0]['items'], hasLength(1));
      });

      test('los productos de baja, solo con products.view', () async {
        Future<List<String>> names(String? as) async => [
          for (final product
              in (await client.get(
                    '/products?includeInactive=true',
                    as: as,
                  )).$2['data']
                  as List)
            product['name'] as String,
        ];

        expect(await names('uid-almacen'), ['Aceite de baja', 'Arroz']);
        expect(await names('uid-ver'), ['Arroz']);
        expect(await names('uid-cliente'), ['Arroz']);
        expect(await names(null), ['Arroz']);
      });

      test('los pedidos del cliente piden solo una cuenta', () async {
        final (status, _) = await client.get('/orders/mine', as: 'uid-cliente');
        final (noAccount, _) = await client.get(
          '/orders/mine',
          as: 'uid-nadie',
        );

        expect(status, 200);
        expect(noAccount, 403);
        expect((await client.get('/orders/mine')).$1, 401);
      });
    });
  });
}
