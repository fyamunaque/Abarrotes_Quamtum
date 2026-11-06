import '../common/photos.dart';

/// Las fotos de las categorías: [Photos] en la carpeta `categories`. Se ven
/// anchas (el encabezado de la categoría en la tienda), así que se guardan
/// de hasta 1200 px por lado. En `Category.imageUrl` va
/// `/images/categories/<id>/<archivo>.jpg`.
class CategoryImages extends Photos {
  CategoryImages({super.random})
    : super(folder: 'categories', maxSide: maxSidePx);

  /// El lado más largo de la foto guardada.
  static const maxSidePx = 1200;

  /// El comienzo de la URL de una foto subida (y de la ruta que la sirve).
  static const prefix = '/images/categories/';
}
