import 'dart:convert';

import 'package:abarrotes_server/src/auth/firebase_auth_middleware.dart';
import 'package:abarrotes_server/src/auth/firebase_identity.dart';
import 'package:abarrotes_server/src/auth/firebase_token_verifier.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../../support/test_tokens.dart';

/// Monta el middleware como en el servidor (sobre `/users`) en un servidor
/// HTTP real, con rutas que responden el uid de la identidad recibida.
void main() {
  late RsaKeyPair google;
  late RelicServer server;

  Uri url(String path) => Uri.parse('http://localhost:${server.port}$path');

  FirebaseTokenVerifier verifier({PublicKeysUnavailableException? keysError}) =>
      FirebaseTokenVerifier(
        projectId: testProjectId,
        keys: FakeKeys({'llave-1': google.public}, error: keysError),
        now: () => testNow,
      );

  Response uid(Request request) =>
      Response.ok(body: Body.fromString(request.firebaseIdentity.uid));

  setUpAll(() async {
    google = generateRsaKeyPair();
    final app = RelicApp()
      ..use('/users', firebaseAuthMiddleware(verifier()))
      ..get('/users/me', uid)
      ..post('/users', uid)
      ..use(
        '/sin-llaves',
        firebaseAuthMiddleware(
          verifier(keysError: const PublicKeysUnavailableException('sin red')),
        ),
      )
      ..get('/sin-llaves', uid)
      ..get('/publica', (_) => Response.ok(body: Body.fromString('ok')));
    server = await app.serve(port: 0);
  });

  tearDownAll(() => server.close());

  Map<String, String> bearer(String token) => {
    'authorization': 'Bearer $token',
  };

  test('con un token válido deja pasar y entrega la identidad', () async {
    final token = signToken(google.private);

    final me = await http.get(url('/users/me'), headers: bearer(token));
    final create = await http.post(url('/users'), headers: bearer(token));

    expect((me.statusCode, me.body), (200, 'uid-ana'));
    expect((create.statusCode, create.body), (200, 'uid-ana'));
  });

  test('acepta el esquema Bearer sin importar mayúsculas', () async {
    final response = await http.get(
      url('/users/me'),
      headers: {'authorization': 'bearer ${signToken(google.private)}'},
    );

    expect(response.statusCode, 200);
  });

  test('sin header Authorization responde 401 en JSON', () async {
    final response = await http.get(url('/users/me'));

    expect(response.statusCode, 401);
    expect(response.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(response.body), {
      'statusCode': 401,
      'message': 'Falta el token de acceso (Authorization: Bearer <token>)',
      'error': 'Unauthorized',
    });
  });

  test('POST /users también está protegido', () async {
    final response = await http.post(url('/users'));

    expect(response.statusCode, 401);
  });

  test('con otro esquema (Basic) responde 401', () async {
    final response = await http.get(
      url('/users/me'),
      headers: {'authorization': 'Basic dXN1YXJpbzpjbGF2ZQ=='},
    );

    expect(response.statusCode, 401);
  });

  test('con un token inválido responde 401 sin detalles', () async {
    final response = await http.get(
      url('/users/me'),
      headers: bearer(unsignedToken(validClaims())),
    );

    expect(response.statusCode, 401);
    expect(jsonDecode(response.body)['message'], 'Token inválido o vencido');
  });

  test('si no hay llaves de Google responde 503', () async {
    final response = await http.get(
      url('/sin-llaves'),
      headers: bearer(signToken(google.private)),
    );

    expect(response.statusCode, 503);
  });

  test('no toca las rutas fuera de su prefijo', () async {
    final response = await http.get(url('/publica'));

    expect(response.statusCode, 200);
  });
}
