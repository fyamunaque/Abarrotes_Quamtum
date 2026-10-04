// Config de Firebase por plataforma, con el formato de `flutterfire configure`.
// No son secretos: identifican el proyecto. Lo que protege los datos es el
// servidor, que verifica el ID token en cada petición.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract final class DefaultFirebaseOptions {
  /// La config de la plataforma actual, o null si esa plataforma todavía no
  /// está registrada en Firebase: la app arranca, pero no se puede ingresar.
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => null,
    };
  }

  /// Pendiente: la Web app del proyecto (consola de Firebase → Configuración
  /// del proyecto → Tus apps → Web).
  static const FirebaseOptions? web = null;

  /// De apps/android/app/google-services.json: el mismo proyecto y paquete
  /// que la app Kotlin.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDezqjhkzbRah2b_M7M6qUAqSVTMMhdYYA',
    appId: '1:850027810618:android:fec30065966a893544ca03',
    messagingSenderId: '850027810618',
    projectId: 'prototype-440b7',
    storageBucket: 'prototype-440b7.firebasestorage.app',
  );
}
