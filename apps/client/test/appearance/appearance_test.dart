import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/app.dart';
import 'package:neils/appearance/appearance.dart';
import 'package:neils/appearance/appearance_providers.dart';
import 'package:neils/appearance/appearance_repository.dart';
import 'package:neils/cart/cart_storage.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/orders/orders_providers.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes.dart';
import '../support.dart';

void main() {
  useBundledFonts();

  group('el repositorio en el dispositivo', () {
    test('guarda y lee los tres valores', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = PrefsAppearanceRepository(prefs);

      expect(repository.read(), ThemePreference.system);
      for (final value in ThemePreference.values) {
        await repository.write(value);
        expect(PrefsAppearanceRepository(prefs).read(), value);
      }
    });

    test('un valor desconocido cuenta como sistema', () async {
      SharedPreferences.setMockInitialValues({
        PrefsAppearanceRepository.key: 'violeta',
      });
      final prefs = await SharedPreferences.getInstance();

      expect(PrefsAppearanceRepository(prefs).read(), ThemePreference.system);
    });
  });

  test('cada preferencia da su modo', () {
    expect(ThemePreference.system.themeMode, ThemeMode.system);
    expect(ThemePreference.light.themeMode, ThemeMode.light);
    expect(ThemePreference.dark.themeMode, ThemeMode.dark);
  });

  test('set guarda la preferencia', () async {
    final repository = MemoryAppearanceRepository();
    final container = ProviderContainer(
      overrides: [appearanceRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect(container.read(appearanceProvider), ThemePreference.system);
    await container.read(appearanceProvider.notifier).set(ThemePreference.dark);

    expect(container.read(appearanceProvider), ThemePreference.dark);
    expect(repository.read(), ThemePreference.dark);
  });

  test('la preferencia guardada sobrevive a un provider nuevo', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = ProviderContainer(
      overrides: [
        appearanceRepositoryProvider.overrideWithValue(
          PrefsAppearanceRepository(prefs),
        ),
      ],
    );
    await first.read(appearanceProvider.notifier).set(ThemePreference.light);
    first.dispose();

    final second = ProviderContainer(
      overrides: [
        appearanceRepositoryProvider.overrideWithValue(
          PrefsAppearanceRepository(prefs),
        ),
      ],
    );
    addTearDown(second.dispose);

    expect(second.read(appearanceProvider), ThemePreference.light);
  });

  group('la app', () {
    late ProviderContainer container;

    Future<void> pumpApp(WidgetTester tester, ThemePreference stored) async {
      final catalog = FakeCatalogRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appearanceRepositoryProvider.overrideWithValue(
              MemoryAppearanceRepository(stored),
            ),
            sessionProvider.overrideWith(() => TestSession(const SignedOut())),
            cartStorageProvider.overrideWithValue(MemoryCartStorage()),
            catalogRepositoryProvider.overrideWithValue(catalog),
            orderRepositoryProvider.overrideWithValue(
              FakeOrderRepository(catalog),
            ),
          ],
          child: const NeilsApp(),
        ),
      );
      container = ProviderScope.containerOf(
        tester.element(find.byType(NeilsApp)),
      );
    }

    Brightness brightness(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

    testWidgets('arranca en oscuro si estaba guardado', (tester) async {
      await pumpApp(tester, ThemePreference.dark);
      // El primer cuadro ya es oscuro: sin pasar por el claro.
      await tester.pump();

      expect(brightness(tester), Brightness.dark);
    });

    testWidgets('en sistema sigue al brillo del dispositivo', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester, ThemePreference.system);
      await tester.pump();

      expect(brightness(tester), Brightness.dark);
    });

    testWidgets('cambiar la preferencia cambia el modo de la app', (
      tester,
    ) async {
      await pumpApp(tester, ThemePreference.light);
      await tester.pump();
      expect(brightness(tester), Brightness.light);

      await container
          .read(appearanceProvider.notifier)
          .set(ThemePreference.dark);
      await tester.pumpAndSettle();

      expect(brightness(tester), Brightness.dark);
    });
  });
}
