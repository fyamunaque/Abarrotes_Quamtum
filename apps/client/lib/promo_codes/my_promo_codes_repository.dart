import '../common/api_client.dart';
import 'my_promo_code.dart';

/// Los códigos de la cuenta: los que activó y activar uno. Las rutas piden
/// el ID token de Firebase. Los errores salen como `ApiFailure` con el
/// mensaje del servidor (p. ej. "El código no existe o ya no está vigente").
abstract interface class MyPromoCodesRepository {
  /// Los que todavía le sirven, los que vencen antes primero.
  Future<List<MyPromoCode>> mine(String idToken);

  /// Activa [code], escrito como sea.
  Future<MyPromoCode> redeem(String idToken, String code);
}

/// [MyPromoCodesRepository] contra `GET /promo-codes/mine` y
/// `POST /promo-codes/redeem`.
class HttpMyPromoCodesRepository implements MyPromoCodesRepository {
  HttpMyPromoCodesRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<MyPromoCode>> mine(String idToken) async {
    final json = await _api.get(
      '/promo-codes/mine',
      idToken: idToken,
      fallback: 'No se pudieron cargar tus códigos.',
    );
    return decodeResponse(
      () => [
        for (final code in json as List<Object?>) MyPromoCode.fromJson(code),
      ],
    );
  }

  @override
  Future<MyPromoCode> redeem(String idToken, String code) async {
    final json = await _api.post(
      '/promo-codes/redeem',
      {'code': code.trim()},
      idToken: idToken,
      fallback: 'No se pudo activar el código.',
    );
    return decodeResponse(() => MyPromoCode.fromJson(json));
  }
}
