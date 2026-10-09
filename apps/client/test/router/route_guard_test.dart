import 'package:flutter_test/flutter_test.dart';
import 'package:neils/router/route_guard.dart';
import 'package:neils/session/session.dart';

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

    test('un cliente va al catálogo; admin y staff al panel', () {
      expect(routeAfterSignIn(user(UserRole.customer), null), '/catalogo');
      expect(routeAfterSignIn(user(UserRole.admin), null), '/admin');
      expect(routeAfterSignIn(user(UserRole.staff), null), '/admin');
    });

    test('admin y staff vuelven a la ruta del panel que pidieron', () {
      expect(
        routeAfterSignIn(user(UserRole.staff), '/admin/pedidos?estado=x'),
        '/admin/pedidos?estado=x',
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
