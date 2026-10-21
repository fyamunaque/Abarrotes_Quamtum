import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../auth/auth_repository.dart';
import 'session.dart';

/// La sesión actual. El router la escucha para proteger /admin.
final sessionProvider = NotifierProvider<SessionNotifier, Session>(
  SessionNotifier.new,
);

/// El ID token de la cuenta abierta, o null sin sesión: para las rutas
/// públicas que responden distinto a cada cliente (los precios del catálogo,
/// las ofertas). Si no se puede obtener, null: se atiende como visitante.
final optionalIdTokenProvider = Provider<Future<String?> Function()>(
  (ref) => () async {
    if (ref.read(sessionProvider) is! SignedIn) return null;
    try {
      return await ref.read(authRepositoryProvider).idToken();
    } on AuthFailure {
      return null;
    }
  },
);

/// Si la cuenta abierta puede usar las promociones VIP. Lo que depende de eso
/// (los precios del catálogo, las ofertas) mira solo esto: cambia cuando un
/// admin agrega o quita el correo, sin cerrar la sesión.
final isVipProvider = Provider<bool>(
  (ref) => switch (ref.watch(sessionProvider)) {
    SignedIn(:final user) => user.isVip,
    _ => false,
  },
);

/// Hay sesión cuando hay una cuenta de Firebase y el servidor devolvió su
/// perfil (`GET /users/me`), que es de donde salen el rol y si es VIP.
/// [refreshProfile] lo vuelve a pedir sin cerrar la sesión.
///
/// Escucha a Firebase para la cuenta que quedó abierta al arrancar y para los
/// cambios que no pasan por aquí (p. ej. salir en otra pestaña). Ingresar y
/// registrarse piden el perfil ellos mismos: mientras corren, los avisos de
/// Firebase se ignoran. Si no, el registro pediría el perfil antes de guardar
/// el nombre, y el servidor crearía la cuenta sin él.
class SessionNotifier extends Notifier<Session> {
  /// El uid de la cuenta ya resuelta, o que se está resolviendo.
  String? _uid;
  bool _entering = false;
  Future<void>? _refreshing;

  @override
  Session build() {
    final accounts = ref
        .watch(authRepositoryProvider)
        .accountChanges()
        .listen(_onAccount);
    ref.onDispose(accounts.cancel);
    return const SessionLoading();
  }

  AuthRepository get _auth => ref.read(authRepositoryProvider);

  /// Ingresa con email y contraseña. Devuelve la cuenta, para que la pantalla
  /// decida a dónde ir según el rol. Los errores salen como [AuthFailure].
  Future<SessionUser> signIn({
    required String email,
    required String password,
  }) => _enter(() => _auth.signIn(email: email, password: password));

  /// Crea una cuenta de cliente y queda ingresada.
  Future<SessionUser> register({
    required String name,
    required String email,
    required String password,
  }) => _enter(
    () => _auth.register(name: name, email: email, password: password),
  );

  /// Vuelve a pedir el perfil y si el correo ya está confirmado (p. ej. un
  /// admin lo hizo VIP, o la persona confirmó su correo), sin cerrar la
  /// sesión. Si falla, la sesión queda como estaba. Si ya hay uno en curso,
  /// devuelve ese.
  Future<void> refreshProfile() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    if (_entering || state is! SignedIn) return;
    final uid = _uid;
    try {
      final user = await _fetchProfile(reload: true);
      if (!ref.mounted || _uid != uid) return;
      if (state case SignedIn(user: final current) when current != user) {
        state = SignedIn(user);
      }
    } on AuthFailure {
      // Sin red o el servidor caído: se vuelve a intentar la próxima vez.
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _uid = null;
    state = const SignedOut();
  }

  Future<SessionUser> _enter(Future<String> Function() enter) async {
    _entering = true;
    try {
      final uid = await enter();
      try {
        final user = await _profile();
        _uid = uid;
        state = SignedIn(user);
        return user;
      } catch (_) {
        // _profile ya cerró la cuenta de Firebase; si había otra sesión
        // abierta, tampoco sigue.
        _uid = null;
        state = const SignedOut();
        rethrow;
      }
    } finally {
      _entering = false;
    }
  }

  Future<void> _onAccount(String? uid) async {
    if (_entering) return;
    if (uid == null) {
      _uid = null;
      state = const SignedOut();
      return;
    }
    if (uid == _uid) return;

    _uid = uid;
    try {
      final user = await _profile();
      if (ref.mounted && _uid == uid) state = SignedIn(user);
    } catch (error) {
      if (ref.mounted && _uid == uid) {
        _uid = null;
        state = const SignedOut();
      }
      // Un AuthFailure (servidor caído, sin red) ya se resolvió sin sesión;
      // cualquier otra cosa es un error de programación.
      if (error is! AuthFailure) rethrow;
    }
  }

  /// El perfil de la cuenta de Firebase actual. Sin perfil no hay rol, así que
  /// si falla se cierra también la cuenta de Firebase.
  Future<SessionUser> _profile() async {
    try {
      return await _fetchProfile();
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  /// El perfil del servidor y si el correo está confirmado. Primero el
  /// correo: con [reload], si se acaba de confirmar, renueva el token, y así
  /// el servidor ya lo ve al responder el perfil.
  Future<SessionUser> _fetchProfile({bool reload = false}) async {
    final verified = await _auth.emailVerified(reload: reload);
    final user = await ref
        .read(userRepositoryProvider)
        .me(await _auth.idToken());
    return user.copyWith(emailVerified: verified);
  }
}
