import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/auth/auth_repository.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/staff_permission.dart';
import 'package:neils/users/http_user_repository.dart';

void main() {
  /// Como responde el servidor: JSON en UTF-8, sin charset en el Content-Type.
  http.Response json(int status, Object body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  HttpUserRepository repository(
    MockClientHandler handler, {
    String baseUrl = 'http://localhost:8082',
  }) => HttpUserRepository(
    ApiClient(MockClient(handler), baseUrl: Uri.parse(baseUrl)),
  );

  Matcher failsWith(String text) => throwsA(
    isA<AuthFailure>().having((f) => f.message, 'message', contains(text)),
  );

  const profile = {
    'id': '0190a1b2-0000-7000-8000-000000000001',
    'email': 'jose@tienda.pe',
    'name': 'José Ñahui',
    'phone': null,
    'role': 'staff',
    'address': null,
    'createdAt': '2026-10-04T10:00:00.000Z',
  };

  test('pide GET /users/me con el ID token y arma la cuenta', () async {
    late http.Request sent;
    final user = await repository((request) async {
      sent = request;
      return json(200, profile);
    }).me('el-token');

    expect(sent.method, 'GET');
    expect(sent.url.toString(), 'http://localhost:8082/users/me');
    expect(sent.headers['authorization'], 'Bearer el-token');
    expect(user.id, profile['id']);
    expect(user.email, 'jose@tienda.pe');
    expect(user.name, 'José Ñahui');
    expect(user.role, UserRole.staff);
    expect(user.address, isNull);

    final withAddress = await repository(
      (_) async => json(200, {...profile, 'address': 'Jr. Cusco 456'}),
    ).me('t');
    expect(withAddress.address, 'Jr. Cusco 456');

    // isVip: sin el campo (un servidor anterior), no es VIP.
    expect(user.isVip, isFalse);
    final vip = await repository(
      (_) async => json(200, {...profile, 'isVip': true}),
    ).me('t');
    expect(vip.isVip, isTrue);
  });

  test('el rol del equipo y los permisos que la app conoce', () async {
    final user = await repository(
      (_) async => json(200, {
        ...profile,
        'staffRole': {'id': 'r-1', 'name': 'Cajera'},
        'permissions': ['orders.view', 'orders.updateStatus', 'otro.nuevo'],
      }),
    ).me('t');

    expect(user.staffRoleName, 'Cajera');
    expect(user.permissions, {
      StaffPermission.ordersView,
      StaffPermission.ordersUpdateStatus,
    });
    expect(user.can(StaffPermission.ordersView), isTrue);
    expect(user.can(StaffPermission.staffManage), isFalse);

    // Sin los campos (un servidor anterior, o un cliente): ninguno.
    final customer = await repository(
      (_) async => json(200, {...profile, 'staffRole': null}),
    ).me('t');
    expect(customer.staffRoleName, isNull);
    expect(customer.permissions, isEmpty);
  });

  test('respeta el path de API_URL y la barra final', () async {
    late Uri url;
    await repository((request) async {
      url = request.url;
      return json(200, profile);
    }, baseUrl: 'https://api.tienda.pe/v1/').me('t');

    expect(url.toString(), 'https://api.tienda.pe/v1/users/me');
  });

  group('errores', () {
    test('401: la sesión no es válida', () {
      expect(
        repository((_) async => json(401, {'message': 'Token vencido'}))
            .me('t'),
        failsWith('Vuelve a ingresar'),
      );
    });

    test('5xx: el servidor no está disponible', () {
      expect(
        repository((_) async => json(503, {'message': 'x'})).me('t'),
        failsWith('no está disponible'),
      );
    });

    test('409 y 400 muestran el mensaje del servidor', () {
      expect(
        repository(
          (_) async => json(409, {
            'statusCode': 409,
            'message': 'Ese email ya está registrado con otra cuenta',
            'error': 'Conflict',
          }),
        ).me('t'),
        failsWith('Ese email ya está registrado con otra cuenta'),
      );
      expect(
        repository((_) async => http.Response('nada', 400)).me('t'),
        failsWith('No se pudo cargar tu cuenta'),
      );
    });

    test('sin conexión con el servidor', () {
      expect(
        repository((_) async => throw http.ClientException('refused')).me('t'),
        failsWith('No se pudo conectar'),
      );
    });

    test('una respuesta que no es un perfil', () {
      expect(
        repository((_) async => json(200, {...profile, 'role': 'root'}))
            .me('t'),
        failsWith('inesperado'),
      );
      expect(
        repository((_) async => http.Response('<html>', 200)).me('t'),
        failsWith('inesperado'),
      );
    });
  });
}
