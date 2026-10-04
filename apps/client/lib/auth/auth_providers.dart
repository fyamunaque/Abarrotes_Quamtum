import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return HttpUserRepository(client, baseUrl: apiBaseUrl);
});
