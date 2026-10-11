import 'dart:async';
import 'dart:convert';

import 'package:abarrotes_server/src/common/api_route.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import 'test_tokens.dart';

/// Sirve [routes] en un servidor HTTP local montándolas igual que
/// `addRoutes` en Serverpod (`mergeByPath` + `injectAt`), pero atendiendo
/// cada petición con la sesión del test, para que todo quede dentro de su
/// transacción (y se revierta al terminar).
Future<RelicServer> serveRoutes(
  Session Function() session,
  List<RouteEntry> routes, {
  Map<String, Middleware> middleware = const {},
}) {
  final app = RelicApp();
  middleware.forEach((path, middleware) => app.use(path, middleware));
  for (final (path, route) in mergeByPath(routes)) {
    app.injectAt(path, _WithTestSession(route, session));
  }
  return app.serve(port: 0);
}

/// La ruta de [route], pero con la sesión del test en vez de una por petición.
class _WithTestSession extends Route {
  _WithTestSession(this.route, this.session)
    : super(methods: route.methods, path: route.path, host: route.host);

  final Route route;
  final Session Function() session;

  @override
  Future<Result> call(Request req) async => route.handleCall(session(), req);

  @override
  FutureOr<Result> handleCall(Session session, Request request) =>
      route.handleCall(session, request);
}

/// Respuesta ya decodificada: el status y el JSON (o null si no hubo body).
typedef ApiResult = (int status, dynamic body);

/// Cliente HTTP de los tests. Con `as:` manda un Firebase ID token de ese uid
/// firmado con las llaves de prueba; [email] y [emailVerified] cambian esos
/// claims (por defecto, `<uid>@tienda.pe` verificado: el correo que le pone
/// [insertUser], así el personal se reconoce por su correo).
class TestClient {
  TestClient(this.server, this.google);

  final RelicServer server;
  final RsaKeyPair google;

  Future<ApiResult> get(
    String path, {
    String? as,
    String? email,
    bool emailVerified = true,
  }) => _send(
    'GET',
    path,
    as: as,
    email: email,
    emailVerified: emailVerified,
  );

  Future<ApiResult> post(
    String path,
    Object? body, {
    String? as,
    String? email,
    bool emailVerified = true,
  }) => _send(
    'POST',
    path,
    body: body,
    as: as,
    email: email,
    emailVerified: emailVerified,
  );

  Future<ApiResult> patch(String path, Object? body, {String? as}) =>
      _send('PATCH', path, body: body, as: as);

  Future<ApiResult> delete(String path, {String? as}) =>
      _send('DELETE', path, as: as);

  Future<ApiResult> _send(
    String method,
    String path, {
    Object? body,
    String? as,
    String? email,
    bool emailVerified = true,
  }) async {
    final claims = validClaims(
      uid: as ?? '',
      email: email ?? '$as@tienda.pe',
      emailVerified: emailVerified,
    );
    final request =
        http.Request(method, Uri.parse('http://localhost:${server.port}$path'))
          ..headers.addAll({
            'content-type': 'application/json',
            if (as != null)
              'authorization':
                  'Bearer ${signToken(google.private, claims: claims)}',
          });
    if (body != null) request.body = body is String ? body : jsonEncode(body);
    final response = await http.Response.fromStream(await request.send());
    return (
      response.statusCode,
      response.body.isEmpty ? null : jsonDecode(response.body),
    );
  }
}

/// Crea una cuenta cuyo firebaseUid es [uid] (correo `$uid@tienda.pe`, si
/// no se dice otro). Para que además sea del personal, `insertStaff`.
Future<User> insertUser(Session session, String uid, {String? email}) =>
    User.db.insertRow(
      session,
      User(
        firebaseUid: uid,
        email: email ?? '$uid@tienda.pe',
        name: 'Usuario $uid',
      ),
    );
