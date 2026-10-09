import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/api_client.dart';
import '../config/api_config.dart';
import '../firebase_options.dart';
import '../users/http_user_repository.dart';
import '../users/user_repository.dart';
import 'auth_repository.dart';
import 'firebase_auth_repository.dart';

/// Las cuentas de Firebase. Los tests lo reemplazan por uno en memoria.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => DefaultFirebaseOptions.currentPlatform == null
      ? const UnavailableAuthRepository()
      : FirebaseAuthRepository(FirebaseAuth.instance),
);

/// El perfil y el rol desde el servidor.
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => HttpUserRepository(ref.watch(apiClientProvider)),
);

/// Las rutas que piden cuenta (las del panel), con el ID token de la cuenta
/// abierta en cada llamada.
final authedApiProvider = Provider<AuthedApi>(
  (ref) => AuthedApi(
    ref.watch(apiClientProvider),
    () => ref.read(authRepositoryProvider).idToken(),
  ),
);
