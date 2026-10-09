import '../../common/api_client.dart';
import '../../common/page_list.dart';
import 'movement.dart';

/// El historial de inventario y registrar movimientos (solo admin y staff).
/// Los errores salen como `ApiFailure` (p. ej. 409 si una salida deja el
/// stock en negativo).
abstract interface class InventoryRepository {
  /// Una página, el más reciente primero.
  Future<PageList<Movement>> movements({int page = 1});

  Future<Movement> record(MovementInput input);
}

class HttpInventoryRepository implements InventoryRepository {
  HttpInventoryRepository(this._api);

  final AuthedApi _api;

  static const pageSize = 20;

  @override
  Future<PageList<Movement>> movements({int page = 1}) async {
    final json = await _api.get(
      '/inventory/movements',
      query: {'page': '$page', 'limit': '$pageSize'},
      fallback: 'No se pudo cargar el historial.',
    );
    return decodeResponse(() => decodePage(json, Movement.fromJson));
  }

  @override
  Future<Movement> record(MovementInput input) async {
    final json = await _api.post(
      '/inventory/movements',
      input.toJson(),
      fallback: 'No se pudo registrar el movimiento.',
    );
    return decodeResponse(() => Movement.fromJson(json));
  }
}
