import 'package:flutter/material.dart';

/// Cómo se ve la app: como el teléfono o el navegador ([system]), siempre
/// clara o siempre oscura. Se elige en el menú y queda en el dispositivo.
enum ThemePreference {
  system,
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
}
