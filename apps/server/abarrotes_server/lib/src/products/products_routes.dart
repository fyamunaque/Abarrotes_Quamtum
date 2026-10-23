import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../auth/firebase_auth_middleware.dart';
import '../auth/guards.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/money.dart';
import '../common/pagination.dart';
import '../common/shopper.dart';
import '../generated/protocol.dart';
import '../promotions/promotion_rules.dart';
import 'product_images.dart';
import 'products_service.dart';

/// Rutas de productos: lectura pública (marketplace y app) y escritura con
/// `products.manage`. La lectura usa el token, si viene, para mostrar la
/// promoción de cada cliente y, con `products.view`, los dados de baja.
List<RouteEntry> productsRoutes(
  ProductsService products,
  Guards guards, {
  required ShopperResolver shoppers,
}) {
  Route staffOnly(Method method, ApiHandler handler) =>
      guards.require(Permission.productsManage, ApiRoute(method, handler));

  Future<Shopper> shopperOf(Session session, Request request) async => shoppers
      .resolve(session, await optionalIdentity(guards.verifier, request));

  Future<bool> canViewInactive(Session session, Request request) async =>
      (await guards.optionalAccess(
        session,
        request,
      )).can(Permission.productsView);

  return [
    (
      '/products',
      ApiRoute(Method.get, (session, request) async {
        final query = InputReader.query(
          request,
          allowed: {
            ...PageQuery.fields,
            'categoryId',
            'search',
            'includeInactive',
            'onSale',
          },
        );
        final page = PageQuery.read(query);
        final categoryId = query.uuid('categoryId', required: false);
        final search = query.text('search', maxLength: 100, required: false);
        final includeInactive =
            query.boolean('includeInactive', required: false) ?? false;
        final onSale = query.boolean('onSale', required: false) ?? false;
        query.check();

        final (list, total) = await products.list(
          session,
          page,
          shopper: await shopperOf(session, request),
          categoryId: categoryId,
          search: search,
          // Solo tiene efecto con products.view; para el resto se ignora.
          includeInactive:
              includeInactive && await canViewInactive(session, request),
          onSale: onSale,
        );
        return jsonResponse(
          200,
          page.wrap(list.map(productJson).toList(), total),
        );
      }),
    ),
    (
      '/products/:id',
      ApiRoute(Method.get, (session, request) async {
        final id = idParam(request);
        final staff = await canViewInactive(session, request);
        final product = await products.get(
          session,
          id,
          shopper: await shopperOf(session, request),
          includeInactive: staff,
        );
        return jsonResponse(200, productJson(product));
      }),
    ),
    (
      '/products',
      staffOnly(Method.post, (session, request) async {
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: {..._editableFields, 'currentStock'},
        );
        final name = body.text('name', maxLength: 150);
        final description = _description(body);
        final sku = body.text('sku', maxLength: 50);
        final priceCents = _price(body, required: true);
        final imageUrl = _imageUrl(body);
        final active = body.boolean('active', required: false);
        // Solo el stock inicial; después, por inventory.
        final currentStock = body.integer('currentStock', required: false);
        final minStock = body.integer('minStock', required: false);
        final expirationDate = body.dateTime('expirationDate', nullable: true);
        final categoryId = body.uuid('categoryId');
        if (ProductImages.isStored(imageUrl)) {
          body.reject(
            'imageUrl tiene que ser una URL http(s): la foto se sube después '
            'de crear el producto',
          );
        }
        body.check();

        final product = await products.create(
          session,
          Product(
            name: name!,
            description: description,
            sku: sku!,
            priceCents: priceCents!,
            imageUrl: imageUrl,
            active: active ?? true,
            currentStock: currentStock ?? 0,
            minStock: minStock ?? 0,
            expirationDate: expirationDate,
            categoryId: categoryId!,
          ),
        );
        return jsonResponse(201, productJson(product));
      }),
    ),
    (
      '/products/:id',
      staffOnly(Method.patch, (session, request) async {
        final id = idParam(request);
        // Campos parciales; el stock no se edita aquí (inventory).
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: _editableFields,
        );
        final name = body.text('name', maxLength: 150, required: false);
        final description = _description(body);
        final sku = body.text('sku', maxLength: 50, required: false);
        final priceCents = _price(body, required: false);
        final imageUrl = _imageUrl(body);
        final active = body.boolean('active', required: false);
        final minStock = body.integer('minStock', required: false);
        final expirationDate = body.dateTime('expirationDate', nullable: true);
        final categoryId = body.uuid('categoryId', required: false);
        body.check();

        final product = await products.update(session, id, (current) {
          var product = current.copyWith(
            name: name,
            sku: sku,
            priceCents: priceCents,
            active: active,
            minStock: minStock,
            categoryId: categoryId,
          );
          // Los campos nullables se borran si vienen en null.
          if (body.has('description')) {
            product = product.copyWith(description: description);
          }
          if (body.has('imageUrl')) {
            // Una foto subida solo vale si es la que ya tiene: así se puede
            // reenviar el producto sin tocarla. Para cambiarla, se sube.
            if (ProductImages.isStored(imageUrl) &&
                imageUrl != current.imageUrl) {
              throw const ApiException.badRequest(
                'Para cambiar la foto, súbela con PUT /products/:id/image',
              );
            }
            product = product.copyWith(imageUrl: imageUrl);
          }
          if (body.has('expirationDate')) {
            product = product.copyWith(expirationDate: expirationDate);
          }
          return product;
        });
        return jsonResponse(200, productJson(product));
      }),
    ),
    (
      '/products/:id',
      // Desactiva el producto (baja lógica) y lo devuelve.
      staffOnly(Method.delete, (session, request) async {
        final product = await products.deactivate(session, idParam(request));
        return jsonResponse(200, productJson(product));
      }),
    ),
    (
      '/products/:id/image',
      // La foto, tal cual (sin JSON): JPEG, PNG o WebP. Se guarda procesada
      // y reemplaza a la que tenía.
      staffOnly(Method.put, (session, request) async {
        final id = idParam(request);
        final photo = ProductImages.process(await _readPhoto(request));
        final product = await products.setImage(session, id, photo);
        return jsonResponse(200, productJson(product));
      }),
    ),
    (
      '${ProductImages.urlPrefix}:productId/:file',
      // Pública, como el catálogo. Cada foto subida tiene un nombre nuevo:
      // el navegador la guarda en caché para siempre.
      ApiRoute(Method.get, (session, request) async {
        final photo = await products.image(
          session,
          request.rawPathParameters[#productId] ?? '',
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
  ];
}

/// El body de la subida de una foto, de hasta [ProductImages.maxUploadBytes].
Future<Uint8List> _readPhoto(Request request) async {
  final bytes = BytesBuilder(copy: false);
  try {
    await for (final chunk in request.read(
      maxLength: ProductImages.maxUploadBytes,
    )) {
      bytes.add(chunk);
    }
  } on MaxBodySizeExceeded {
    throw const ApiException(413, 'La foto pesa más de 8 MB');
  }
  if (bytes.isEmpty) {
    throw const ApiException.badRequest('Falta la foto en el body');
  }
  return bytes.takeBytes();
}

const _editableFields = {
  'name',
  'description',
  'sku',
  'price',
  'imageUrl',
  'active',
  'minStock',
  'expirationDate',
  'categoryId',
};

String? _description(InputReader body) =>
    body.text('description', maxLength: 1000, nullable: true);

int? _price(InputReader body, {required bool required}) =>
    body.cents('price', minCents: 0, required: required);

/// Una URL externa o la ruta de una foto subida ([ProductImages]); qué ruta
/// vale lo decide cada ruta.
String? _imageUrl(InputReader body) => body.url(
  'imageUrl',
  maxLength: 2000,
  nullable: true,
  orPathUnder: ProductImages.urlPrefix,
);

/// Como lo lee la app (`Product.fromJson`): precios como texto ("4.5") y
/// la promoción vigente de quien mira (o null) con días de la tienda.
Map<String, Object?> productJson(Product product) {
  final category = product.category!;
  return {
    'id': product.id.toString(),
    'name': product.name,
    'description': product.description,
    'sku': product.sku,
    'price': formatMoney(product.priceCents),
    'imageUrl': product.imageUrl,
    'active': product.active,
    'currentStock': product.currentStock,
    'minStock': product.minStock,
    'expirationDate': product.expirationDate?.toUtc().toIso8601String(),
    'createdAt': product.createdAt.toUtc().toIso8601String(),
    'categoryId': product.categoryId.toString(),
    'category': {'id': category.id.toString(), 'name': category.name},
    'promotion': _promotionJson(product.promotions?.firstOrNull),
  };
}

/// La promoción vigente tal como la ven el marketplace y la app.
Map<String, Object?>? _promotionJson(Promotion? promotion) {
  if (promotion == null) return null;
  final days = toDayPeriod(promotion.startDate, promotion.endDate);
  return {
    'id': promotion.id.toString(),
    'promoPrice': formatMoney(promotion.promoPriceCents),
    'startDate': days.startDate,
    'endDate': days.endDate,
    'title': promotion.title,
    'audience': promotion.audience.name,
  };
}
