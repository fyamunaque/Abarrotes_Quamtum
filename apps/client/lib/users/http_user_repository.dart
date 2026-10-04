import '../auth/auth_repository.dart';
import '../common/api_client.dart';
import '../session/session.dart';
import 'user_repository.dart';

/// [UserRepository] contra las rutas REST del servidor.
class HttpUserRepository implements UserRepository {
  HttpUserRepository(this._api);

  final ApiClient _api;

  @override
  Future<SessionUser> me(String idToken) async {
    final Object? json;
    try {
      json = await _api.get(
        '/users/me',
        idToken: idToken,
        fallback: 'No se pudo cargar tu cuenta.',
      );
    } on ApiFailure catch (failure) {
      // La sesión trata cualquier error del perfil como AuthFailure.
      throw AuthFailure(failure.message);
    }
    return _user(json);
  }

  SessionUser _user(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'email': final String email,
      'role': final String role,
    }) {
      final userRole = UserRole.values.asNameMap()[role];
      if (userRole != null) {
        return SessionUser(
          id: id,
          name: name,
          email: email,
          role: userRole,
          address: json['address'] as String?,
        );
      }
    }
    throw const AuthFailure('El servidor respondió algo inesperado.');
  }
}
