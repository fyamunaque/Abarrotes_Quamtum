import 'package:serverpod/serverpod.dart';

import '../auth/firebase_identity.dart';
import '../common/api_route.dart';
import '../common/customer_requirements.dart';
import '../common/http_json.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart';

/// Cuentas de usuario: el vínculo entre un uid de Firebase y la tienda, y los
/// dispositivos donde reciben avisos push. Los permisos del personal no viven
/// aquí (ver staff/).
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

  /// Los datos de [user] que pide un pedido: el celular ([phone], ya
  /// normalizado), el DNI ([dni]; con [clearDni], lo borra) y, con
  /// [acceptTerms], la aceptación de los términos vigentes, ahora. Lo que no
  /// viene queda como estaba. Un DNI que ya tiene otra cuenta: 409.
  Future<User> updateProfile(
    Session session,
    User user, {
    String? phone,
    String? dni,
    bool clearDni = false,
    bool acceptTerms = false,
  }) async {
    try {
      return await User.db.updateRow(
        session,
        user.copyWith(
          phone: phone ?? user.phone,
          dni: clearDni ? null : dni ?? user.dni,
          termsVersion: acceptTerms ? currentTermsVersion : user.termsVersion,
          termsAcceptedAt: acceptTerms
              ? DateTime.now().toUtc()
              : user.termsAcceptedAt,
        ),
      );
    } on DatabaseUniqueViolationException {
      throw const ApiException.conflict(
        'Ese DNI ya está registrado en otra cuenta.',
      );
    }
  }

  /// Las cuentas de la tienda, por nombre. [search] busca en el nombre y el
  /// correo.
  Future<(List<User>, int)> listCustomers(
    Session session,
    PageQuery page, {
    String? search,
  }) async {
    Expression where(UserTable user) {
      if (search == null) return Constant.bool(true);
      final pattern = '%${escapeLike(search)}%';
      return user.name.ilike(pattern) | user.email.ilike(pattern);
    }

    final customers = await User.db.find(
      session,
      where: where,
      orderByList: (user) => [user.name.asc(), user.id.asc()],
      limit: page.limit,
      offset: page.offset,
    );
    final total = await User.db.count(session, where: where);
    return (customers, total);
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
