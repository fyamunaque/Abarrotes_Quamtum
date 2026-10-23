import 'package:serverpod/serverpod.dart';

/// Si un navegador puede llamar al servidor desde la página [origin]
/// (p. ej. `http://localhost:5006`).
typedef OriginPolicy = bool Function(String origin);

/// Orígenes permitidos: los de [extra] (exactos) y, en [development],
/// cualquier `http://localhost:<puerto>`, donde corre la app Flutter web.
OriginPolicy allowedOrigins({
  required bool development,
  Iterable<String> extra = const [],
}) {
  final exact = {
    for (final origin in extra)
      if (origin.trim().isNotEmpty) origin.trim(),
  };
  final localhost = RegExp(r'^http://localhost(:\d+)?$');
  return (origin) =>
      exact.contains(origin) || (development && localhost.hasMatch(origin));
}

/// CORS para la app web, que corre en otro origen. Se registra en `/` para
/// correr antes que cualquier otro middleware: el preflight (`OPTIONS`) no
/// trae token, y firebaseAuthMiddleware lo rechazaría.
///
/// Con un origen permitido, responde el preflight con 204 y agrega
/// `Access-Control-Allow-Origin` a las demás respuestas. Con uno ajeno no
/// agrega nada, así que el navegador bloquea la respuesta.
Middleware corsMiddleware(OriginPolicy isAllowed) {
  return (Handler next) {
    return (Request request) async {
      final origin = request.headers['origin']?.firstOrNull;
      if (origin == null || !isAllowed(origin)) return next(request);

      if (request.method == Method.options) {
        return Response.noContent(
          headers: Headers.build((headers) {
            _allowOrigin(headers, origin);
            headers['Access-Control-Allow-Methods'] = const [
              'GET, POST, PUT, PATCH, DELETE, OPTIONS',
            ];
            headers['Access-Control-Allow-Headers'] = const [
              'Authorization, Content-Type',
            ];
            headers['Access-Control-Max-Age'] = const ['600'];
          }),
        );
      }

      final result = await next(request);
      if (result is! Response) return result;
      return result.copyWith(
        headers: result.headers.transform(
          (headers) => _allowOrigin(headers, origin),
        ),
      );
    };
  };
}

void _allowOrigin(MutableHeaders headers, String origin) {
  headers['Access-Control-Allow-Origin'] = [origin];
  headers['Vary'] = const ['Origin'];
}
