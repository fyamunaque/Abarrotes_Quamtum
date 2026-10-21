import '../common/api_client.dart';
import '../common/page_list.dart';
import 'offer.dart';

/// Las ofertas exclusivas de la cuenta abierta. Los errores salen como
/// `ApiFailure`.
abstract interface class OffersRepository {
  /// Las promociones VIP vigentes que la cuenta puede usar. El servidor solo
  /// las manda a un cliente VIP con el correo verificado: a los demás, nada.
  Future<List<Offer>> exclusive();
}

/// [OffersRepository] contra `GET /promotions/active`, con el ID token de la
/// cuenta abierta ([idToken]). La ruta trae también las promociones para
/// todos: aquí quedan solo las VIP.
class HttpOffersRepository implements OffersRepository {
  HttpOffersRepository(this._api, {required this._idToken});

  final ApiClient _api;
  final Future<String?> Function() _idToken;

  /// Lo más que da el servidor por página: alcanza para las de una tienda.
  static const limit = 100;

  @override
  Future<List<Offer>> exclusive() async {
    final json = await _api.get(
      '/promotions/active',
      query: {'limit': '$limit'},
      idToken: await _idToken(),
      fallback: 'No se pudieron cargar las ofertas.',
    );
    return decodeResponse(
      () => [
        for (final offer in decodePage(json, Offer.fromJson).items)
          if (offer.vip) offer,
      ],
    );
  }
}
