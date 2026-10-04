import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'firebase_identity.dart';
import 'google_public_keys.dart';

/// Verifica Firebase ID tokens según
/// https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library
class FirebaseTokenVerifier {
  FirebaseTokenVerifier({
    required this.projectId,
    required this._keys,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Tolerancia para `iat` y `auth_time`: los emite el reloj de Google, que
  /// puede ir unos segundos por delante del nuestro.
  static const clockSkew = Duration(minutes: 1);

  final String projectId;
  final PublicKeySource _keys;
  final DateTime Function() _now;

  String get _issuer => 'https://securetoken.google.com/$projectId';

  /// La identidad del token, o [InvalidFirebaseTokenException] si no es válido.
  /// Si no se pueden obtener las llaves de Google, lanza
  /// [PublicKeysUnavailableException].
  Future<FirebaseIdentity> verify(String token) async {
    final parts = token.split('.');
    if (parts.length != 3) throw _invalid('no tiene tres partes');
    final header = _decodeJson(parts[0], 'header');
    final claims = _decodeJson(parts[1], 'payload');

    if (header['alg'] != 'RS256') {
      throw _invalid('algoritmo ${header['alg']} en vez de RS256');
    }
    final kid = header['kid'];
    if (kid is! String || kid.isEmpty) throw _invalid('sin kid');
    final key = await _keys.keyFor(kid);
    if (key == null) throw _invalid('kid desconocido');
    if (!_signatureMatches(key, parts)) throw _invalid('firma inválida');

    final now = _now().toUtc();
    if (!_seconds(claims, 'exp').isAfter(now)) throw _invalid('vencido');
    final latest = now.add(clockSkew);
    if (_seconds(claims, 'iat').isAfter(latest)) throw _invalid('iat futuro');
    if (_seconds(claims, 'auth_time').isAfter(latest)) {
      throw _invalid('auth_time futuro');
    }
    if (claims['aud'] != projectId) throw _invalid('aud de otro proyecto');
    if (claims['iss'] != _issuer) throw _invalid('iss de otro proyecto');
    final uid = claims['sub'];
    if (uid is! String || uid.isEmpty || uid.length > 128) {
      throw _invalid('sub vacío o demasiado largo');
    }

    return FirebaseIdentity(
      uid: uid,
      email: claims['email'] is String ? claims['email'] as String : null,
      emailVerified: claims['email_verified'] == true,
      name: claims['name'] is String ? claims['name'] as String : null,
    );
  }

  static bool _signatureMatches(JWTKey key, List<String> parts) {
    try {
      return JWTAlgorithm.RS256.verify(
        key,
        Uint8List.fromList(utf8.encode('${parts[0]}.${parts[1]}')),
        _decodeBase64(parts[2]),
      );
    } on FormatException {
      return false;
    }
  }

  static Map<String, dynamic> _decodeJson(String part, String name) {
    try {
      final value = jsonDecode(utf8.decode(_decodeBase64(part)));
      if (value is Map<String, dynamic>) return value;
    } on FormatException {
      // Cae al error de abajo.
    }
    throw _invalid('$name ilegible');
  }

  static Uint8List _decodeBase64(String part) =>
      base64Url.decode(base64Url.normalize(part));

  static DateTime _seconds(Map<String, dynamic> claims, String claim) {
    final value = claims[claim];
    if (value is! num) throw _invalid('sin $claim');
    return DateTime.fromMillisecondsSinceEpoch(
      (value * 1000).round(),
      isUtc: true,
    );
  }

  static InvalidFirebaseTokenException _invalid(String reason) =>
      InvalidFirebaseTokenException(reason);
}
