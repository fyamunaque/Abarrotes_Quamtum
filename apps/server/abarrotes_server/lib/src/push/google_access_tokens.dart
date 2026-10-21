import 'dart:async';
import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

/// Una cuenta de servicio de Google: el JSON que se descarga en Firebase
/// (Configuración del proyecto → Cuentas de servicio → Generar nueva clave
/// privada). Es un secreto: no se versiona ni se escribe en el log.
class ServiceAccount {
  const ServiceAccount({
    required this.projectId,
    required this.clientEmail,
    required this.privateKey,
    required this.tokenUri,
  });

  /// Lanza [FormatException] si [json] no es el de una cuenta de servicio
  /// (el mensaje nunca incluye la llave).
  factory ServiceAccount.fromJson(Object? json) => switch (json) {
    {
          'type': 'service_account',
          'project_id': final String projectId,
          'client_email': final String clientEmail,
          'private_key': final String privateKey,
        } &&
        final Map<Object?, Object?> map =>
      ServiceAccount(
        projectId: projectId,
        clientEmail: clientEmail,
        privateKey: privateKey,
        tokenUri: Uri.parse(
          map['token_uri'] as String? ?? 'https://oauth2.googleapis.com/token',
        ),
      ),
    _ => throw const FormatException(
      'No es el JSON de una cuenta de servicio de Google',
    ),
  };

  final String projectId;
  final String clientEmail;
  final String privateKey;
  final Uri tokenUri;

  /// Sin la llave.
  @override
  String toString() => 'ServiceAccount($clientEmail, $projectId)';
}

/// No se pudo obtener un access token. [reason] es para el log.
class AccessTokenException implements Exception {
  const AccessTokenException(this.reason);

  final String reason;

  @override
  String toString() => 'AccessTokenException: $reason';
}

/// Access tokens de OAuth 2.0 para las APIs de Google, con el flujo de
/// cuenta de servicio: un JWT firmado (RS256) con su llave, que Google canjea
/// por un token de una hora. Lo guarda hasta un minuto antes de que venza.
///
/// https://developers.google.com/identity/protocols/oauth2/service-account#httprest
class GoogleAccessTokens {
  GoogleAccessTokens(
    this._account, {
    required this.scope,
    http.Client? client,
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final ServiceAccount _account;
  final String scope;
  final http.Client _client;
  final DateTime Function() _now;

  /// El token se renueva un poco antes de vencer.
  static const margin = Duration(minutes: 1);

  static const _timeout = Duration(seconds: 10);

  String? _token;
  DateTime? _expiresAt;
  Future<String>? _pending;

  /// Un access token vigente. Lanza [AccessTokenException] si no se pudo
  /// obtener.
  Future<String> token() async {
    final now = _now().toUtc();
    if (_token case final token? when now.isBefore(_expiresAt!)) return token;
    // Varios envíos a la vez piden un solo token.
    return _pending ??= _exchange().whenComplete(() => _pending = null);
  }

  Future<String> _exchange() async {
    final issuedAt = _now().toUtc();
    final assertion = _assertion(issuedAt);
    final http.Response response;
    try {
      response = await _client
          .post(
            _account.tokenUri,
            body: {
              'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
              'assertion': assertion,
            },
          )
          .timeout(_timeout);
    } on Exception catch (e) {
      throw AccessTokenException('sin respuesta de Google: ${e.runtimeType}');
    }
    final body = _decode(response.body);
    if (response.statusCode != 200) {
      throw AccessTokenException(
        'Google respondió ${response.statusCode} '
        '(${body?['error'] ?? 'sin detalle'})',
      );
    }
    if (body case {
      'access_token': final String token,
      'expires_in': final int expiresIn,
    }) {
      _token = token;
      _expiresAt = issuedAt.add(Duration(seconds: expiresIn) - margin);
      return token;
    }
    throw const AccessTokenException('respuesta de Google sin access_token');
  }

  /// El JWT que se canjea: lo emite la cuenta de servicio, para [scope], con
  /// una hora de vigencia.
  String _assertion(DateTime issuedAt) {
    final seconds = issuedAt.millisecondsSinceEpoch ~/ 1000;
    try {
      return JWT({
        'iss': _account.clientEmail,
        'scope': scope,
        'aud': _account.tokenUri.toString(),
        'iat': seconds,
        'exp': seconds + 3600,
      }).sign(
        RSAPrivateKey(_account.privateKey),
        algorithm: JWTAlgorithm.RS256,
        noIssueAt: true,
      );
    } on Object catch (e) {
      // Una llave rota: el motivo, nunca la llave.
      throw AccessTokenException(
        'no se pudo firmar con la llave de la cuenta de servicio '
        '(${e.runtimeType})',
      );
    }
  }

  static Map<String, Object?>? _decode(String body) {
    try {
      final json = jsonDecode(body);
      return json is Map<String, Object?> ? json : null;
    } on FormatException {
      return null;
    }
  }
}
