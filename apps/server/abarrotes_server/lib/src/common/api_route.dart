import 'dart:async';

import 'package:serverpod/serverpod.dart';

import 'http_json.dart';
import 'input_reader.dart';

/// Una ruta y el path donde se registra. Varias rutas pueden compartir path
/// con métodos distintos (p. ej. GET público y POST protegido).
typedef RouteEntry = (String path, Route route);

/// Registra [routes] en el servidor web (ver [mergeByPath]).
void addRoutes(WebServer webServer, List<RouteEntry> routes) {
  for (final (path, route) in mergeByPath(routes)) {
    webServer.addRoute(route, path);
  }
}

/// Serverpod admite una sola ruta por path, así que las rutas que comparten
/// path se juntan en una que despacha según el método. Cada una conserva su
/// guard. Un mismo método dos veces en un path es un error de programación.
///
/// Cada path responde además `OPTIONS` (el preflight de CORS). Sin eso, el
/// router contestaría 405 antes de que corra corsMiddleware.
List<RouteEntry> mergeByPath(List<RouteEntry> routes) {
  final byPath = <String, Map<Method, Route>>{};
  for (final (path, route) in routes) {
    final methods = byPath.putIfAbsent(path, () => {});
    for (final method in route.methods) {
      if (methods.containsKey(method)) {
        throw ArgumentError('${method.value} $path está registrado dos veces');
      }
      methods[method] = route;
    }
  }
  for (final methods in byPath.values) {
    methods.putIfAbsent(Method.options, _PreflightRoute.new);
  }
  return [
    for (final MapEntry(key: path, value: methods) in byPath.entries)
      (
        path,
        methods.values.toSet().length == 1
            ? methods.values.first
            : _MethodDispatchRoute(methods),
      ),
  ];
}

/// `OPTIONS` sin CORS (p. ej. de un origen no permitido): solo dice que la
/// ruta existe. Las respuestas con CORS las da corsMiddleware antes.
class _PreflightRoute extends Route {
  _PreflightRoute() : super(methods: {Method.options});

  @override
  Result handleCall(Session session, Request request) => Response.noContent();
}

class _MethodDispatchRoute extends Route {
  _MethodDispatchRoute(this._routes) : super(methods: _routes.keys.toSet());

  final Map<Method, Route> _routes;

  @override
  FutureOr<Result> handleCall(Session session, Request request) =>
      _routes[request.method]!.handleCall(session, request);
}

typedef ApiHandler =
    FutureOr<Response> Function(Session session, Request request);

/// Ruta de un solo método definida por una función. Un [ApiException] que
/// lance [handler] se convierte en su respuesta JSON.
class ApiRoute extends Route {
  ApiRoute(Method method, this.handler) : super(methods: {method});

  final ApiHandler handler;

  @override
  Future<Result> handleCall(Session session, Request request) =>
      withApiErrors(() async => handler(session, request));
}

/// El parámetro de ruta `:id` como UUID; si no lo es, 400.
UuidValue idParam(Request request) =>
    parseUuid(request.rawPathParameters[#id]) ??
    (throw const ApiException.badRequest('El id debe ser un UUID'));

/// Escapa `%`, `_` y `\` para usar [text] literal dentro de un LIKE.
String escapeLike(String text) =>
    text.replaceAllMapped(RegExp(r'[\\%_]'), (match) => '\\${match[0]}');
