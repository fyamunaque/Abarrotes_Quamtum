import 'package:serverpod/serverpod.dart';

import '../auth/firebase_token_verifier.dart';
import '../auth/role_guard.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../generated/protocol.dart';
import 'categories_service.dart';

/// Rutas de categorías: lectura pública (el marketplace y la app la usan) y
/// escritura solo para admin y staff.
List<RouteEntry> categoriesRoutes(
  CategoriesService categories,
  FirebaseTokenVerifier verifier,
) {
  Route staffOnly(Route route) =>
      RoleGuard(staffRoles, route, verifier: verifier);

  return [
    (
      '/categories',
      ApiRoute(Method.get, (session, request) async {
        InputReader.query(request, allowed: const {}).check();
        final list = await categories.list(session);
        return jsonResponse(200, list.map(categoryJson).toList());
      }),
    ),
    (
      '/categories/:id',
      ApiRoute(Method.get, (session, request) async {
        final category = await categories.get(session, idParam(request));
        return jsonResponse(200, categoryJson(category));
      }),
    ),
    (
      '/categories',
      staffOnly(
        ApiRoute(Method.post, (session, request) async {
          final name = _readName(await readJsonBody(request), required: true);
          final category = await categories.create(session, name!);
          return jsonResponse(201, categoryJson(category));
        }),
      ),
    ),
    (
      '/categories/:id',
      staffOnly(
        ApiRoute(Method.patch, (session, request) async {
          final id = idParam(request);
          final name = _readName(await readJsonBody(request), required: false);
          final category = await categories.update(session, id, name);
          return jsonResponse(200, categoryJson(category));
        }),
      ),
    ),
    (
      '/categories/:id',
      staffOnly(
        ApiRoute(Method.delete, (session, request) async {
          await categories.delete(session, idParam(request));
          return Response.noContent();
        }),
      ),
    ),
  ];
}

/// Body de POST y PATCH: `{name}`, sin espacios alrededor.
String? _readName(Object? json, {required bool required}) {
  final body = InputReader.body(json, allowed: const {'name'});
  final name = body.text('name', maxLength: 60, required: required);
  body.check();
  return name;
}

Map<String, Object?> categoryJson(Category category) => {
  'id': category.id.toString(),
  'name': category.name,
};
