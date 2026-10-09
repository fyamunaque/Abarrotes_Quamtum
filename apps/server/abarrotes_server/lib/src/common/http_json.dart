import 'dart:convert';

import 'package:serverpod/serverpod.dart';

const _reasonPhrases = {
  400: 'Bad Request',
  401: 'Unauthorized',
  403: 'Forbidden',
  404: 'Not Found',
  409: 'Conflict',
  413: 'Content Too Large',
  503: 'Service Unavailable',
};

/// Error que una ruta convierte en respuesta con [jsonError].
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  const ApiException.badRequest(Object message) : this(400, message);
  const ApiException.forbidden(String message) : this(403, message);
  const ApiException.conflict(String message) : this(409, message);

  final int statusCode;

  /// Un texto, o una lista de textos si falló la validación.
  final Object message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Respuesta con [body] serializado como JSON.
Response jsonResponse(int statusCode, Object? body) => Response(
  statusCode,
  body: Body.fromString(jsonEncode(body), mimeType: MimeType.json),
);

/// Error con una forma fija, la que lee la app:
/// `{statusCode, message, error}`. [message] es un texto o una lista de textos.
Response jsonError(int statusCode, Object message) => jsonResponse(statusCode, {
  'statusCode': statusCode,
  'message': message,
  'error': ?_reasonPhrases[statusCode],
});

/// Ejecuta [action] y convierte un [ApiException] en su respuesta JSON.
Future<Response> withApiErrors(Future<Response> Function() action) async {
  try {
    return await action();
  } on ApiException catch (e) {
    return jsonError(e.statusCode, e.message);
  }
}

/// Lee el body como JSON. Lanza [ApiException] si no es JSON o pesa más de
/// [maxBytes].
Future<Object?> readJsonBody(
  Request request, {
  int maxBytes = 16 * 1024,
}) async {
  final String text;
  try {
    text = await request.readAsString(maxLength: maxBytes);
  } on MaxBodySizeExceeded {
    throw ApiException(413, 'El body supera los $maxBytes bytes');
  }
  try {
    return jsonDecode(text);
  } on FormatException {
    throw const ApiException.badRequest('El body debe ser JSON válido');
  }
}
