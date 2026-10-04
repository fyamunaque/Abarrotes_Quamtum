/// Lo que se cargó de una lista paginada (productos, pedidos) y cuántos hay
/// en total.
class PageList<T> {
  const PageList(
    this.items, {
    required this.total,
    this.page = 1,
    this.pageSize = 20,
    this.loadingMore = false,
  });

  final List<T> items;
  final int total;

  /// La página que se pidió (desde 1) y cuántos trae cada página.
  final int page;
  final int pageSize;

  /// Si se está pidiendo la página siguiente.
  final bool loadingMore;

  bool get hasMore => items.length < total;

  /// Para las tablas que van página por página.
  int get pageCount => total == 0 ? 1 : (total / pageSize).ceil();
  bool get hasPrevious => page > 1;
  bool get hasNext => page < pageCount;

  PageList<T> withLoadingMore() => PageList(
    items,
    total: total,
    page: page,
    pageSize: pageSize,
    loadingMore: true,
  );

  /// Esta lista con [next] agregada al final.
  PageList<T> append(PageList<T> next) => PageList(
    [...items, ...next.items],
    total: next.total,
    page: next.page,
    pageSize: next.pageSize,
  );

  /// Esta página con [item] en lugar del que cumple [matches].
  PageList<T> replace(T item, bool Function(T) matches) => PageList(
    [for (final current in items) matches(current) ? item : current],
    total: total,
    page: page,
    pageSize: pageSize,
  );
}

/// Una página como la manda el servidor: `{data, meta: {total, page, limit}}`.
/// Lanza [FormatException] si no tiene esa forma.
PageList<T> decodePage<T>(Object? json, T Function(Object? item) decode) =>
    switch (json) {
      {
        'data': final List<Object?> data,
        'meta': {'total': final int total} && final Map<String, Object?> meta,
      } =>
        PageList(
          [for (final item in data) decode(item)],
          total: total,
          page: meta['page'] as int? ?? 1,
          pageSize: meta['limit'] as int? ?? 20,
        ),
      _ => throw FormatException('No es una página', json),
    };
