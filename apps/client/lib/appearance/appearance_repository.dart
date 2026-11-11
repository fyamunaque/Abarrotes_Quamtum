import 'package:shared_preferences/shared_preferences.dart';

import 'appearance.dart';

/// Dónde queda la apariencia elegida. La lectura es síncrona: la app la sabe
/// antes del primer cuadro y no pasa por el modo equivocado.
abstract interface class AppearanceRepository {
  /// La guardada, o [ThemePreference.system] si no hay o no se entiende.
  ThemePreference read();

  Future<void> write(ThemePreference value);
}

/// En memoria: la de los tests.
class MemoryAppearanceRepository implements AppearanceRepository {
  MemoryAppearanceRepository([this._value = ThemePreference.system]);

  ThemePreference _value;

  @override
  ThemePreference read() => _value;

  @override
  Future<void> write(ThemePreference value) async => _value = value;
}

/// En el dispositivo: SharedPreferences en Android, localStorage en la web.
class PrefsAppearanceRepository implements AppearanceRepository {
  PrefsAppearanceRepository(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'neils.appearance';

  @override
  ThemePreference read() =>
      ThemePreference.values.asNameMap()[_prefs.getString(key)] ??
      ThemePreference.system;

  @override
  Future<void> write(ThemePreference value) =>
      _prefs.setString(key, value.name);
}
