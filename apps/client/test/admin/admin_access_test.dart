import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/admin/inventory/inventory_providers.dart';
import 'package:neils/admin/orders/admin_order.dart';
import 'package:neils/admin/orders/admin_orders_providers.dart';
import 'package:neils/admin/products/admin_products_providers.dart';
import 'package:neils/admin/stats/stats.dart';
import 'package:neils/admin/stats/stats_providers.dart';
import 'package:neils/app.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/features/admin/products/product_form.dart';
import 'package:neils/features/admin/shared/status_badge.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/session/staff_permission.dart';

import '../fakes.dart';
import '../support.dart';
import 'panel_support.dart';

const _rice = Product(
  id: 'arroz',
  name: 'Arroz extra 5 kg',
  sku: 'ARR-5K',
  priceCents: 2490,
  stock: 40,
  category: groceries,
);

const _summary = SalesSummary(
  totalCents: 4550,
  orders: 2,
  averageTicketCents: 2275,
);

/// Lo que ve cada rol en el panel según sus permisos. Es solo la
/// experiencia: el servidor revisa el permiso en cada ruta.
void main() {
  useBundledFonts();

  late FakeAdminOrdersRepository orders;
  late FakeInventoryRepository inventory;
  late FakeAdminProductsRepository products;

  setUp(() {
    orders = FakeAdminOrdersRepository([
      adminOrder('o-1', OrderStatus.pendingConfirmation),
    ]);
    inventory = FakeInventoryRepository([_rice]);
    products = FakeAdminProductsRepository([_rice]);
  });

  List<Override> repositories() => [
    adminOrdersRepositoryProvider.overrideWithValue(orders),
    inventoryRepositoryProvider.overrideWithValue(inventory),
    adminProductsRepositoryProvider.overrideWithValue(products),
    catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
    statsRepositoryProvider.overrideWithValue(
      FakeStatsRepository(
        overviewData: StatsOverview(
          today: _summary,
          week: _summary,
          month: _summary,
          ordersByStatus: const {OrderStatus.pendingConfirmation: 2},
        ),
      ),
    ),
  ];

  Future<(ProviderContainer, GoRouter)> pump(
    WidgetTester tester,
    String at,
    Set<StaffPermission> permissions, {
    String? roleName,
    double width = 1280,
  }) => pumpPanel(
    tester,
    at: at,
    permissions: permissions,
    roleName: roleName,
    width: width,
    overrides: repositories(),
  );

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  List<String> railLabels(WidgetTester tester) => [
    for (final destination
        in tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .destinations)
      (destination.label as Text).data!,
  ];

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('el menú y las rutas', () {
    testWidgets('la Cajera ve Pedidos y Productos, y entra por Pedidos', (
      tester,
    ) async {
      final (_, router) = await pump(
        tester,
        '/admin',
        cashierPermissions,
        roleName: 'Cajera',
      );

      // Sin las estadísticas, /admin la lleva a su sección principal.
      expect(location(router), '/admin/pedidos');
      expect(railLabels(tester), ['Pedidos', 'Productos']);
      expect(find.text('Ana · Cajera'), findsOneWidget);
    });

    testWidgets('el Almacenero ve el inicio, Productos e Inventario', (
      tester,
    ) async {
      await pump(tester, '/admin', storekeeperPermissions);

      expect(railLabels(tester), ['Inicio', 'Productos', 'Inventario']);
      // Los enlaces del inicio, solo a lo que puede abrir.
      expect(find.text('Ver pedidos'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Inventario'), findsOneWidget);
    });

    testWidgets('una sección sin permiso: "No tienes acceso" y la suya', (
      tester,
    ) async {
      final (_, router) = await pump(
        tester,
        '/admin/inventario',
        cashierPermissions,
        roleName: 'Cajera',
      );

      expect(location(router), '/admin/sin-acceso');
      expect(find.text('No tienes acceso a esta sección'), findsOneWidget);
      expect(
        find.text('Tu rol (Cajera) no incluye Inventario.'),
        findsOneWidget,
      );
      // Ninguna sección del menú queda marcada.
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, isNull);

      await tapAndSettle(tester, find.text('Ir a Pedidos'));
      expect(location(router), '/admin/pedidos');
    });

    testWidgets('sin ninguna sección, "No tienes acceso" y la tienda', (
      tester,
    ) async {
      final (_, router) = await pump(tester, '/admin', const {
        StaffPermission.customersView,
      });

      expect(location(router), '/admin/sin-acceso');
      expect(
        find.text('Tu rol todavía no tiene ninguna sección del panel.'),
        findsOneWidget,
      );
      expect(find.byType(NavigationRail), findsNothing);
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, 'Ir a la tienda'),
      );
      expect(location(router), '/');
    });

    testWidgets(
      'en el teléfono: la barra con sus secciones, sin "Sin acceso"',
      (tester) async {
        final (_, router) = await pump(
          tester,
          '/admin/pedidos',
          cashierPermissions,
          width: 375,
        );
        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(bar.destinations, hasLength(2));

        router.go('/admin/promociones');
        await tester.pumpAndSettle();
        expect(find.text('No tienes acceso a esta sección'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('si le cambian el rol con la sección abierta, la deja', (
      tester,
    ) async {
      final (container, router) = await pump(
        tester,
        '/admin/inventario',
        storekeeperPermissions,
      );
      expect(find.text('Registrar movimiento'), findsOneWidget);

      // Volvió a pedir el perfil y ahora es Cajera.
      (container.read(sessionProvider.notifier) as TestSession).set(
        signedInWith(cashierPermissions, roleName: 'Cajera'),
      );
      await tester.pumpAndSettle();

      expect(location(router), '/admin/sin-acceso');
      expect(railLabels(tester), ['Pedidos', 'Productos']);
    });
  });

  group('los botones', () {
    testWidgets('registrar movimientos, solo con inventory.adjust', (
      tester,
    ) async {
      await pump(tester, '/admin/inventario', const {
        StaffPermission.inventoryView,
      });

      expect(find.text('Registrar movimiento'), findsNothing);
      expect(
        find.text(
          'Tu rol puede ver el inventario, pero no registrar movimientos.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin products.manage, los productos en modo lectura', (
      tester,
    ) async {
      await pump(tester, '/admin/productos', cashierPermissions);

      expect(find.text('Nuevo producto'), findsNothing);
      expect(
        find.text(
          'Tu rol puede ver los productos, pero no crearlos ni editarlos.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Arroz extra 5 kg'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductForm), findsNothing);
    });

    testWidgets('con products.manage, crear y editar', (tester) async {
      await pump(tester, '/admin/productos', const {
        StaffPermission.productsManage,
      });

      expect(find.text('Nuevo producto'), findsOneWidget);
      await tester.tap(find.text('Arroz extra 5 kg'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductForm), findsOneWidget);
    });

    testWidgets('el estado del pedido, solo con orders.updateStatus', (
      tester,
    ) async {
      await pump(tester, '/admin/pedidos', const {
        StaffPermission.ordersView,
        StaffPermission.customersView,
      });

      await tapAndSettle(tester, find.text('Ana Quispe'));
      expect(find.text('Confirmar'), findsNothing);
      expect(find.text('Cancelar pedido'), findsNothing);
      expect(
        find.text('Tu rol puede ver los pedidos, pero no cambiar su estado.'),
        findsOneWidget,
      );
    });

    testWidgets('sin customers.view, el pedido sin los datos del cliente', (
      tester,
    ) async {
      // Así lo manda el servidor sin ese permiso.
      orders = FakeAdminOrdersRepository([
        AdminOrder(
          order: adminOrder('o-1', OrderStatus.pendingConfirmation).order,
        ),
      ]);
      await pump(tester, '/admin/pedidos', const {
        StaffPermission.ordersView,
        StaffPermission.ordersUpdateStatus,
      });

      expect(find.text('Cliente'), findsNothing);
      await tapAndSettle(tester, find.byType(StatusBadge));
      expect(
        find.text('Tu rol no incluye ver los datos de los clientes.'),
        findsOneWidget,
      );
      expect(find.text('Confirmar'), findsOneWidget);
    });
  });

  group('con la sesión real', () {
    late FakeAuthRepository auth;
    late FakeUserRepository users;

    setUp(() {
      auth = FakeAuthRepository();
      users = FakeUserRepository(auth);
    });

    Future<GoRouter> pumpApp(WidgetTester tester, String at) async {
      useWideScreen(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            userRepositoryProvider.overrideWithValue(users),
            ...repositories(),
          ],
          child: const NeilsApp(),
        ),
      );
      final router = ProviderScope.containerOf(
        tester.element(find.byType(NeilsApp)),
      ).read(routerProvider)..go(at);
      await tester.pumpAndSettle();
      return router;
    }

    Future<void> signIn(WidgetTester tester, String email) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo'),
        email,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'secreta',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
      await tester.pumpAndSettle();
    }

    testWidgets('al ingresar, cada uno llega a su sección', (tester) async {
      final almacen = auth.addAccount('almacen@tienda.pe', 'secreta');
      users.permissions[almacen.uid] = storekeeperPermissions;
      final caja = auth.addAccount('caja@tienda.pe', 'secreta');
      users.permissions[caja.uid] = cashierPermissions;

      var router = await pumpApp(tester, '/login');
      await signIn(tester, 'almacen@tienda.pe');
      expect(location(router), '/admin/inventario');

      router = await pumpApp(tester, '/login');
      await signIn(tester, 'caja@tienda.pe');
      expect(location(router), '/admin/pedidos');
    });

    testWidgets('al volver a la app, un rol nuevo rige sin cerrar sesión', (
      tester,
    ) async {
      final luis = auth.addAccount(
        'luis@tienda.pe',
        'secreta',
        name: 'Luis',
        signedIn: true,
      );
      users.permissions[luis.uid] = storekeeperPermissions;
      users.roleNames[luis.uid] = 'Almacenero';
      final router = await pumpApp(tester, '/admin/inventario');
      expect(find.text('Registrar movimiento'), findsOneWidget);

      // Un admin le cambió el rol mientras tanto.
      users.permissions[luis.uid] = cashierPermissions;
      users.roleNames[luis.uid] = 'Cajera';
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();

      expect(location(router), '/admin/sin-acceso');
      expect(
        find.text('Tu rol (Cajera) no incluye Inventario.'),
        findsOneWidget,
      );
      expect(railLabels(tester), ['Pedidos', 'Productos']);
      expect(auth.current, luis.uid);
    });
  });
}
