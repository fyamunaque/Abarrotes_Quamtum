/// Una categoría del catálogo (Abarrotes, Lácteos…).
class Category {
  const Category({required this.id, required this.name});

  /// Como la manda el servidor: `{id, name}`.
  factory Category.fromJson(Object? json) => switch (json) {
    {'id': final String id, 'name': final String name} => Category(
      id: id,
      name: name,
    ),
    _ => throw FormatException('No es una categoría', json),
  };

  final String id;
  final String name;
}
