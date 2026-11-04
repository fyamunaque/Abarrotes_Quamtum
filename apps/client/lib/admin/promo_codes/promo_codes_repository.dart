import '../../common/api_client.dart';
import '../../common/page_list.dart';
import 'promo_code.dart';

/// Los códigos promocionales del panel (`/promo-codes`, con
/// `promotions.manage`). Los errores salen como `ApiFailure` con el mensaje
/// del servidor (p. ej. 409 "Ya existe el código VERANO-10"). Sus
/// promociones se crean con `PromotionsRepository`.
abstract interface class PromoCodesRepository {
  /// Una página, los creados más recientemente primero. Con [status], solo
  /// los que hoy están en ese estado; con [search], los que tienen ese texto.
  Future<PageList<PromoCode>> list({
    int page = 1,
    PromoCodeStatus? status,
    String search = '',
  });

  Future<PromoCode> get(String id);

  Future<PromoCode> create(PromoCodeInput input);

  Future<PromoCode> update(String id, PromoCodeInput input);

  Future<void> delete(String id);
}

class HttpPromoCodesRepository implements PromoCodesRepository {
  HttpPromoCodesRepository(this._api);

  final AuthedApi _api;

  static const pageSize = 20;

  @override
  Future<PageList<PromoCode>> list({
    int page = 1,
    PromoCodeStatus? status,
    String search = '',
  }) async {
    final json = await _api.get(
      '/promo-codes',
      query: {
        'page': '$page',
        'limit': '$pageSize',
        'status': ?status?.name,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
      fallback: 'No se pudieron cargar los códigos.',
    );
    return decodeResponse(() => decodePage(json, PromoCode.fromJson));
  }

  @override
  Future<PromoCode> get(String id) async {
    final json = await _api.get(
      '/promo-codes/${Uri.encodeComponent(id)}',
      fallback: 'No se pudo cargar el código.',
    );
    return decodeResponse(() => PromoCode.fromJson(json));
  }

  @override
  Future<PromoCode> create(PromoCodeInput input) async {
    final json = await _api.post(
      '/promo-codes',
      input.toJson(),
      fallback: 'No se pudo crear el código.',
    );
    return decodeResponse(() => PromoCode.fromJson(json));
  }

  @override
  Future<PromoCode> update(String id, PromoCodeInput input) async {
    final json = await _api.patch(
      '/promo-codes/${Uri.encodeComponent(id)}',
      input.toJson(),
      fallback: 'No se pudo guardar el código.',
    );
    return decodeResponse(() => PromoCode.fromJson(json));
  }

  @override
  Future<void> delete(String id) => _api.delete(
    '/promo-codes/${Uri.encodeComponent(id)}',
    fallback: 'No se pudo eliminar el código.',
  );
}
