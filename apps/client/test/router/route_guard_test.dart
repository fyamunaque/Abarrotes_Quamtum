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
  });
}
