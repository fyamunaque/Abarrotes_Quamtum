import 'package:serverpod/serverpod.dart';

import '../auth/firebase_identity.dart';
import '../common/http_json.dart';
import '../generated/protocol.dart';
import 'create_user_request.dart';

/// Cuentas de usuario: el vínculo entre un uid de Firebase y su rol, y los
/// dispositivos donde reciben avisos push.
class UsersService {
  const UsersService();

  /// El usuario de [identity]. La primera vez lo crea como cliente con el
  /// email y el nombre del token. Guarda si el correo está verificado
  /// (`email_verified` del token), si cambió: el aviso push lo necesita.
  Future<User> findOrCreate(Session session, FirebaseIdentity identity) async {
    final existing = await _findByFirebaseUid(session, identity.uid);
    if (existing != null) {
      return _syncEmailVerified(session, existing, identity.emailVerified);
    }

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
          emailVerified: identity.emailVerified,
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

  /// Registra el token de FCM de un dispositivo de [user]. Si ya estaba, lo
  /// renueva; si era de otra cuenta (otra persona ingresó en ese
  /// dispositivo), pasa a esta.
  Future<void> registerDevice(
    Session session,
    User user, {
    required String token,
    String? platform,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await _findDevice(session, token);
    if (existing == null) {
      try {
        await DeviceToken.db.insertRow(
          session,
          DeviceToken(
            token: token,
            platform: platform,
            userId: user.id!,
            createdAt: now,
            updatedAt: now,
          ),
        );
        return;
      } on DatabaseUniqueViolationException {
        // El mismo dispositivo se registró dos veces a la vez: se actualiza
        // el que quedó.
      }
    }
    final device = existing ?? (await _findDevice(session, token))!;
    await DeviceToken.db.updateRow(
      session,
      device.copyWith(
        userId: user.id,
        platform: platform ?? device.platform,
        updatedAt: now,
      ),
    );
  }

  /// Quita el token de [user] (p. ej. al cerrar sesión). Si es de otra
  /// cuenta o no existe, no hace nada.
  Future<void> removeDevice(Session session, User user, String token) async {
    await DeviceToken.db.deleteWhere(
      session,
      where: (device) =>
          device.token.equals(token) & device.userId.equals(user.id),
    );
  }

  Future<DeviceToken?> _findDevice(Session session, String token) =>
      DeviceToken.db.findFirstRow(
        session,
        where: (device) => device.token.equals(token),
      );

  Future<User> _syncEmailVerified(
    Session session,
    User user,
    bool emailVerified,
  ) async {
    if (user.emailVerified == emailVerified) return user;
    return User.db.updateRow(
      session,
      user.copyWith(emailVerified: emailVerified),
      columns: (user) => [user.emailVerified],
    );
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
