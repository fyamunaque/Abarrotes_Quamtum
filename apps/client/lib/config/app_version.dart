/// La versión de la app, la de `version:` en pubspec.yaml ("1.0.2+3"). La
/// pasan al compilar tool/build_apk.dart y tool/serve_web.dart
/// (`--dart-define=APP_VERSION`); con `flutter run` queda vacía.
const appVersion = String.fromEnvironment('APP_VERSION');

/// La de [appVersion] (ver [versionLabel]).
String? get appVersionLabel => versionLabel(appVersion);

/// "Versión 1.0.2 (3)" para "1.0.2+3": el nombre y, entre paréntesis, el
/// número de compilación. Null sin versión (en desarrollo).
String? versionLabel(String version) {
  if (version.isEmpty) return null;
  final [name, ...build] = version.split('+');
  return build.isEmpty ? 'Versión $name' : 'Versión $name (${build.first})';
}
