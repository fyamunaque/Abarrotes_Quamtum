import 'dart:async';
import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

import 'firebase_identity.dart';

/// Llaves con las que se firman los ID tokens, buscadas por `kid`.
abstract interface class PublicKeySource {
  /// La llave de [kid], o null si no existe.
  ///
  /// Lanza [PublicKeysUnavailableException] si no hay llaves vigentes y no se
  /// pudieron descargar.
  Future<JWTKey?> keyFor(String kid);
}

/// Las llaves públicas con las que Google firma los Firebase ID tokens.
///
/// Las guarda en memoria hasta el `max-age` que indica Google en
/// `Cache-Control`. Si llega un `kid` que no conoce (Google rotó las llaves),
/// vuelve a descargarlas. Entre dos intentos de descarga forzados, o después
/// de una descarga fallida, espera al menos [minRefreshInterval].
class GooglePublicKeys implements PublicKeySource {
  GooglePublicKeys({
    http.Client? client,
    DateTime Function()? now,
    Uri? url,
    this.minRefreshInterval = const Duration(minutes: 1),
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now,
       _url = url ?? defaultUrl;

  /// Certificados X.509 de securetoken@system.gserviceaccount.com, por `kid`.
  static final defaultUrl = Uri.parse(
    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
  );

  /// Vigencia de las llaves si la respuesta no trae `max-age`.
  static const defaultMaxAge = Duration(hours: 1);

  final http.Client _client;
  final DateTime Function() _now;
  final Uri _url;
  final Duration minRefreshInterval;

  Map<String, JWTKey> _keys = const {};
  DateTime? _expiresAt;
  DateTime? _attemptedAt;
  DateTime? _failedAt;
  Future<void>? _inFlight;

  @override
  Future<JWTKey?> keyFor(String kid) async {
    if (!_hasFreshKeys) await _refresh();
    final key = _keys[kid];
    if (key != null || _attemptedRecently) return key;

    try {
      await _refresh();
    } on PublicKeysUnavailableException {
      // Las llaves que ya tenemos siguen vigentes; solo este kid es desconocido.
      return null;
    }
    return _keys[kid];
  }

  bool get _hasFreshKeys {
    final expiresAt = _expiresAt;
    return expiresAt != null && _now().isBefore(expiresAt);
  }

  bool get _attemptedRecently => _isRecent(_attemptedAt);

  bool _isRecent(DateTime? time) =>
      time != null && _now().difference(time) < minRefreshInterval;

  /// Una sola descarga a la vez: quienes llegan mientras tanto la comparten.
  Future<void> _refresh() {
    if (_inFlight case final inFlight?) return inFlight;
    if (_isRecent(_failedAt)) {
      return Future.error(
        const PublicKeysUnavailableException(
          'la última descarga falló hace menos de un minuto',
        ),
      );
    }
    return _inFlight = _download().whenComplete(() => _inFlight = null);
  }

  Future<void> _download() async {
    _attemptedAt = _now();
    try {
      final (keys, maxAge) = await _fetch();
      _keys = keys;
      _expiresAt = _now().add(maxAge ?? defaultMaxAge);
      _failedAt = null;
    } on PublicKeysUnavailableException {
      _failedAt = _now();
      rethrow;
    }
  }

  Future<(Map<String, JWTKey>, Duration?)> _fetch() async {
    final http.Response response;
    try {
      response = await _client.get(_url).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw PublicKeysUnavailableException('no se pudo descargar: $e');
    }
    if (response.statusCode != 200) {
      throw PublicKeysUnavailableException(
        'Google respondió ${response.statusCode}',
      );
    }

    final keys = <String, JWTKey>{};
    try {
      final certificates = jsonDecode(response.body);
      if (certificates is! Map<String, dynamic>) {
        throw const FormatException('se esperaba un objeto kid -> certificado');
      }
      for (final MapEntry(key: kid, value: pem) in certificates.entries) {
        if (pem is String) keys[kid] = RSAPublicKey.cert(pem);
      }
    } catch (e) {
      throw PublicKeysUnavailableException('respuesta inválida: $e');
    }
    if (keys.isEmpty) {
      throw const PublicKeysUnavailableException('la respuesta no trae llaves');
    }
    return (keys, _maxAge(response.headers['cache-control']));
  }

  static Duration? _maxAge(String? cacheControl) {
    final match = RegExp(r'max-age=(\d+)').firstMatch(cacheControl ?? '');
    return match == null ? null : Duration(seconds: int.parse(match[1]!));
  }
}
