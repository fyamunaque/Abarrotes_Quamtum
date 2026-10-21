import 'package:flutter_test/flutter_test.dart';
import 'package:neils/router/route_guard.dart';
import 'package:neils/router/routes.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/staff_permission.dart';

import '../support.dart';

void main() {
  final sessions = <String, Session>{
    'sin sesión': const SignedOut(),
    for (final role in UserRole.values) role.name: signedInAs(role),
  };

  String? redirect(Session session, String location) =>
      redirectFor(session, Uri.parse(location));

  group('el flujo público es para todos', () {
    for (final path in ['/', '/login', '/registro', '/catalogo']) {
      for (final MapEntry(key: who, value: session) in sessions.entries) {
        test('$path ($who)', () => expect(redirect(session, path), isNull));
      }
    }
  });

  group('/admin', () {
    test('sin sesión va a /login y recuerda a dónde volver', () {
      expect(redirect(const SignedOut(), '/admin'), '/login?from=%2Fadmin');
      expect(
        redirect(const SignedOut(), '/admin/pedidos?estado=confirmed'),
        '/login?from=%2Fadmin%2Fpedidos%3Festado%3Dconfirmed',
      );
    });

    test('un cliente vuelve al inicio', () {
      expect(redirect(signedInAs(UserRole.customer), '/admin'), '/');
      expect(redirect(signedInAs(UserRole.customer), '/admin/pedidos'), '/');
    });

    test('admin y staff entran, también a las subrutas', () {
      for (final role in [UserRole.admin, UserRole.staff]) {
        expect(redirect(signedInAs(role), '/admin'), isNull);
        expect(redirect(signedInAs(role), '/admin/pedidos'), isNull);
      }
    });

    test('el equipo y los roles, solo con staff.manage', () {
      for (final path in ['/admin/equipo', '/admin/roles']) {
        expect(redirect(signedInAs(UserRole.admin), path), isNull);
        // Del personal, pero sin el permiso: "No tienes acceso".
        expect(
          redirect(signedInAs(UserRole.staff), path),
          '/admin/sin-acceso?seccion=${Uri.encodeComponent(path)}',
        );
        expect(redirect(signedInAs(UserRole.customer), path), '/');
        expect(
          redirect(const SignedOut(), path),
          '/login?from=${Uri.encodeComponent(path)}',
        );
      }
      // Un rol a medida con staff.manage también entra.
      final manager = SignedIn(
        SessionUser(
          id: 'u-gerente',
          name: 'Gina',
          email: 'gina@tienda.pe',
          role: UserRole.admin,
          staffRoleName: 'Gerente',
          permissions: const {StaffPermission.staffManage},
        ),
      );
      expect(redirect(manager, '/admin/equipo'), isNull);
    });

    group('cada sección, con su permiso', () {
      final cashier = signedInWith(cashierPermissions, roleName: 'Cajera');
      final storekeeper = signedInWith(storekeeperPermissions);

      test('lo que pide cada una', () {
        expect(Routes.permissionsFor('/admin'), {StaffPermission.statsView});
        expect(Routes.permissionsFor('/admin/pedidos'), {
          StaffPermission.ordersView,
        });
        expect(Routes.permissionsFor('/admin/inventario/x'), {
          StaffPermission.inventoryView,
        });
        // Con uno de los dos alcanza.
        expect(Routes.permissionsFor('/admin/productos'), {
          StaffPermission.productsView,
          StaffPermission.productsManage,
        });
        expect(Routes.permissionsFor('/admin/promociones'), {
          StaffPermission.promotionsManage,
        });
        expect(Routes.permissionsFor('/admin/clientes-vip'), {
          StaffPermission.vipView,
        });
        expect(Routes.permissionsFor('/admin/sin-acceso'), isNull);
        expect(
          Routes.allows(const {
            StaffPermission.productsManage,
          }, '/admin/productos'),
          isTrue,
        );
      });

      test('sin el permiso, "No tienes acceso" con la sección pedida', () {
        expect(redirect(cashier, '/admin/pedidos'), isNull);
        expect(redirect(cashier, '/admin/productos'), isNull);
        expect(
          redirect(cashier, '/admin/inventario'),
          '/admin/sin-acceso?seccion=%2Fadmin%2Finventario',
        );
        expect(
          redirect(cashier, '/admin/promociones'),
          '/admin/sin-acceso?seccion=%2Fadmin%2Fpromociones',
        );
        expect(redirect(storekeeper, '/admin/inventario'), isNull);
        expect(
          redirect(storekeeper, '/admin/pedidos'),
          '/admin/sin-acceso?seccion=%2Fadmin%2Fpedidos',
        );
        // "Sin acceso" lo ve cualquiera del personal: no hay vueltas.
        expect(redirect(cashier, '/admin/sin-acceso'), isNull);
      });

      test('/admin sin las estadísticas lleva a la sección principal', () {
        expect(redirect(cashier, '/admin'), '/admin/pedidos');
        expect(redirect(storekeeper, '/admin'), isNull);
      });
    });

    test('una ruta que solo empieza parecido no está protegida', () {
      expect(redirect(const SignedOut(), '/administracion'), isNull);
    });

    test('mientras la sesión carga no redirige', () {
      expect(redirect(const SessionLoading(), '/admin'), isNull);
      expect(redirect(const SessionLoading(), '/login'), isNull);
    });
  });

  group('después de ingresar', () {
    SessionUser user(UserRole role) => signedInAs(role).user;

    test('un cliente va al catálogo; el personal, a su sección', () {
      expect(routeAfterSignIn(user(UserRole.customer), null), '/catalogo');
      expect(routeAfterSignIn(user(UserRole.admin), null), '/admin');
      expect(
        routeAfterSignIn(signedInWith(storekeeperPermissions).user, null),
        '/admin/inventario',
      );
      expect(
        routeAfterSignIn(signedInWith(cashierPermissions).user, null),
        '/admin/pedidos',
      );
    });

    test('la sección principal: la de su tarea, o la primera que ve', () {
      SessionUser only(Set<StaffPermission> permissions) =>
          signedInWith(permissions).user;

      // Quien administra la tienda, al inicio.
      expect(panelHomeFor(user(UserRole.admin)), '/admin');
      // Lo primero que puede cambiar.
      expect(panelHomeFor(only(storekeeperPermissions)), '/admin/inventario');
      expect(panelHomeFor(only(cashierPermissions)), '/admin/pedidos');
      expect(
        panelHomeFor(
          only(const {
            StaffPermission.productsView,
            StaffPermission.promotionsManage,
          }),
        ),
        '/admin/promociones',
      );
      // Si no cambia nada, la primera que ve.
      expect(
        panelHomeFor(
          only(const {
            StaffPermission.productsView,
            StaffPermission.ordersView,
          }),
        ),
        '/admin/pedidos',
      );
      // Administra el equipo, pero no ve las estadísticas.
      expect(
        panelHomeFor(only(const {StaffPermission.staffManage})),
        '/admin/equipo',
      );
      // Ninguna sección.
      expect(
        panelHomeFor(only(const {StaffPermission.customersView})),
        '/admin/sin-acceso',
      );
    });

    test('admin y staff vuelven a la ruta del panel que pidieron', () {
      expect(
        routeAfterSignIn(user(UserRole.staff), '/admin/pedidos?estado=x'),
        '/admin/pedidos?estado=x',
      );
    });

    test('sin el permiso de la sección pedida, a la suya', () {
      expect(
        routeAfterSignIn(user(UserRole.staff), '/admin/equipo'),
        '/admin/pedidos',
      );
      expect(
        routeAfterSignIn(user(UserRole.admin), '/admin/equipo'),
        '/admin/equipo',
      );
    });

    test('un cliente que venía del panel va al catálogo', () {
      expect(routeAfterSignIn(user(UserRole.customer), '/admin'), '/catalogo');
    });

    test('cualquier cuenta vuelve al carrito o a "Mis pedidos"', () {
      for (final role in UserRole.values) {
        expect(routeAfterSignIn(user(role), '/carrito'), '/carrito');
        expect(routeAfterSignIn(user(role), '/mis-pedidos'), '/mis-pedidos');
      }
    });

    test('from solo vale si es una de esas rutas de esta app', () {
      for (final from in [
        '/catalogo',
        '/administracion',
        'https://otro.com/admin',
        '//otro.com/admin',
        'https://otro.com/carrito',
        '//otro.com/mis-pedidos',
        '',
      ]) {
        expect(
          routeAfterSignIn(user(UserRole.admin), from),
          '/admin',
          reason: from,
        );
        expect(
          routeAfterSignIn(user(UserRole.customer), from),
          '/catalogo',
          reason: from,
        );
      }
    });
  });

  group('/mis-pedidos', () {
    test('sin sesión va a /login y vuelve después', () {
      expect(
        redirect(const SignedOut(), '/mis-pedidos'),
        '/login?from=%2Fmis-pedidos',
      );
    });

    test('cualquier cuenta entra; mientras la sesión carga, espera', () {
      for (final role in UserRole.values) {
        expect(redirect(signedInAs(role), '/mis-pedidos'), isNull);
      }
      expect(redirect(const SessionLoading(), '/mis-pedidos'), isNull);
    });

    test('el carrito y el detalle no piden cuenta', () {
      expect(redirect(const SignedOut(), '/carrito'), isNull);
      expect(redirect(const SignedOut(), '/producto/arroz'), isNull);
    });
  });
}
