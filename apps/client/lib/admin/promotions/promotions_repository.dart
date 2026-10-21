import '../../common/api_client.dart';
import '../../common/page_list.dart';
import 'promotion.dart';

/// Las promociones (solo admin y staff). Los errores salen como
/// `ApiFailure` (p. ej. 400 si el precio no es menor que el normal, 409 si se
/// cruza con otra promoción del producto para la misma audiencia).
abstract interface class PromotionsRepository {
  /// Una página, el inicio más reciente primero. Con [status], solo las que
  /// hoy están en ese estado.
  Future<PageList<Promotion>> list({int page = 1, PromotionStatus? status});

  /// [input] con producto.
  Future<Promotion> create(PromotionInput input);

  Future<Promotion> update(String id, PromotionInput input);

  Future<void> delete(String id);
}

class HttpPromotionsRepository implements PromotionsRepository {
  HttpPromotionsRepository(this._api);

  final AuthedApi _api;

  static const pageSize = 20;

  @override
  Future<PageList<Promotion>> list({
    int page = 1,
    PromotionStatus? status,
  }) async {
    final json = await _api.get(
      '/promotions',
      query: {'page': '$page', 'limit': '$pageSize', 'status': ?status?.name},
      fallback: 'No se pudieron cargar las promociones.',
    );
    return decodeResponse(() => decodePage(json, Promotion.fromJson));
  }

  @override
  Future<Promotion> create(PromotionInput input) async {
    final json = await _api.post(
      '/promotions',
      input.toJson(),
      fallback: 'No se pudo crear la promoción.',
    );
    return decodeResponse(() => Promotion.fromJson(json));
  }

  @override
  Future<Promotion> update(String id, PromotionInput input) async {
    final json = await _api.patch(
      '/promotions/${Uri.encodeComponent(id)}',
      input.toJson(),
      fallback: 'No se pudo guardar la promoción.',
    );
    return decodeResponse(() => Promotion.fromJson(json));
  }

  @override
  Future<void> delete(String id) => _api.delete(
    '/promotions/${Uri.encodeComponent(id)}',
    fallback: 'No se pudo eliminar la promoción.',
  );
}
