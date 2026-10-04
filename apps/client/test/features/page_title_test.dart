import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/orders/admin_orders_providers.dart';
import 'package:neils/app.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

import '../admin/panel_support.dart';
import '../fakes.dart';
import '../support.dart';

void main() {
  useBundledFonts();

  /// El título que queda en la pestaña: el del [Title] de más adentro.
  String tabTitle(WidgetTester tester) =>
      tester.widgetList<Title>(find.byType(Title)).last.title;

  testWidgets('cada pantalla pública pone su título en la pestaña', (
    tester,
  ) async {
    useWideScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: const NeilsApp(),
      ),
    );
    final router = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    ).read(routerProvider);

    for (final (path, title) in [
      ('/', "Neil's Food Services"),
      ('/catalogo', "Catálogo · Neil's Food Services"),
      ('/catalogo?q=arroz', "“arroz” · Catálogo · Neil's Food Services"),
      ('/producto/arroz', "Arroz extra 5 kg · Neil's Food Services"),
      ('/carrito', "Carrito · Neil's Food Services"),
      ('/login', "Ingresar · Neil's Food Services"),
      ('/no-existe', "Página no encontrada · Neil's Food Services"),
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(tabTitle(tester), title, reason: path);
    }
  });

  testWidgets('en el panel, la sección', (tester) async {
    await pumpPanel(
      tester,
      at: '/admin/pedidos',
      overrides: [
        adminOrdersRepositoryProvider.overrideWithValue(
          FakeAdminOrdersRepository([]),
        ),
      ],
    );

    expect(tabTitle(tester), "Pedidos · Panel · Neil's Food Services");
  });
}
