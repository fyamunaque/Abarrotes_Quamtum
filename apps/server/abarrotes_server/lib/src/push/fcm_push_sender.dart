import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'google_access_tokens.dart';
import 'push_sender.dart';

/// [PushSender] con la REST API de FCM (HTTP v1): un mensaje por token, nunca
/// por topic (un topic lo puede suscribir cualquiera desde el cliente).
///
/// https://firebase.google.com/docs/cloud-messaging/send/v1-api
class FcmPushSender implements PushSender {
  FcmPushSender({
    required this.projectId,
    required this._accessTokens,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// El scope de OAuth para mandar con FCM.
  static const scope = 'https://www.googleapis.com/auth/firebase.messaging';

  final String projectId;
  final GoogleAccessTokens _accessTokens;
  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  Uri get _url => Uri.parse(
    'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
  );

  @override
  bool get enabled => true;

  @override
  Future<PushOutcome> send(String token, PushMessage message) async {
    final String accessToken;
    try {
      accessToken = await _accessTokens.token();
    } on AccessTokenException catch (e) {
      return (result: PushResult.failed, reason: e.reason);
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            _url,
            headers: {
              'authorization': 'Bearer $accessToken',
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({
              'message': {
                'token': token,
                'notification': {'title': message.title, 'body': message.body},
                if (message.data.isNotEmpty) 'data': message.data,
              },
            }),
          )
          .timeout(_timeout);
    } on Exception catch (e) {
      return (
        result: PushResult.failed,
        reason: 'sin respuesta de FCM: ${e.runtimeType}',
      );
    }

    if (response.statusCode == 200) {
      return (result: PushResult.sent, reason: null);
    }
    final error = _error(response.body);
    return (
      result: _isInvalidToken(response.statusCode, error)
          ? PushResult.invalidToken
          : PushResult.failed,
      reason:
          'FCM respondió ${response.statusCode} '
          '(${error.code ?? error.status ?? 'sin detalle'})',
    );
  }

  /// El token ya no sirve: FCM lo dice con el errorCode UNREGISTERED, o con un
  /// 400 por el campo message.token. Un 404 sin eso (p. ej. otro proyecto)
  /// no borra nada: sería un error de configuración, no del token.
  static bool _isInvalidToken(
    int status,
    ({String? status, String? code, String? field}) error,
  ) =>
      error.code == 'UNREGISTERED' ||
      (status == 400 && error.field == 'message.token');

  /// `error.status`, el `errorCode` de FCM y el campo inválido, si vienen.
  static ({String? status, String? code, String? field}) _error(String body) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return (status: null, code: null, field: null);
    }
    if (json case {'error': final Map<String, Object?> error}) {
      String? code;
      String? field;
      for (final detail in error['details'] as List<Object?>? ?? const []) {
        if (detail case {'errorCode': final String errorCode}) {
          code = errorCode;
        }
        if (detail case {
          'fieldViolations': [{'field': final String violated}, ...],
        }) {
          field = violated;
        }
      }
      return (status: error['status'] as String?, code: code, field: field);
    }
    return (status: null, code: null, field: null);
  }
}
