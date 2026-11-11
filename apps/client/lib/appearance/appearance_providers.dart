import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'appearance.dart';
import 'appearance_repository.dart';

/// El de la app lo reemplaza `main.dart` por [PrefsAppearanceRepository].
/// Este, en memoria, es el de los tests.
final appearanceRepositoryProvider = Provider<AppearanceRepository>(
  (ref) => MemoryAppearanceRepository(),
);

/// La apariencia elegida: arranca con la guardada y [AppearanceNotifier.set]
/// la cambia y la guarda.
final appearanceProvider =
    NotifierProvider<AppearanceNotifier, ThemePreference>(
      AppearanceNotifier.new,
    );

class AppearanceNotifier extends Notifier<ThemePreference> {
  @override
  ThemePreference build() => ref.watch(appearanceRepositoryProvider).read();

  Future<void> set(ThemePreference value) async {
    state = value;
    await ref.read(appearanceRepositoryProvider).write(value);
  }
}
