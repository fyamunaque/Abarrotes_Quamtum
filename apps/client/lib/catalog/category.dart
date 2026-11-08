/// Una categoría del catálogo (Abarrotes, Lácteos…), con la línea de su
/// encabezado en la tienda y su foto, si las tiene.
class Category {
  const Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  /// Como la manda el servidor: `{id, name, description, imageUrl}`. Un
  /// servidor anterior solo manda `{id, name}`.
  factory Category.fromJson(Object? json) => switch (json) {
    {'id': final String id, 'name': final String name} => Category(
      id: id,
      name: name,
      description: switch ((json as Map)['description']) {
        final String text when text.isNotEmpty => text,
        _ => null,
      },
      imageUrl: switch (json['imageUrl']) {
        final String url when url.isNotEmpty => url,
        _ => null,
      },
    ),
    _ => throw FormatException('No es una categoría', json),
  };

  final String id;
  final String name;

  /// "Hot dogs, jamonadas y más", para el encabezado de la categoría.
  final String? description;

  /// La foto: una ruta relativa al servidor (`/images/categories/…`) o una
  /// URL externa.
  final String? imageUrl;
}
