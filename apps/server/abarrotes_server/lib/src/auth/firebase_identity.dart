/// Quién hace la petición, según un Firebase ID token ya verificado.
class FirebaseIdentity {
  const FirebaseIdentity({
    required this.uid,
    this.email,
    this.emailVerified = false,
    this.name,
  });

  /// uid de Firebase Auth (claim `sub`).
  final String uid;
  final String? email;
  final bool emailVerified;
  final String? name;
}

/// El token no es un Firebase ID token válido para este proyecto.
class InvalidFirebaseTokenException implements Exception {
  const InvalidFirebaseTokenException(this.reason);

  /// Motivo, solo para los logs: nunca incluye el token.
  final String reason;

  @override
  String toString() => 'InvalidFirebaseTokenException: $reason';
}

/// No se pudieron obtener las llaves públicas de Google para verificar tokens.
class PublicKeysUnavailableException implements Exception {
  const PublicKeysUnavailableException(this.reason);

  final String reason;

  @override
  String toString() => 'PublicKeysUnavailableException: $reason';
}
