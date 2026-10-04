import 'dart:convert';

import 'package:serverpod/serverpod.dart';

const _reasonPhrases = {
  400: 'Bad Request',
  401: 'Unauthorized',
  403: 'Forbidden',
  404: 'Not Found',
  409: 'Conflict',
  503: 'Service Unavailable',
};

/// Respuesta con [body] serializado como JSON.
Response jsonResponse(int statusCode, Object? body) => Response(
  statusCode,
  body: Body.fromString(jsonEncode(body), mimeType: MimeType.json),
);

/// Error con la misma forma que los de la API NestJS:
/// `{statusCode, message, error}`. [message] es un texto o una lista de textos.
Response jsonError(int statusCode, Object message) => jsonResponse(statusCode, {
  'statusCode': statusCode,
  'message': message,
  'error': ?_reasonPhrases[statusCode],
});
