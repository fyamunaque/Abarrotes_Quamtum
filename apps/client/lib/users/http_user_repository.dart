import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_repository.dart';
import '../session/session.dart';
import 'user_repository.dart';

/// [UserRepository] contra las rutas REST del servidor.
class HttpUserRepository implements UserRepository {
  HttpUserRepository(this._client, {required Uri baseUrl})
    : _me = Uri.parse(
        '${baseUrl.toString().replaceFirst(RegExp(r'/+$'), '')}/users/me',
      );

  final http.Client _client;
  final Uri _me;

  static const _timeout = Duration(seconds: 15);

  @override
  Future<SessionUser> me(String idToken) async {
    final http.Response response;
    try {
      response = await _client
          .get(_me, headers: {'authorization': 'Bearer $idToken'})
          .timeout(_timeout);
    } on http.ClientException {
      throw const AuthFailure(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    } on TimeoutException {
      throw const AuthFailure('El servidor no responde. Vuelve a intentar.');
    }

    // El body es JSON en UTF-8; `response.body` usaría latin1 si el
    // Content-Type no dice el charset, y rompería las tildes.
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    return switch (response.statusCode) {
      200 => _user(body),
      401 => throw const AuthFailure(
        'Tu sesión no es válida. Vuelve a ingresar.',
      ),
      >= 500 => throw const AuthFailure(
        'El servidor no está disponible. Intenta más tarde.',
      ),
      // 400 y 409 traen un mensaje para la persona (p. ej. el email ya está
      // registrado con otra cuenta).
      _ => throw AuthFailure(
        _serverMessage(body) ?? 'No se pudo cargar tu cuenta.',
      ),
    };
  }

  SessionUser _user(String body) {
    if (_decode(body) case {
      'id': final String id,
      'name': final String name,
      'email': final String email,
      'role': final String role,
    }) {
      final userRole = UserRole.values.asNameMap()[role];
      if (userRole != null) {
        return SessionUser(id: id, name: name, email: email, role: userRole);
      }
    }
    throw const AuthFailure('El servidor respondió algo inesperado.');
  }

  String? _serverMessage(String body) => switch (_decode(body)) {
    {'message': final String message} when message.isNotEmpty => message,
    _ => null,
  };

  Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}
