import 'package:abarrotes_server/src/auth/guards.dart';
import 'package:abarrotes_server/src/categories/categories_routes.dart';
import 'package:abarrotes_server/src/categories/categories_service.dart';
import 'package:abarrotes_server/src/common/api_route.dart';
import 'package:abarrotes_server/src/inventory/inventory_routes.dart';
import 'package:abarrotes_server/src/inventory/inventory_service.dart';
import 'package:abarrotes_server/src/inventory/stock_alerts.dart';
import 'package:abarrotes_server/src/orders/orders_routes.dart';
import 'package:abarrotes_server/src/orders/orders_service.dart';
import 'package:abarrotes_server/src/products/products_routes.dart';
import 'package:abarrotes_server/src/products/products_service.dart';
import 'package:abarrotes_server/src/promotions/promotions_routes.dart';
import 'package:abarrotes_server/src/staff/audit_log_repository.dart';
import 'package:abarrotes_server/src/staff/permissions.dart';
import 'package:abarrotes_server/src/staff/roles_service.dart';
import 'package:abarrotes_server/src/staff/staff_routes.dart';
import 'package:abarrotes_server/src/staff/staff_service.dart';
import 'package:abarrotes_server/src/stats/providers/expiring_products_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/fulfillment_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/low_stock_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/order_status_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/overview_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/sales_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/top_products_report_provider.dart';
import 'package:abarrotes_server/src/stats/stats_routes.dart';
import 'package:abarrotes_server/src/store/store_routes.dart';
import 'package:abarrotes_server/src/store/store_settings_service.dart';
import 'package:abarrotes_server/src/users/users_routes.dart';
import 'package:abarrotes_server/src/users/users_service.dart';
import 'package:abarrotes_server/src/vip/vip_routes.dart';
import 'package:abarrotes_server/src/vip/vip_service.dart';
import 'package:serverpod/serverpod.dart' show Route;
import 'package:test/test.dart';

import '../../support/promotions_setup.dart';
import '../../support/staff_setup.dart';
import '../../support/test_tokens.dart';

/// Cada ruta con su protección, armadas como en `server.dart`: ninguna queda
/// protegida solo por "ser del personal". Si se agrega una ruta, hay que
/// decidir aquí su permiso.
void main() {
  /// Lo que pide cada ruta: un permiso ("products.manage"), cualquier
  /// cuenta, el token (la cuenta propia) o nada (pública).
  String protectionOf(String path, Route route) => switch (route) {
    RequirePermission(:final permission) => permissionKey(permission),
    RequireAccount() => 'cuenta',
    // addUsersRoutes pone el middleware de Firebase en /users.
    ApiRoute() when path.startsWith('/users/') => 'token',
    ApiRoute() => 'pública',
    _ => 'otra: ${route.runtimeType}',
  };

  test('el permiso de cada ruta', () {
    final guards = testGuards(generateRsaKeyPair());
    final stockAlerts = StockAlerts();
    const sales = SalesReportProvider();
    final routes = <RouteEntry>[
      ...usersRoutes(const UsersService(), guards, shoppers: testShoppers),
      ...categoriesRoutes(const CategoriesService(), guards),
      ...storeRoutes(const StoreSettingsService(), guards),
      ...productsRoutes(
        ProductsService(pricing: testPromotions()),
        guards,
        shoppers: testShoppers,
      ),
      ...promotionsRoutes(testPromotions(), guards, shoppers: testShoppers),
      ...inventoryRoutes(const InventoryService(), stockAlerts, guards),
      ...ordersRoutes(
        OrdersService(pricing: testPromotions()),
        guards,
        shoppers: testShoppers,
      ),
      ...vipRoutes(const VipService(), guards),
      ...staffRoutes(
        roles: const RolesService(),
        staff: const StaffService(),
        audit: const DbAuditLogRepository(),
        guards: guards,
      ),
      ...statsRoutes(
        overview: OverviewReportProvider(
          sales: sales,
          orderStatus: const OrderStatusReportProvider(),
          fulfillment: const FulfillmentReportProvider(),
        ),
        sales: sales,
        topProducts: const TopProductsReportProvider(),
        lowStock: LowStockReportProvider(stockAlerts),
        expiring: ExpiringProductsReportProvider(stockAlerts),
        guards: guards,
      ),
    ];

    final protections = {
      for (final (path, route) in routes)
        for (final method in route.methods)
          '${method.name.toUpperCase()} $path': protectionOf(path, route),
    };

    expect(protections, {
      'GET /users/me': 'token',
      'PUT /users/me/devices': 'token',
      'DELETE /users/me/devices': 'token',
      'GET /customers': 'customers.view',
      // Los datos de la tienda: lectura pública.
      'GET /store': 'pública',
      'PATCH /store': 'store.manage',
      // Catálogo: lectura pública, escritura con su permiso.
      'GET /categories': 'pública',
      'GET /categories/:id': 'pública',
      'POST /categories': 'categories.manage',
      'PATCH /categories/:id': 'categories.manage',
      'DELETE /categories/:id': 'categories.manage',
      'GET /products': 'pública',
      'GET /products/:id': 'pública',
      'POST /products': 'products.manage',
      'PATCH /products/:id': 'products.manage',
      'DELETE /products/:id': 'products.manage',
      // La foto: se sube con su permiso y se ve como el catálogo.
      'PUT /products/:id/image': 'products.manage',
      'GET /images/products/:productId/:file': 'pública',
      'GET /promotions/active': 'pública',
      'GET /promotions': 'promotions.manage',
      'GET /promotions/:id': 'promotions.manage',
      'POST /promotions': 'promotions.manage',
      'PATCH /promotions/:id': 'promotions.manage',
      'DELETE /promotions/:id': 'promotions.manage',
      'GET /inventory/movements': 'inventory.view',
      'POST /inventory/movements': 'inventory.adjust',
      'GET /inventory/alerts/low-stock': 'inventory.view',
      'GET /inventory/alerts/expiring': 'inventory.view',
      'POST /orders': 'cuenta',
      'GET /orders/mine': 'cuenta',
      'GET /orders': 'orders.view',
      'PATCH /orders/:id/status': 'orders.updateStatus',
      'GET /vip-customers': 'vip.view',
      'POST /vip-customers': 'vip.manage',
      'DELETE /vip-customers/:id': 'vip.manage',
      'GET /stats/overview': 'stats.view',
      'GET /stats/sales': 'stats.view',
      'GET /stats/top-products': 'stats.view',
      'GET /stats/low-stock': 'stats.view',
      'GET /stats/expiring': 'stats.view',
      'GET /staff/roles': 'staff.manage',
      'GET /staff/roles/:id': 'staff.manage',
      'POST /staff/roles': 'staff.manage',
      'PATCH /staff/roles/:id': 'staff.manage',
      'DELETE /staff/roles/:id': 'staff.manage',
      'GET /staff/members': 'staff.manage',
      'POST /staff/members': 'staff.manage',
      'PATCH /staff/members/:id': 'staff.manage',
      'DELETE /staff/members/:id': 'staff.manage',
      'GET /staff/audit': 'staff.manage',
    });
  });
}
