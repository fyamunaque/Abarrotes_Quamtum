import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neils/config/app_version.dart';

import '../../tool/pubspec_version.dart';

/// El número de versión: el que muestra la app y el que sube
/// tool/build_apk.dart en pubspec.yaml.
void main() {
  test('la etiqueta: "Versión 1.0.2 (3)"; sin versión, nada', () {
    expect(versionLabel('1.0.2+3'), 'Versión 1.0.2 (3)');
    expect(versionLabel('1.0.2'), 'Versión 1.0.2');
    expect(versionLabel(''), isNull);
  });

  group('pubspec.yaml', () {
    late Directory dir;
    late File pubspec;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('version_test');
      pubspec = File('${dir.path}/pubspec.yaml')
        ..writeAsStringSync(
          'name: neils\n'
          'description: "La tienda."\n'
          'version: 1.0.9+12\n'
          '\n'
          'environment:\n'
          '  sdk: ^3.13.5\n',
        );
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('lee la versión', () {
      final version = readVersion(pubspec);
      expect(version, (major: 1, minor: 0, patch: 9, build: 12));
      expect(versionName(version), '1.0.9');
      expect(fullVersion(version), '1.0.9+12');
    });

    test('escribe la versión nueva sin tocar el resto', () {
      writeVersion((major: 1, minor: 1, patch: 0, build: 13), pubspec);

      expect(readVersion(pubspec), (major: 1, minor: 1, patch: 0, build: 13));
      expect(
        pubspec.readAsStringSync(),
        'name: neils\n'
        'description: "La tienda."\n'
        'version: 1.1.0+13\n'
        '\n'
        'environment:\n'
        '  sdk: ^3.13.5\n',
      );
    });

    test('con saltos de línea de Windows (CRLF), igual', () {
      pubspec.writeAsStringSync('name: neils\r\nversion: 1.0.9+12\r\n\r\n');
      writeVersion((major: 1, minor: 0, patch: 10, build: 13), pubspec);

      expect(
        pubspec.readAsStringSync(),
        'name: neils\r\nversion: 1.0.10+13\r\n\r\n',
      );
    });

    test('sin una versión válida, lo dice', () {
      pubspec.writeAsStringSync('name: neils\nversion: 1.0\n');
      expect(() => readVersion(pubspec), throwsFormatException);
    });
  });
}
