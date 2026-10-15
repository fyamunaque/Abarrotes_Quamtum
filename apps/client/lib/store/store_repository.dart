import '../common/api_client.dart';
import 'store_settings.dart';

/// Los datos de la tienda. Los errores salen como `ApiFailure`.
abstract interface class StoreRepository {
  /// `GET /store`: público, sin cuenta.
  Future<StoreSettings> settings();

  /// `PATCH /store` (con `store.manage`): guarda [settings] y devuelve
  /// cómo quedaron. Los campos opcionales en null se borran.
  Future<StoreSettings> update(StoreSettings settings);
}

class HttpStoreRepository implements StoreRepository {
  HttpStoreRepository(this._api, this._authed);

  final ApiClient _api;
  final AuthedApi _authed;

  @override
  Future<StoreSettings> update(StoreSettings settings) async {
    final json = await _authed.patch('/store', {
      'name': settings.name,
      'address': settings.address,
      'reference': settings.reference,
      'phone': settings.phone,
      'openingHours': settings.openingHours,
      'pickupInstructions': settings.pickupInstructions,
    }, fallback: 'No se pudieron guardar los datos de la tienda.');
    return decodeResponse(() => StoreSettings.fromJson(json));
  }

  @override
  Future<StoreSettings> settings() async {
    final json = await _api.get(
      '/store',
      fallback: 'No se pudieron cargar los datos de la tienda.',
    );
    return decodeResponse(() => StoreSettings.fromJson(json));
  }
}
