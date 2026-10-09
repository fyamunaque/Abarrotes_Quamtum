import 'package:serverpod/serverpod.dart';

import '../auth/firebase_identity.dart';
import '../common/http_json.dart';
import '../generated/protocol.dart';
import 'create_user_request.dart';

/// Cuentas de usuario: el vínculo entre un uid de Firebase y su rol.
class UsersService {
  const UsersService();

  /// El usuario de [identity]. La primera vez lo crea como cliente con el
  /// email y el nombre del token.
  Future<User> findOrCreate(Session session, FirebaseIdentity identity) async {
    final existing = await _findByFirebaseUid(session, identity.uid);
    if (existing != null) return existing;

    final email = identity.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      throw const ApiException.badRequest(
        'La cuenta de Firebase no tiene email: inicia sesión con email o Google',
      );
    }
    if (await _findByEmail(session, email) != null) {
      throw const ApiException.conflict(
        'Ese email ya está registrado con otra cuenta',
      );
    }

    try {
      return await User.db.insertRow(
        session,
        User(
          firebaseUid: identity.uid,
          email: email,
          name: _displayName(identity.name, email),
          role: UserRole.customer,
        ),
      );
    } on DatabaseUniqueViolationException {
      // Dos primeros inicios de sesión simultáneos: el otro ya lo creó.
      final created = await _findByFirebaseUid(session, identity.uid);
      if (created != null) return created;
      throw const ApiException.conflict(
        'Ese email ya está registrado con otra cuenta',
      );
    }
  }

  /// Crea una cuenta admin o staff. Es la única forma de tener esos roles.
  /// La ruta ya pasó por `RoleGuard`; la regla se repite aquí por si el
  /// servicio se usa desde otro lado.
  Future<User> createStaff(
    Session session, {
    required User admin,
    required CreateUserRequest input,
  }) async {
    if (admin.role != UserRole.admin) {
      throw const ApiException.forbidden(
        'Solo un administrador puede crear cuentas admin o staff',
      );
    }
    if (input.role == UserRole.customer) {
      throw const ApiException.badRequest(['role debe ser admin o staff']);
    }
    if (await _findByFirebaseUid(session, input.firebaseUid) != null) {
      throw const ApiException.conflict(
        'Ya existe un usuario con ese firebaseUid',
      );
    }
    if (await _findByEmail(session, input.email) != null) {
      throw const ApiException.conflict('Ya existe un usuario con ese email');
    }

    try {
      return await User.db.insertRow(
        session,
        User(
          firebaseUid: input.firebaseUid,
          email: input.email,
          name: input.name,
          phone: input.phone,
          address: input.address,
          role: input.role,
        ),
      );
    } on DatabaseUniqueViolationException {
      throw const ApiException.conflict(
        'Ya existe un usuario con ese firebaseUid o email',
      );
    }
  }

  Future<User?> _findByFirebaseUid(Session session, String firebaseUid) =>
      User.db.findFirstRow(
        session,
        where: (user) => user.firebaseUid.equals(firebaseUid),
      );

  Future<User?> _findByEmail(Session session, String email) =>
      User.db.findFirstRow(session, where: (user) => user.email.equals(email));

  /// El nombre del token o, si no trae, lo que va antes de la @ del email.
  static String _displayName(String? name, String email) {
    final trimmed = name?.trim() ?? '';
    final fallback = email.split('@').first;
    final displayName = trimmed.isEmpty ? fallback : trimmed;
    return displayName.length > 100
        ? displayName.substring(0, 100)
        : displayName;
  }
}
