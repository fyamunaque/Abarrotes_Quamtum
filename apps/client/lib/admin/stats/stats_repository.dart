import '../../common/api_client.dart';
import 'stats.dart';

/// Los reportes del inicio del panel (`/stats/*`, solo admin y staff). Los
/// errores salen como `ApiFailure`.
abstract interface class StatsRepository {
  Future<StatsOverview> overview();

  /// Los últimos 30 días, un punto por día.
  Future<SalesReport> sales30Days();

  /// Los más vendidos de los últimos 30 días.
  Future<List<TopProduct>> topProducts({int limit = 5});

  Future<List<LowStockItem>> lowStock();

  /// Los que vencen hasta dentro de [days] días (y los ya vencidos).
  Future<List<ExpiringItem>> expiring({int days = 7});
}

class HttpStatsRepository implements StatsRepository {
  HttpStatsRepository(this._api);

  final AuthedApi _api;

  static const _fallback = 'No se pudo cargar el reporte.';

  @override
  Future<StatsOverview> overview() async {
    final json = await _api.get('/stats/overview', fallback: _fallback);
    return decodeResponse(() => StatsOverview.fromJson(json));
  }

  @override
  Future<SalesReport> sales30Days() async {
    final json = await _api.get('/stats/sales', fallback: _fallback);
    return decodeResponse(() => SalesReport.fromJson(json));
  }

  @override
  Future<List<TopProduct>> topProducts({int limit = 5}) async {
    final json = await _api.get(
      '/stats/top-products',
      query: {'limit': '$limit'},
      fallback: _fallback,
    );
    return decodeResponse(() => _data(json, TopProduct.fromJson));
  }

  @override
  Future<List<LowStockItem>> lowStock() async {
    final json = await _api.get('/stats/low-stock', fallback: _fallback);
    return decodeResponse(() => _data(json, LowStockItem.fromJson));
  }

  @override
  Future<List<ExpiringItem>> expiring({int days = 7}) async {
    final json = await _api.get(
      '/stats/expiring',
      query: {'days': '$days'},
      fallback: _fallback,
    );
    return decodeResponse(() => _data(json, ExpiringItem.fromJson));
  }

  /// `{data: [...]}`.
  static List<T> _data<T>(Object? json, T Function(Object?) decode) =>
      switch (json) {
        {'data': final List<Object?> data} => [
          for (final item in data) decode(item),
        ],
        _ => throw FormatException('No es una lista', json),
      };
}
