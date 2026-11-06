import 'dart:math';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../common/photos.dart';

/// Las fotos de los productos: [Photos] en la carpeta `products`, de hasta
/// [maxSide] px. En `Product.imageUrl` va `/images/products/<id>/<archivo>`.
class ProductImages {
  ProductImages({Random? random})
    : _photos = Photos(folder: 'products', maxSide: maxSide, random: random);

  final Photos _photos;

  static const storageId = Photos.storageId;

  /// El comienzo de la URL de una foto subida (y de la ruta que la sirve).
  static const urlPrefix = '/images/products/';

  /// Lo más que puede pesar la foto que llega.
  static const maxUploadBytes = Photos.maxUploadBytes;

  /// El lado más largo de la foto guardada.
  static const maxSide = 800;

  /// Si [url] es de una foto subida aquí (y no una URL externa).
  static bool isStored(String? url) => url != null && url.startsWith(urlPrefix);

  /// La foto lista para guardar ([Photos.processPhoto]), de hasta [maxSide].
  static Uint8List process(Uint8List bytes) =>
      Photos.processPhoto(bytes, maxSide: maxSide);

  /// Guarda [jpeg] como una foto nueva del producto y devuelve su URL.
  Future<String> store(Session session, UuidValue productId, Uint8List jpeg) =>
      _photos.store(session, productId, jpeg);

  /// La foto [file] del producto, o null si no existe.
  Future<Uint8List?> read(Session session, String productId, String file) =>
      _photos.read(session, productId, file);

  /// Borra la foto de [url] si es una subida aquí.
  Future<void> delete(Session session, String? url) =>
      _photos.delete(session, url);
}
