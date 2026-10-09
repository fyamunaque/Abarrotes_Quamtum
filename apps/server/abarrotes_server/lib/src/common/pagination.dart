import 'input_reader.dart';

/// Paginación de los listados: `?page=` (desde 1) y
/// `?limit=` (1 a 100, por defecto 20).
class PageQuery {
  const PageQuery(this.page, this.limit);

  static const fields = {'page', 'limit'};

  /// Lee `page` y `limit` del query; los errores quedan en [query].
  factory PageQuery.read(InputReader query) => PageQuery(
    query.integer('page', min: 1, required: false) ?? 1,
    query.integer('limit', min: 1, max: 100, required: false) ?? 20,
  );

  final int page;
  final int limit;

  int get offset => (page - 1) * limit;

  /// `{data, meta}`: la forma que leen todas las tablas de la app.
  Map<String, Object?> wrap(List<Object?> data, int total) => {
    'data': data,
    'meta': {
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': (total / limit).ceil(),
    },
  };
}
