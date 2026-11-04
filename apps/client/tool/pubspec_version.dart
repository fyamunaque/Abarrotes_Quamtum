import 'dart:io';

/// La versión de `version:` en pubspec.yaml: el nombre ("1.0.2") y el número
/// de compilación (3), que en Android son versionName y versionCode.
typedef AppVersion = ({int major, int minor, int patch, int build});

/// La línea `version:`, sin el salto de línea (LF o CRLF): así reemplazarla
/// no toca las demás.
final _pattern = RegExp(
  r'^version:[ \t]*(\d+)\.(\d+)\.(\d+)\+(\d+)[ \t]*(?=\r?$)',
  multiLine: true,
);

/// La versión de [pubspec] (pubspec.yaml, si no se dice otro).
AppVersion readVersion([File? pubspec]) {
  final text = (pubspec ?? File('pubspec.yaml')).readAsStringSync();
  final match = _pattern.firstMatch(text);
  if (match == null) {
    throw const FormatException(
      'pubspec.yaml no tiene una línea "version: 1.0.0+1".',
    );
  }
  int part(int i) => int.parse(match.group(i)!);
  return (major: part(1), minor: part(2), patch: part(3), build: part(4));
}

/// Escribe [version] en [pubspec], sin tocar el resto del archivo.
void writeVersion(AppVersion version, [File? pubspec]) {
  final file = pubspec ?? File('pubspec.yaml');
  final text = file.readAsStringSync();
  file.writeAsStringSync(
    text.replaceFirst(_pattern, 'version: ${fullVersion(version)}'),
  );
}

/// "1.0.2".
String versionName(AppVersion v) => '${v.major}.${v.minor}.${v.patch}';

/// "1.0.2+3", como en pubspec.yaml y en `--dart-define=APP_VERSION`.
String fullVersion(AppVersion v) => '${versionName(v)}+${v.build}';
