/// Las fotos grandes de la marca (portada, banda de promociones). Son del
/// cliente, con derecho de uso: mientras no lleguen, cada una es `null` y se
/// ve el bloque rojo con la franja diagonal y el logo en blanco.
///
/// Para activar una: agregar el archivo a `assets/images/` (está en el
/// pubspec) y poner aquí su ruta, p. ej. `'assets/images/portada.jpg'`.
abstract final class BrandImages {
  /// La portada: horizontal, de al menos 1600 px de ancho.
  static const String? hero = null;

  /// La banda "Promociones para tu negocio".
  static const String? promotionsBanner = null;
}
