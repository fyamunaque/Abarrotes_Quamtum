/// Lo que se cargó de una lista paginada (productos, pedidos) y cuántos hay
/// en total.
class PageList<T> {
  const PageList(this.items, {required this.total, this.loadingMore = false});

  final List<T> items;
  final int total;

  /// Si se está pidiendo la página siguiente.
  final bool loadingMore;

  bool get hasMore => items.length < total;

  PageList<T> withLoadingMore() =>
      PageList(items, total: total, loadingMore: true);

  /// Esta lista con [next] agregada al final.
  PageList<T> append(PageList<T> next) =>
      PageList([...items, ...next.items], total: next.total);
}
