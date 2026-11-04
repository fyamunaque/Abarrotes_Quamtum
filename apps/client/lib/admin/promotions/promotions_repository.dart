import '../../common/api_client.dart';
import '../../common/page_list.dart';
import 'promotion.dart';

/// Las promociones (solo admin y staff). Los errores salen como
/// `ApiFailure` (p. ej. 400 si el precio no es menor que el normal); si se
/// cruza con otras promociones del producto, [PromotionOverlap] con la
/// lista: con `confirmOverlap` se guarda igual (se acumulan).
abstract interface class PromotionsRepository {
  /// Una página, el inicio más reciente primero. Con [status], solo las que
  /// hoy están en ese estado.
  Future<PageList<Promotion>> list({int page = 1, PromotionStatus? status});

  /// [input] con producto.
  Future<Promotion> create(PromotionInput input, {bool confirmOverlap});

  Future<Promotion> update(
    String id,
    PromotionInput input, {
    bool confirmOverlap,
  });

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
  Future<Promotion> create(
    PromotionInput input, {
    bool confirmOverlap = false,
  }) async {
    final json = await _overlaps(
      () => _api.post(
        '/promotions',
        _body(input, confirmOverlap),
        fallback: 'No se pudo crear la promoción.',
      ),
    );
    return decodeResponse(() => Promotion.fromJson(json));
  }

  @override
  Future<Promotion> update(
    String id,
    PromotionInput input, {
    bool confirmOverlap = false,
  }) async {
    final json = await _overlaps(
      () => _api.patch(
        '/promotions/${Uri.encodeComponent(id)}',
        _body(input, confirmOverlap),
        fallback: 'No se pudo guardar la promoción.',
      ),
    );
    return decodeResponse(() => Promotion.fromJson(json));
  }

  static Map<String, Object?> _body(PromotionInput input, bool confirm) => {
    ...input.toJson(),
    if (confirm) 'confirmOverlap': true,
  };

  /// El 409 con la lista de las que se cruzan, como [PromotionOverlap].
  static Future<Object?> _overlaps(Future<Object?> Function() send) async {
    try {
      return await send();
    } on ApiFailure catch (failure) {
      if (failure.details['overlaps'] case final List<Object?> overlaps
          when failure.status == 409) {
        throw PromotionOverlap(
          decodeResponse(
            () => [
              for (final item in overlaps)
                switch (item) {
                  {
                    'label': final String label,
                    'audience': final String audience,
                    'startDate': final String startDate,
                    'endDate': final String endDate,
                  } =>
                    (
                      label: label,
                      audience:
                          PromotionAudience.values.asNameMap()[audience] ??
                          PromotionAudience.everyone,
                      startDate: startDate,
                      endDate: endDate,
                    ),
                  _ => throw FormatException('No es un cruce', item),
                },
            ],
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) => _api.delete(
    '/promotions/${Uri.encodeComponent(id)}',
    fallback: 'No se pudo eliminar la promoción.',
  );
}
