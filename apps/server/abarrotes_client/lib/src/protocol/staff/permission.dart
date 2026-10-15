/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// El catálogo de permisos del personal: la fuente de verdad. En la API
/// viajan como "products.view", "orders.updateStatus" (permissionKey, en
/// staff/permissions.dart). Sumar uno es agregarlo aquí y usarlo en su ruta
/// con RequirePermission: el rol Administrador lo tiene solo.
enum Permission implements _isc.SerializableModel {
  productsView,
  productsManage,
  categoriesManage,
  ordersView,
  ordersUpdateStatus,
  inventoryView,
  inventoryAdjust,
  promotionsManage,
  vipView,
  vipManage,
  statsView,
  customersView,
  staffManage,
  storeManage;

  static Permission fromJson(String name) {
    switch (name) {
      case 'productsView':
        return Permission.productsView;
      case 'productsManage':
        return Permission.productsManage;
      case 'categoriesManage':
        return Permission.categoriesManage;
      case 'ordersView':
        return Permission.ordersView;
      case 'ordersUpdateStatus':
        return Permission.ordersUpdateStatus;
      case 'inventoryView':
        return Permission.inventoryView;
      case 'inventoryAdjust':
        return Permission.inventoryAdjust;
      case 'promotionsManage':
        return Permission.promotionsManage;
      case 'vipView':
        return Permission.vipView;
      case 'vipManage':
        return Permission.vipManage;
      case 'statsView':
        return Permission.statsView;
      case 'customersView':
        return Permission.customersView;
      case 'staffManage':
        return Permission.staffManage;
      case 'storeManage':
        return Permission.storeManage;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "Permission"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
