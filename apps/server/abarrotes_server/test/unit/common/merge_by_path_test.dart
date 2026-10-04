import 'package:abarrotes_server/src/common/api_route.dart';
import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../../support/http_harness.dart';

void main() {
  RouteEntry route(String path, Method method, String answer) =>
      (path, ApiRoute(method, (_, _) => jsonResponse(200, answer)));

  test(
    'Serverpod monta un router por path: dos rutas en el mismo path chocan',
    () {
      final app = RelicApp()
        ..injectAt('/items', route('/items', Method.get, 'lista').$2);

      expect(
        () => app.injectAt('/items', route('/items', Method.post, 'crear').$2),
        throwsArgumentError,
      );
    },
  );

  test(
    'mergeByPath junta los métodos de un path y despacha a cada ruta',
    () async {
      final server = await serveRoutes(() => _NoSession(), [
        route('/items', Method.get, 'lista'),
        route('/items', Method.post, 'crear'),
        route('/items/:id', Method.get, 'detalle'),
      ]);
      addTearDown(server.close);
      Uri url(String path) => Uri.parse('http://localhost:${server.port}$path');

      expect((await http.get(url('/items'))).body, '"lista"');
      expect((await http.post(url('/items'))).body, '"crear"');
      expect((await http.get(url('/items/1'))).body, '"detalle"');
      expect((await http.put(url('/items'))).statusCode, 405);
    },
  );

  test('todo path responde OPTIONS, para el preflight de CORS', () async {
    final server = await serveRoutes(() => _NoSession(), [
      route('/items', Method.get, 'lista'),
      route('/items/:id', Method.get, 'detalle'),
      route('/items/:id', Method.patch, 'editar'),
    ]);
    addTearDown(server.close);
    Future<int> options(String path) async => (await http.Request(
      'OPTIONS',
      Uri.parse('http://localhost:${server.port}$path'),
    ).send()).statusCode;

    expect(await options('/items'), 204);
    expect(await options('/items/1'), 204);
  });

  test('un OPTIONS propio de una ruta no se reemplaza', () {
    final custom = ApiRoute(Method.options, (_, _) => jsonResponse(200, 'x'));
    final merged = mergeByPath([
      route('/items', Method.get, 'lista'),
      ('/items', custom),
    ]);

    expect(merged.single.$2.methods, {Method.get, Method.options});
  });

  test('el mismo método dos veces en un path es un error', () {
    expect(
      () => mergeByPath([
        route('/items', Method.get, 'a'),
        route('/items', Method.get, 'b'),
      ]),
      throwsArgumentError,
    );
  });
}

/// Las rutas de estos tests no usan la sesión.
class _NoSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('La ruta no debería usar la sesión');
}
