import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';

/// La sesión actual. El router la escucha para proteger /admin.
final sessionProvider = NotifierProvider<SessionNotifier, Session>(
  SessionNotifier.new,
);

/// Por ahora la app arranca siempre sin sesión: el inicio de sesión con
/// Firebase Auth (y el rol desde `GET /users/me`) se conecta aquí.
class SessionNotifier extends Notifier<Session> {
  @override
  Session build() => const SignedOut();
}
