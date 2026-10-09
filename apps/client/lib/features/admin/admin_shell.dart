import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import '../../theme/neils_theme.dart';
import '../shared/account.dart';
import '../shared/brand.dart';
import '../shared/page_title.dart';

/// Las secciones del panel, en el orden de la navegación.
enum AdminSection {
  home(
    Routes.admin,
    'Inicio',
    Icons.space_dashboard_outlined,
    Icons.space_dashboard,
  ),
  orders(
    Routes.adminOrders,
    'Pedidos',
    Icons.receipt_long_outlined,
    Icons.receipt_long,
  ),
  products(
    Routes.adminProducts,
    'Productos',
    Icons.inventory_2_outlined,
    Icons.inventory_2,
  ),
  inventory(
    Routes.adminInventory,
    'Inventario',
    Icons.swap_vert,
    Icons.swap_vert,
  ),
  promotions(
    Routes.adminPromotions,
    'Promociones',
    Icons.sell_outlined,
    Icons.sell,
    shortLabel: 'Promos',
  ),
  vip(
    Routes.adminVip,
    'Clientes VIP',
    Icons.workspace_premium_outlined,
    Icons.workspace_premium,
    shortLabel: 'VIP',
  );

  const AdminSection(
    this.path,
    this.label,
    this.icon,
    this.selectedIcon, {
    this._shortLabel,
  });

  final String path;
  final String label;
  final String? _shortLabel;
  final IconData icon;
  final IconData selectedIcon;

  /// Para la barra de abajo del teléfono, donde cada destino tiene poco
  /// ancho.
  String get shortLabel => _shortLabel ?? label;

  /// La sección de [path] (una subruta cuenta como su sección).
  static AdminSection of(String path) => values.lastWhere(
    (section) => path == section.path || path.startsWith('${section.path}/'),
    orElse: () => home,
  );
}

/// Layout común de /admin, con el tema calmado del panel. Solo se llega aquí
/// con una sesión de admin o staff, o mientras la sesión carga (ver
/// route_guard.dart): en ese caso muestra un indicador hasta que el guard
/// decide.
///
/// Desde [wideFrom] la navegación es un riel a la izquierda; por debajo, una
/// barra abajo.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  /// La ruta actual, para marcar la sección.
  final String location;
  final Widget child;

  static const wideFrom = 840.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final wide = MediaQuery.sizeOf(context).width >= wideFrom;
    final selected = AdminSection.of(location);
    void go(int index) => context.go(AdminSection.values[index].path);

    final content = switch (session) {
      SignedIn() => child,
      _ => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Cargando'),
      ),
    };

    return PageTitle(
      title: '${selected.label} · Panel',
      child: Theme(
        data: neilsAdminTheme(Theme.of(context)),
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 64,
            title: const Row(
              children: [
                NeilsLogo(),
                // El espacio se encoge con el título: en un teléfono angosto
                // solo entra el logo.
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'Panel de la tienda',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Ir a la tienda'),
              ),
              if (session case SignedIn(:final user))
                AccountActions(user, inPanel: true),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: wide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: selected.index,
                        onDestinationSelected: go,
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (final section in AdminSection.values)
                            NavigationRailDestination(
                              icon: Icon(section.icon),
                              selectedIcon: Icon(section.selectedIcon),
                              label: Text(section.label),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: content),
                    ],
                  )
                : content,
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selected.index,
                  onDestinationSelected: go,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: [
                    for (final section in AdminSection.values)
                      NavigationDestination(
                        icon: Icon(section.icon),
                        selectedIcon: Icon(section.selectedIcon),
                        label: section.shortLabel,
                        tooltip: section.label,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
