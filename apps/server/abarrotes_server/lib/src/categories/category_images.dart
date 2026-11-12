import 'dart:math';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../common/photos.dart';

/// Las fotos de las categorías: [Photos] en la carpeta `categories`, como
/// `ProductImages` con las de los productos. Se ven anchas (el encabezado de
/// la categoría en la tienda), así que se guardan de hasta [maxSide] px por
/// lado. En `Category.imageUrl` va `/images/categories/<id>/<archivo>.jpg`.
class CategoryImages {
  CategoryImages({Random? random})
    : _photos = Photos(folder: 'categories', maxSide: maxSide, random: random);

  final Photos _photos;

  /// El comienzo de la URL de una foto subida (y de la ruta que la sirve).
  static const urlPrefix = '/images/categories/';

  /// El lado más largo de la foto guardada.
  static const maxSide = 1200;

  /// Si [url] es de una foto subida aquí (y no una URL externa).
  static bool isStored(String? url) => url != null && url.startsWith(urlPrefix);

  /// La foto lista para guardar ([Photos.processPhoto]), de hasta [maxSide].
  static Uint8List process(Uint8List bytes) =>
      Photos.processPhoto(bytes, maxSide: maxSide);

  /// Guarda [jpeg] como una foto nueva de la categoría y devuelve su URL.
  Future<String> store(Session session, UuidValue categoryId, Uint8List jpeg) =>
      _photos.store(session, categoryId, jpeg);

  /// La foto [file] de la categoría, o null si no existe.
  Future<Uint8List?> read(Session session, String categoryId, String file) =>
      _photos.read(session, categoryId, file);

  /// Borra la foto de [url] si es una subida aquí.
  Future<void> delete(Session session, String? url) =>
      _photos.delete(session, url);
}
