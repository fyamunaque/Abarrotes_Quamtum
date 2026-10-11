import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/route_guard.dart';
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
  ),

  /// Las personas del equipo y, en otra pestaña, los roles: un solo destino
  /// para no sumar dos a la barra del teléfono.
  team(
    Routes.adminTeam,
    'Equipo',
    Icons.groups_outlined,
    Icons.groups,
    alsoAt: [Routes.adminRoles],
  );

  const AdminSection(
    this.path,
    this.label,
    this.icon,
    this.selectedIcon, {
    this._shortLabel,
    this.alsoAt = const [],
  });

  final String path;
  final String label;
  final String? _shortLabel;
  final IconData icon;
  final IconData selectedIcon;

  /// Otras rutas que se marcan como esta sección.
  final List<String> alsoAt;

  /// Para la barra de abajo del teléfono, donde cada destino tiene poco
  /// ancho.
  String get shortLabel => _shortLabel ?? label;

  /// El inicio es solo /admin; las demás cuentan también sus subrutas.
  bool _matches(String path) => this == home
      ? path == this.path
      : [
          this.path,
          ...alsoAt,
        ].any((base) => path == base || path.startsWith('$base/'));

  /// La sección de [path], o null si no es de ninguna ("Sin acceso").
  static AdminSection? of(String path) =>
      values.where((section) => section._matches(path)).firstOrNull;

  /// Las secciones que ve [session]: las de sus permisos
  /// (`Routes.permissionsFor`). Mientras la sesión carga, ninguna.
  static List<AdminSection> visibleTo(Session session) => switch (session) {
    SignedIn(:final user) => [
      for (final section in values)
        if (canOpenPanel(user, section.path)) section,
    ],
    _ => const [],
  };
}

/// Layout común de /admin, con el tema calmado del panel. Solo se llega aquí
/// con una sesión del personal, o mientras la sesión carga (ver
/// route_guard.dart): en ese caso muestra un indicador hasta que el guard
/// decide.
///
/// La navegación muestra solo las secciones de los permisos de la sesión.
/// Desde [wideFrom] es un riel a la izquierda; por debajo, una barra abajo,
/// que necesita al menos dos secciones y una elegida: si no (una sola
/// sección, o "Sin acceso"), no hay barra.
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
    final sections = AdminSection.visibleTo(session);
    final selected = AdminSection.of(location);
    final selectedIndex = selected == null ? -1 : sections.indexOf(selected);
    void go(int index) => context.go(sections[index].path);

    final content = switch (session) {
      SignedIn() => child,
      _ => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Cargando'),
      ),
    };

    return PageTitle(
      title: '${selected?.label ?? 'Sin acceso'} · Panel',
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
            child: wide && sections.isNotEmpty
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: selectedIndex < 0 ? null : selectedIndex,
                        onDestinationSelected: go,
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (final section in sections)
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
          bottomNavigationBar: wide || sections.length < 2 || selectedIndex < 0
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: go,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: [
                    for (final section in sections)
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
