import '../common/api_client.dart';
import 'store_settings.dart';

/// Los datos de la tienda. Los errores salen como `ApiFailure`.
abstract interface class StoreRepository {
  /// `GET /store`: público, sin cuenta.
  Future<StoreSettings> settings();
}

class HttpStoreRepository implements StoreRepository {
  HttpStoreRepository(this._api);

  final ApiClient _api;

  @override
  Future<StoreSettings> settings() async {
    final json = await _api.get(
      '/store',
      fallback: 'No se pudieron cargar los datos de la tienda.',
    );
    return decodeResponse(() => StoreSettings.fromJson(json));
  }
}
