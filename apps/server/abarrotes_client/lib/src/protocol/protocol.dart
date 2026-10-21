/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'categories/category.dart' as _iwxpkdmg;
import 'inventory/inventory_movement.dart' as _i976ojya;
import 'inventory/movement_type.dart' as _i0rwgybl;
import 'orders/order.dart' as _ia2sbmwd;
import 'orders/order_item.dart' as _is46w9g4;
import 'orders/order_status.dart' as _ishke5og;
import 'products/product.dart' as _io8c7sps;
import 'promotions/promotion.dart' as _i8z66r5b;
import 'promotions/promotion_audience.dart' as _ik9fivqg;
import 'staff/audit_action.dart' as _i6v8ft9w;
import 'staff/audit_log.dart' as _ias3z63p;
import 'staff/permission.dart' as _iwx11llg;
import 'staff/role.dart' as _idva2d1t;
import 'staff/staff_member.dart' as _ihm1xmqc;
import 'supplies/supply.dart' as _iae274dd;
import 'users/device_token.dart' as _ir35tcw0;
import 'users/user.dart' as _ih6cb19o;
import 'vip/vip_customer.dart' as _i4hmll1q;
export 'categories/category.dart';
export 'inventory/inventory_movement.dart';
export 'inventory/movement_type.dart';
export 'orders/order.dart';
export 'orders/order_item.dart';
export 'orders/order_status.dart';
export 'products/product.dart';
export 'promotions/promotion.dart';
export 'promotions/promotion_audience.dart';
export 'staff/audit_action.dart';
export 'staff/audit_log.dart';
export 'staff/permission.dart';
export 'staff/role.dart';
export 'staff/staff_member.dart';
export 'supplies/supply.dart';
export 'users/device_token.dart';
export 'users/user.dart';
export 'vip/vip_customer.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _iwxpkdmg.Category) {
      return _iwxpkdmg.Category.fromJson(data) as T;
    }
    if (t == _i976ojya.InventoryMovement) {
      return _i976ojya.InventoryMovement.fromJson(data) as T;
    }
    if (t == _i0rwgybl.MovementType) {
      return _i0rwgybl.MovementType.fromJson(data) as T;
    }
    if (t == _ia2sbmwd.Order) {
      return _ia2sbmwd.Order.fromJson(data) as T;
    }
    if (t == _is46w9g4.OrderItem) {
      return _is46w9g4.OrderItem.fromJson(data) as T;
    }
    if (t == _ishke5og.OrderStatus) {
      return _ishke5og.OrderStatus.fromJson(data) as T;
    }
    if (t == _io8c7sps.Product) {
      return _io8c7sps.Product.fromJson(data) as T;
    }
    if (t == _i8z66r5b.Promotion) {
      return _i8z66r5b.Promotion.fromJson(data) as T;
    }
    if (t == _ik9fivqg.PromotionAudience) {
      return _ik9fivqg.PromotionAudience.fromJson(data) as T;
    }
    if (t == _i6v8ft9w.AuditAction) {
      return _i6v8ft9w.AuditAction.fromJson(data) as T;
    }
    if (t == _ias3z63p.AuditLog) {
      return _ias3z63p.AuditLog.fromJson(data) as T;
    }
    if (t == _iwx11llg.Permission) {
      return _iwx11llg.Permission.fromJson(data) as T;
    }
    if (t == _idva2d1t.Role) {
      return _idva2d1t.Role.fromJson(data) as T;
    }
    if (t == _ihm1xmqc.StaffMember) {
      return _ihm1xmqc.StaffMember.fromJson(data) as T;
    }
    if (t == _iae274dd.Supply) {
      return _iae274dd.Supply.fromJson(data) as T;
    }
    if (t == _ir35tcw0.DeviceToken) {
      return _ir35tcw0.DeviceToken.fromJson(data) as T;
    }
    if (t == _ih6cb19o.User) {
      return _ih6cb19o.User.fromJson(data) as T;
    }
    if (t == _i4hmll1q.VipCustomer) {
      return _i4hmll1q.VipCustomer.fromJson(data) as T;
    }
    if (t == _isc.getType<_iwxpkdmg.Category?>()) {
      return (data != null ? _iwxpkdmg.Category.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i976ojya.InventoryMovement?>()) {
      return (data != null ? _i976ojya.InventoryMovement.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i0rwgybl.MovementType?>()) {
      return (data != null ? _i0rwgybl.MovementType.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ia2sbmwd.Order?>()) {
      return (data != null ? _ia2sbmwd.Order.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_is46w9g4.OrderItem?>()) {
      return (data != null ? _is46w9g4.OrderItem.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ishke5og.OrderStatus?>()) {
      return (data != null ? _ishke5og.OrderStatus.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_io8c7sps.Product?>()) {
      return (data != null ? _io8c7sps.Product.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i8z66r5b.Promotion?>()) {
      return (data != null ? _i8z66r5b.Promotion.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ik9fivqg.PromotionAudience?>()) {
      return (data != null ? _ik9fivqg.PromotionAudience.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6v8ft9w.AuditAction?>()) {
      return (data != null ? _i6v8ft9w.AuditAction.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ias3z63p.AuditLog?>()) {
      return (data != null ? _ias3z63p.AuditLog.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iwx11llg.Permission?>()) {
      return (data != null ? _iwx11llg.Permission.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_idva2d1t.Role?>()) {
      return (data != null ? _idva2d1t.Role.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ihm1xmqc.StaffMember?>()) {
      return (data != null ? _ihm1xmqc.StaffMember.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iae274dd.Supply?>()) {
      return (data != null ? _iae274dd.Supply.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ir35tcw0.DeviceToken?>()) {
      return (data != null ? _ir35tcw0.DeviceToken.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ih6cb19o.User?>()) {
      return (data != null ? _ih6cb19o.User.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i4hmll1q.VipCustomer?>()) {
      return (data != null ? _i4hmll1q.VipCustomer.fromJson(data) : null) as T;
    }
    if (t == List<_io8c7sps.Product>) {
      return (data as List)
              .map((e) => deserialize<_io8c7sps.Product>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_io8c7sps.Product>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_io8c7sps.Product>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_is46w9g4.OrderItem>) {
      return (data as List)
              .map((e) => deserialize<_is46w9g4.OrderItem>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_is46w9g4.OrderItem>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_is46w9g4.OrderItem>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i976ojya.InventoryMovement>) {
      return (data as List)
              .map((e) => deserialize<_i976ojya.InventoryMovement>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_i976ojya.InventoryMovement>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i976ojya.InventoryMovement>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i8z66r5b.Promotion>) {
      return (data as List)
              .map((e) => deserialize<_i8z66r5b.Promotion>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_i8z66r5b.Promotion>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i8z66r5b.Promotion>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_iwx11llg.Permission>) {
      return (data as List)
              .map((e) => deserialize<_iwx11llg.Permission>(e))
              .toList()
          as T;
    }
    if (t == List<_ihm1xmqc.StaffMember>) {
      return (data as List)
              .map((e) => deserialize<_ihm1xmqc.StaffMember>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_ihm1xmqc.StaffMember>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ihm1xmqc.StaffMember>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_ia2sbmwd.Order>) {
      return (data as List).map((e) => deserialize<_ia2sbmwd.Order>(e)).toList()
          as T;
    }
    if (t == _isc.getType<List<_ia2sbmwd.Order>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ia2sbmwd.Order>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i4hmll1q.VipCustomer>) {
      return (data as List)
              .map((e) => deserialize<_i4hmll1q.VipCustomer>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_i4hmll1q.VipCustomer>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i4hmll1q.VipCustomer>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_ir35tcw0.DeviceToken>) {
      return (data as List)
              .map((e) => deserialize<_ir35tcw0.DeviceToken>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_ir35tcw0.DeviceToken>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ir35tcw0.DeviceToken>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_ias3z63p.AuditLog>) {
      return (data as List)
              .map((e) => deserialize<_ias3z63p.AuditLog>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_ias3z63p.AuditLog>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ias3z63p.AuditLog>(e))
                    .toList()
              : null)
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _iwxpkdmg.Category => 'Category',
      _i976ojya.InventoryMovement => 'InventoryMovement',
      _i0rwgybl.MovementType => 'MovementType',
      _ia2sbmwd.Order => 'Order',
      _is46w9g4.OrderItem => 'OrderItem',
      _ishke5og.OrderStatus => 'OrderStatus',
      _io8c7sps.Product => 'Product',
      _i8z66r5b.Promotion => 'Promotion',
      _ik9fivqg.PromotionAudience => 'PromotionAudience',
      _i6v8ft9w.AuditAction => 'AuditAction',
      _ias3z63p.AuditLog => 'AuditLog',
      _iwx11llg.Permission => 'Permission',
      _idva2d1t.Role => 'Role',
      _ihm1xmqc.StaffMember => 'StaffMember',
      _iae274dd.Supply => 'Supply',
      _ir35tcw0.DeviceToken => 'DeviceToken',
      _ih6cb19o.User => 'User',
      _i4hmll1q.VipCustomer => 'VipCustomer',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('abarrotes.', '');
    }

    switch (data) {
      case _iwxpkdmg.Category():
        return 'Category';
      case _i976ojya.InventoryMovement():
        return 'InventoryMovement';
      case _i0rwgybl.MovementType():
        return 'MovementType';
      case _ia2sbmwd.Order():
        return 'Order';
      case _is46w9g4.OrderItem():
        return 'OrderItem';
      case _ishke5og.OrderStatus():
        return 'OrderStatus';
      case _io8c7sps.Product():
        return 'Product';
      case _i8z66r5b.Promotion():
        return 'Promotion';
      case _ik9fivqg.PromotionAudience():
        return 'PromotionAudience';
      case _i6v8ft9w.AuditAction():
        return 'AuditAction';
      case _ias3z63p.AuditLog():
        return 'AuditLog';
      case _iwx11llg.Permission():
        return 'Permission';
      case _idva2d1t.Role():
        return 'Role';
      case _ihm1xmqc.StaffMember():
        return 'StaffMember';
      case _iae274dd.Supply():
        return 'Supply';
      case _ir35tcw0.DeviceToken():
        return 'DeviceToken';
      case _ih6cb19o.User():
        return 'User';
      case _i4hmll1q.VipCustomer():
        return 'VipCustomer';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Category') {
      return deserialize<_iwxpkdmg.Category>(data['data']);
    }
    if (dataClassName == 'InventoryMovement') {
      return deserialize<_i976ojya.InventoryMovement>(data['data']);
    }
    if (dataClassName == 'MovementType') {
      return deserialize<_i0rwgybl.MovementType>(data['data']);
    }
    if (dataClassName == 'Order') {
      return deserialize<_ia2sbmwd.Order>(data['data']);
    }
    if (dataClassName == 'OrderItem') {
      return deserialize<_is46w9g4.OrderItem>(data['data']);
    }
    if (dataClassName == 'OrderStatus') {
      return deserialize<_ishke5og.OrderStatus>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_io8c7sps.Product>(data['data']);
    }
    if (dataClassName == 'Promotion') {
      return deserialize<_i8z66r5b.Promotion>(data['data']);
    }
    if (dataClassName == 'PromotionAudience') {
      return deserialize<_ik9fivqg.PromotionAudience>(data['data']);
    }
    if (dataClassName == 'AuditAction') {
      return deserialize<_i6v8ft9w.AuditAction>(data['data']);
    }
    if (dataClassName == 'AuditLog') {
      return deserialize<_ias3z63p.AuditLog>(data['data']);
    }
    if (dataClassName == 'Permission') {
      return deserialize<_iwx11llg.Permission>(data['data']);
    }
    if (dataClassName == 'Role') {
      return deserialize<_idva2d1t.Role>(data['data']);
    }
    if (dataClassName == 'StaffMember') {
      return deserialize<_ihm1xmqc.StaffMember>(data['data']);
    }
    if (dataClassName == 'Supply') {
      return deserialize<_iae274dd.Supply>(data['data']);
    }
    if (dataClassName == 'DeviceToken') {
      return deserialize<_ir35tcw0.DeviceToken>(data['data']);
    }
    if (dataClassName == 'User') {
      return deserialize<_ih6cb19o.User>(data['data']);
    }
    if (dataClassName == 'VipCustomer') {
      return deserialize<_i4hmll1q.VipCustomer>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  @override
  String getModuleName() => 'abarrotes';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
