import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/auth/auth_repository.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/legal/legal_texts.dart';
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

  test('el perfil: celular, DNI, términos y si está completo', () async {
    final user = await repository(
      (_) async => json(200, {
        ...profile,
        'phone': '987654321',
        'dni': '45678912',
        'termsVersion': termsVersion,
        'termsAcceptedAt': '2026-10-28T15:00:00.000Z',
        'profileComplete': true,
      }),
    ).me('t');

    expect(user.phone, '987654321');
    expect(user.dni, '45678912');
    expect(user.termsVersion, termsVersion);
    expect(user.termsAcceptedAt, DateTime.utc(2026, 10, 28, 15));
    expect(user.profileComplete, isTrue);

    final incomplete = await repository(
      (_) async => json(200, {...profile, 'profileComplete': false}),
    ).me('t');
    expect(incomplete.profileComplete, isFalse);
    // Un servidor anterior no lo manda (ni lo pide): completo.
    expect(
      (await repository((_) async => json(200, profile)).me('t'))
          .profileComplete,
      isTrue,
    );
  });

  group('updateProfile', () {
    test(
      'PATCH /users/me con lo que cambia y la versión de los términos',
      () async {
        final sent = <http.Request>[];
        final repo = repository((request) async {
          sent.add(request);
          return json(200, {...profile, 'phone': '987654321'});
        });

        final user = await repo.updateProfile(
          'el-token',
          phone: '987 654 321',
          dni: '45678912',
          acceptTerms: true,
        );
        await repo.updateProfile('el-token', clearDni: true);
        await repo.updateProfile('el-token', phone: '912345678');

        expect(sent.first.method, 'PATCH');
        expect(sent.first.url.path, '/users/me');
        expect(sent.first.headers['authorization'], 'Bearer el-token');
        expect(jsonDecode(sent[0].body), {
          'phone': '987 654 321',
          'dni': '45678912',
          'acceptTerms': termsVersion,
        });
        expect(jsonDecode(sent[1].body), {'dni': null});
        expect(jsonDecode(sent[2].body), {'phone': '912345678'});
        expect(user.phone, '987654321');
      },
    );

    test('un DNI de otra cuenta: ApiFailure 409 con el mensaje', () {
      expect(
        repository(
          (_) async => json(409, {
            'statusCode': 409,
            'message': 'Ese DNI ya está registrado en otra cuenta.',
          }),
        ).updateProfile('t', dni: '45678912'),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.status, 'status', 409)
              .having(
                (f) => f.message,
                'message',
                'Ese DNI ya está registrado en otra cuenta.',
              ),
        ),
      );
    });
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
