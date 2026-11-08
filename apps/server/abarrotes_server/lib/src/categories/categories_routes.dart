import 'package:serverpod/serverpod.dart';

import '../auth/guards.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/photos.dart';
import '../generated/protocol.dart';
import 'categories_service.dart';
import 'category_images.dart';

/// Rutas de categorías: lectura pública (el marketplace y la app la usan),
/// la foto pública, y escritura con `categories.manage`.
List<RouteEntry> categoriesRoutes(
  CategoriesService categories,
  Guards guards,
) {
  Route manage(Route route) =>
      guards.require(Permission.categoriesManage, route);

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
      manage(
        ApiRoute(Method.post, (session, request) async {
          final (:name, :description, clear: _) = _readBody(
            await readJsonBody(request),
            nameRequired: true,
          );
          final category = await categories.create(
            session,
            name!,
            description: description,
          );
          return jsonResponse(201, categoryJson(category));
        }),
      ),
    ),
    (
      '/categories/:id',
      manage(
        ApiRoute(Method.patch, (session, request) async {
          final id = idParam(request);
          final (:name, :description, :clear) = _readBody(
            await readJsonBody(request),
            nameRequired: false,
          );
          final category = await categories.update(
            session,
            id,
            name,
            description: description,
            clearDescription: clear,
          );
          return jsonResponse(200, categoryJson(category));
        }),
      ),
    ),
    (
      '/categories/:id/image',
      // La foto, tal cual (sin JSON): JPEG, PNG o WebP. Se guarda procesada
      // y reemplaza a la que tenía.
      manage(
        ApiRoute(Method.put, (session, request) async {
          final id = idParam(request);
          final photo = categories.processImage(await readPhotoBody(request));
          final category = await categories.setImage(session, id, photo);
          return jsonResponse(200, categoryJson(category));
        }),
      ),
    ),
    (
      '/categories/:id/image',
      // Sin foto: la tienda vuelve a mostrar su color con la inicial.
      manage(
        ApiRoute(Method.delete, (session, request) async {
          final category = await categories.removeImage(
            session,
            idParam(request),
          );
          return jsonResponse(200, categoryJson(category));
        }),
      ),
    ),
    (
      '${CategoryImages.urlPrefix}:categoryId/:file',
      // Pública, como el catálogo. Cada foto subida tiene un nombre nuevo:
      // el navegador la guarda en caché para siempre.
      ApiRoute(Method.get, (session, request) async {
        final photo = await categories.image(
          session,
          request.rawPathParameters[#categoryId] ?? '',
          request.rawPathParameters[#file] ?? '',
        );
        if (photo == null) throw const ApiException(404, 'Foto no encontrada');
        return Response.ok(
          body: Body.fromData(photo, mimeType: MimeType.parse('image/jpeg')),
          headers: Headers.build((headers) {
            headers['Cache-Control'] = const [
              'public, max-age=31536000, immutable',
            ];
          }),
        );
      }),
    ),
    (
      '/categories/:id',
      manage(
        ApiRoute(Method.delete, (session, request) async {
          await categories.delete(session, idParam(request));
          return Response.noContent();
        }),
      ),
    ),
  ];
}

/// Body de POST y PATCH: `{name, description}`, sin espacios alrededor. La
/// descripción tiene hasta 80 caracteres; vacía o `null` en un PATCH
/// ([clear]) la borra.
({String? name, String? description, bool clear}) _readBody(
  Object? json, {
  required bool nameRequired,
}) {
  final body = InputReader.body(json, allowed: const {'name', 'description'});
  final name = body.text('name', maxLength: 60, required: nameRequired);
  final hasDescription =
      json is Map<String, Object?> && json.containsKey('description');
  final raw = hasDescription ? json['description'] : null;
  final blank =
      hasDescription && (raw == null || (raw is String && raw.trim().isEmpty));
  final description = blank
      ? null
      : body.text('description', maxLength: 80, required: false);
  body.check();
  return (name: name, description: description, clear: blank);
}

Map<String, Object?> categoryJson(Category category) => {
  'id': category.id.toString(),
  'name': category.name,
  'description': category.description,
  'imageUrl': category.imageUrl,
};
