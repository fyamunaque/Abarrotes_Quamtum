import '../../common/api_client.dart';
import '../../common/days.dart';
import '../../common/page_list.dart';
import 'movement.dart';

/// El historial de inventario y registrar movimientos (solo admin y staff).
/// Los errores salen como `ApiFailure` (p. ej. 409 si una salida deja el
/// stock en negativo).
abstract interface class InventoryRepository {
  /// Una página, el más reciente primero. Con [origin], solo los de pedidos
  /// o los manuales; con [categoryId], los de sus productos; [search], por
  /// nombre o SKU del producto, o el N.º del pedido. [from] y [to] son días
  /// de la tienda, ambos incluidos.
  Future<PageList<Movement>> movements({
    int page = 1,
    String? search,
    MovementOrigin? origin,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  });

  Future<Movement> record(MovementInput input);
}

class HttpInventoryRepository implements InventoryRepository {
  HttpInventoryRepository(this._api);

  final AuthedApi _api;

  static const pageSize = 20;

  @override
  Future<PageList<Movement>> movements({
    int page = 1,
    String? search,
    MovementOrigin? origin,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    final json = await _api.get(
      '/inventory/movements',
      query: {
        'page': '$page',
        'limit': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        'origin': ?origin?.name,
        'categoryId': ?categoryId,
        if (from != null) 'from': formatDay(from),
        if (to != null) 'to': formatDay(to),
      },
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
