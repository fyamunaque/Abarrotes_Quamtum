import '../auth/auth_repository.dart';
import '../common/api_client.dart';
import '../legal/legal_texts.dart';
import '../session/session.dart';
import '../session/staff_permission.dart';
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

  @override
  Future<SessionUser> updateProfile(
    String idToken, {
    String? phone,
    String? dni,
    bool clearDni = false,
    bool acceptTerms = false,
  }) async {
    final json = await _api.patch(
      '/users/me',
      {
        'phone': ?phone,
        if (clearDni) 'dni': null else 'dni': ?dni,
        if (acceptTerms) 'acceptTerms': termsVersion,
      },
      idToken: idToken,
      fallback: 'No se pudieron guardar tus datos.',
    );
    try {
      return _user(json);
    } on AuthFailure catch (failure) {
      throw ApiFailure(failure.message);
    }
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
          phone: json['phone'] as String?,
          dni: json['dni'] as String?,
          termsVersion: json['termsVersion'] as String?,
          termsAcceptedAt: switch (json['termsAcceptedAt']) {
            final String at => DateTime.parse(at),
            _ => null,
          },
          // Sin el campo (un servidor anterior, que no lo pide), completo.
          profileComplete: json['profileComplete'] != false,
          isVip: json['isVip'] == true,
          staffRoleName: switch (json['staffRole']) {
            {'name': final String name} => name,
            _ => null,
          },
          // Sin el campo (un servidor anterior), ninguno.
          permissions: switch (json['permissions']) {
            final List<Object?> keys => StaffPermission.fromKeys(keys),
            _ => const {},
          },
        );
      }
    }
    throw const AuthFailure('El servidor respondió algo inesperado.');
  }
}
