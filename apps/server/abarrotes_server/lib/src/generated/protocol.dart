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
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'categories/category.dart' as _iwxpkdmg;
import 'inventory/inventory_movement.dart' as _i976ojya;
import 'inventory/movement_type.dart' as _i0rwgybl;
import 'orders/order.dart' as _ia2sbmwd;
import 'orders/order_item.dart' as _is46w9g4;
import 'orders/order_status.dart' as _ishke5og;
import 'products/product.dart' as _io8c7sps;
import 'promotions/promotion.dart' as _i8z66r5b;
import 'supplies/supply.dart' as _iae274dd;
import 'users/user.dart' as _ih6cb19o;
import 'users/user_role.dart' as _iyk67ys5;
export 'categories/category.dart';
export 'inventory/inventory_movement.dart';
export 'inventory/movement_type.dart';
export 'orders/order.dart';
export 'orders/order_item.dart';
export 'orders/order_status.dart';
export 'products/product.dart';
export 'promotions/promotion.dart';
export 'supplies/supply.dart';
export 'users/user.dart';
export 'users/user_role.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'categories',
      dartName: 'Category',
      schema: 'public',
      module: 'abarrotes',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'categories_name_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'inventory_movements',
      dartName: 'InventoryMovement',
      schema: 'public',
      module: 'abarrotes',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'type',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:MovementType',
        ),
        _isp.ColumnDefinition(
          name: 'quantity',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'reason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'productId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'inventory_movements_fk_0',
          columns: ['productId'],
          referenceTable: 'products',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.cascade,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'inventory_movements_fk_1',
          columns: ['userId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.cascade,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'order_items',
      dartName: 'OrderItem',
      schema: 'public',
      module: 'abarrotes',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'quantity',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'unitPriceCents',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'orderId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'productId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'order_items_fk_0',
          columns: ['orderId'],
          referenceTable: 'orders',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.cascade,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'order_items_fk_1',
          columns: ['productId'],
          referenceTable: 'products',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.cascade,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'orders',
      dartName: 'Order',
      schema: 'public',
      module: 'abarrotes',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:OrderStatus',
          columnDefault: '\'pendingConfirmation\'',
        ),
        _isp.ColumnDefinition(
          name: 'totalCents',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'deliveryAddress',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'customerId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'orders_fk_0',
          columns: ['customerId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.cascade,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'products',
      dartName: 'Product',
      schema: 'public',
      module: 'abarrotes',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sku',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'priceCents',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'imageUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'active',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'currentStock',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'minStock',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'expirationDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'categoryId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'products_fk_0',
          columns: ['categoryId'],
          referenceTable: 'categories',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.cascade,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'products_sku_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sku',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'promotions',
      dartName: 'Promotion',
      schema: 'public',
      module: 'abarrotes',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'promoPriceCents',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'startDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'endDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'active',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'productId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'promotions_fk_0',
          columns: ['productId'],
          referenceTable: 'products',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.cascade,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'supplies',
      dartName: 'Supply',
      schema: 'public',
      module: 'abarrotes',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'unit',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'quantity',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'minQuantity',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'users',
      dartName: 'User',
      schema: 'public',
      module: 'abarrotes',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'firebaseUid',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'email',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'phone',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:UserRole',
          columnDefault: '\'customer\'',
        ),
        _isp.ColumnDefinition(
          name: 'address',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'users_firebase_uid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'firebaseUid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'users_email_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._isp.Protocol.targetTableDefinitions,
  ];

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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
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
    if (t == _iae274dd.Supply) {
      return _iae274dd.Supply.fromJson(data) as T;
    }
    if (t == _ih6cb19o.User) {
      return _ih6cb19o.User.fromJson(data) as T;
    }
    if (t == _iyk67ys5.UserRole) {
      return _iyk67ys5.UserRole.fromJson(data) as T;
    }
    if (t == _is.getType<_iwxpkdmg.Category?>()) {
      return (data != null ? _iwxpkdmg.Category.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i976ojya.InventoryMovement?>()) {
      return (data != null ? _i976ojya.InventoryMovement.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i0rwgybl.MovementType?>()) {
      return (data != null ? _i0rwgybl.MovementType.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ia2sbmwd.Order?>()) {
      return (data != null ? _ia2sbmwd.Order.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_is46w9g4.OrderItem?>()) {
      return (data != null ? _is46w9g4.OrderItem.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ishke5og.OrderStatus?>()) {
      return (data != null ? _ishke5og.OrderStatus.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_io8c7sps.Product?>()) {
      return (data != null ? _io8c7sps.Product.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i8z66r5b.Promotion?>()) {
      return (data != null ? _i8z66r5b.Promotion.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iae274dd.Supply?>()) {
      return (data != null ? _iae274dd.Supply.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ih6cb19o.User?>()) {
      return (data != null ? _ih6cb19o.User.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyk67ys5.UserRole?>()) {
      return (data != null ? _iyk67ys5.UserRole.fromJson(data) : null) as T;
    }
    if (t == List<_io8c7sps.Product>) {
      return (data as List)
              .map((e) => deserialize<_io8c7sps.Product>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_io8c7sps.Product>?>()) {
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
    if (t == _is.getType<List<_is46w9g4.OrderItem>?>()) {
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
    if (t == _is.getType<List<_i976ojya.InventoryMovement>?>()) {
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
    if (t == _is.getType<List<_i8z66r5b.Promotion>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i8z66r5b.Promotion>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_ia2sbmwd.Order>) {
      return (data as List).map((e) => deserialize<_ia2sbmwd.Order>(e)).toList()
          as T;
    }
    if (t == _is.getType<List<_ia2sbmwd.Order>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ia2sbmwd.Order>(e))
                    .toList()
              : null)
          as T;
    }
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
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
      _iae274dd.Supply => 'Supply',
      _ih6cb19o.User => 'User',
      _iyk67ys5.UserRole => 'UserRole',
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
      case _iae274dd.Supply():
        return 'Supply';
      case _ih6cb19o.User():
        return 'User';
      case _iyk67ys5.UserRole():
        return 'UserRole';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
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
    if (dataClassName == 'Supply') {
      return deserialize<_iae274dd.Supply>(data['data']);
    }
    if (dataClassName == 'User') {
      return deserialize<_ih6cb19o.User>(data['data']);
    }
    if (dataClassName == 'UserRole') {
      return deserialize<_iyk67ys5.UserRole>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _iwxpkdmg.Category:
        return _iwxpkdmg.Category.t;
      case _i976ojya.InventoryMovement:
        return _i976ojya.InventoryMovement.t;
      case _ia2sbmwd.Order:
        return _ia2sbmwd.Order.t;
      case _is46w9g4.OrderItem:
        return _is46w9g4.OrderItem.t;
      case _io8c7sps.Product:
        return _io8c7sps.Product.t;
      case _i8z66r5b.Promotion:
        return _i8z66r5b.Promotion.t;
      case _iae274dd.Supply:
        return _iae274dd.Supply.t;
      case _ih6cb19o.User:
        return _ih6cb19o.User.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

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
    try {
      return _isp.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
