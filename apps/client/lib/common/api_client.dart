import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Un error de una ruta REST, ya con el mensaje para la persona.
class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.status});

  final String message;

  /// El status HTTP, o null si no hubo respuesta (sin red, sin respuesta a
  /// tiempo).
  final int? status;

  @override
  String toString() => 'ApiFailure($status): $message';
}

/// Convierte una respuesta con [decode]. Si no tiene la forma esperada (un
/// servidor de otra versión, un proxy que respondió HTML), un [ApiFailure].
T decodeResponse<T>(T Function() decode) {
  try {
    return decode();
  } on FormatException {
    throw const ApiFailure('El servidor respondió algo inesperado.');
  } on TypeError {
    throw const ApiFailure('El servidor respondió algo inesperado.');
  }
}

/// Las rutas REST del servidor (apps/server): arma la URL, manda el ID token
/// de Firebase y convierte cada error en un [ApiFailure] en español.
class ApiClient {
  ApiClient(this._client, {required Uri baseUrl})
    : _base = baseUrl.toString().replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _base;

  static const _timeout = Duration(seconds: 15);

  /// [fallback] es el mensaje si el servidor rechaza la petición sin decir
  /// por qué (un 4xx sin `message`).
  Future<Object?> get(
    String path, {
    Map<String, String>? query,
    String? idToken,
    required String fallback,
  }) => _send(
    () => _client.get(_url(path, query), headers: _headers(idToken)),
    fallback,
  );

  Future<Object?> post(
    String path,
    Object? body, {
    String? idToken,
    required String fallback,
  }) => _send(
    () => _client.post(
      _url(path, null),
      headers: _jsonHeaders(idToken),
      body: jsonEncode(body),
    ),
    fallback,
  );

  Future<Object?> patch(
    String path,
    Object? body, {
    String? idToken,
    required String fallback,
  }) => _send(
    () => _client.patch(
      _url(path, null),
      headers: _jsonHeaders(idToken),
      body: jsonEncode(body),
    ),
    fallback,
  );

  Future<Object?> delete(
    String path, {
    String? idToken,
    required String fallback,
  }) => _send(
    () => _client.delete(_url(path, null), headers: _headers(idToken)),
    fallback,
  );

  /// Manda [bytes] tal cual con PUT (p. ej. una foto, con su
  /// [contentType]). Con más tiempo que el resto: un archivo tarda en subir
  /// con una conexión lenta.
  Future<Object?> putBytes(
    String path,
    List<int> bytes, {
    required String contentType,
    String? idToken,
    required String fallback,
  }) => _send(
    () => _client.put(
      _url(path, null),
      headers: {..._headers(idToken), 'content-type': contentType},
      body: bytes,
    ),
    fallback,
    timeout: _uploadTimeout,
  );

  static const _uploadTimeout = Duration(seconds: 60);

  Map<String, String> _jsonHeaders(String? idToken) => {
    ..._headers(idToken),
    'content-type': 'application/json; charset=utf-8',
  };

  Uri _url(String path, Map<String, String>? query) {
    final url = Uri.parse('$_base$path');
    return query == null || query.isEmpty
        ? url
        : url.replace(queryParameters: query);
  }

  Map<String, String> _headers(String? idToken) => {
    if (idToken != null) 'authorization': 'Bearer $idToken',
  };

  Future<Object?> _send(
    Future<http.Response> Function() request,
    String fallback, {
    Duration timeout = _timeout,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on http.ClientException {
      throw const ApiFailure(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    } on TimeoutException {
      throw const ApiFailure('El servidor no responde. Vuelve a intentar.');
    }

    // El body es JSON en UTF-8; `response.body` usaría latin1 si el
    // Content-Type no dice el charset, y rompería las tildes.
    final body = _decode(utf8.decode(response.bodyBytes, allowMalformed: true));
    final status = response.statusCode;
    if (status >= 200 && status < 300) return body;
    throw ApiFailure(switch (status) {
      401 => 'Tu sesión no es válida. Vuelve a ingresar.',
      >= 500 => 'El servidor no está disponible. Intenta más tarde.',
      // 400, 404 y 409 traen un mensaje para la persona (p. ej. "Stock
      // insuficiente: Aceite tiene 2 unidades").
      _ => _serverMessage(body) ?? fallback,
    }, status: status);
  }

  /// El `message` del error: un texto, o la lista de errores de validación.
  static String? _serverMessage(Object? body) => switch (body) {
    {'message': final String message} when message.isNotEmpty => message,
    {'message': final List<Object?> messages} when messages.isNotEmpty =>
      messages.join('. '),
    _ => null,
  };

  static Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}

/// Las rutas del panel, que piden el ID token de Firebase en cada llamada.
/// [idToken] lo pide a Firebase, que lo renueva solo antes de que venza.
class AuthedApi {
  AuthedApi(this._api, this._idToken);

  final ApiClient _api;
  final Future<String> Function() _idToken;

  Future<Object?> get(
    String path, {
    Map<String, String>? query,
    required String fallback,
  }) async => _api.get(
    path,
    query: query,
    idToken: await _idToken(),
    fallback: fallback,
  );

  Future<Object?> post(
    String path,
    Object? body, {
    required String fallback,
  }) async =>
      _api.post(path, body, idToken: await _idToken(), fallback: fallback);

  Future<Object?> patch(
    String path,
    Object? body, {
    required String fallback,
  }) async =>
      _api.patch(path, body, idToken: await _idToken(), fallback: fallback);

  Future<Object?> delete(String path, {required String fallback}) async =>
      _api.delete(path, idToken: await _idToken(), fallback: fallback);

  Future<Object?> putBytes(
    String path,
    List<int> bytes, {
    required String contentType,
    required String fallback,
  }) async => _api.putBytes(
    path,
    bytes,
    contentType: contentType,
    idToken: await _idToken(),
    fallback: fallback,
  );
}
