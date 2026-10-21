import '../../common/api_client.dart';
import '../../common/page_list.dart';
import 'vip_customer.dart';

/// Los clientes VIP. Admin y staff los ven; solo admin agrega y quita (el
/// servidor responde 403 a los demás). Los errores salen como `ApiFailure`.
abstract interface class VipRepository {
  /// Una página de los VIP activos, por correo. Con [search], los que lo
  /// contienen.
  Future<PageList<VipCustomer>> list({int page = 1, String search = ''});

  /// Agrega [emails] y devuelve qué se agregó, qué ya estaba y qué no es un
  /// correo válido.
  Future<VipAddSummary> add(List<String> emails);

  /// Lo da de baja (no se borra) y lo devuelve.
  Future<VipCustomer> remove(String id);
}

class HttpVipRepository implements VipRepository {
  HttpVipRepository(this._api);

  final AuthedApi _api;

  static const pageSize = 20;

  @override
  Future<PageList<VipCustomer>> list({int page = 1, String search = ''}) async {
    final json = await _api.get(
      '/vip-customers',
      query: {
        'page': '$page',
        'limit': '$pageSize',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
      fallback: 'No se pudieron cargar los clientes VIP.',
    );
    return decodeResponse(() => decodePage(json, VipCustomer.fromJson));
  }

  @override
  Future<VipAddSummary> add(List<String> emails) async {
    final json = await _api.post('/vip-customers', {
      'emails': emails,
    }, fallback: 'No se pudieron agregar los correos.');
    return decodeResponse(() => VipAddSummary.fromJson(json));
  }

  @override
  Future<VipCustomer> remove(String id) async {
    final json = await _api.delete(
      '/vip-customers/${Uri.encodeComponent(id)}',
      fallback: 'No se pudo quitar al cliente VIP.',
    );
    return decodeResponse(() => VipCustomer.fromJson(json));
  }
}
