/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:abarrotes_server/src/generated/protocol.dart' as _i1p9jj0z;
import 'package:serverpod/serverpod.dart' as _is;
import '../inventory/inventory_movement.dart' as _i4yp9mtd;
import '../orders/order.dart' as _ij3i88ow;
import '../staff/audit_log.dart' as _iohhzbvb;
import '../staff/staff_member.dart' as _i3fhtrko;
import '../users/device_token.dart' as _iuurxiuf;
import '../vip/vip_customer.dart' as _icy1qtyi;

/// Cuenta de la plataforma. La autenticación vive en Firebase: aquí se guarda
/// el uid de Firebase, nunca una contraseña. Los permisos del personal no
/// están aquí: salen de StaffMember y su Role, por el correo.
abstract class User
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  User._({
    this.id,
    required this.firebaseUid,
    required this.email,
    bool? emailVerified,
    required this.name,
    this.phone,
    this.address,
    DateTime? createdAt,
    this.orders,
    this.inventoryMovements,
    this.vipCustomersAdded,
    this.deviceTokens,
    this.staffMembersAdded,
    this.auditLogs,
  }) : emailVerified = emailVerified ?? false,
       createdAt = createdAt ?? DateTime.now();

  factory User({
    _is.UuidValue? id,
    required String firebaseUid,
    required String email,
    bool? emailVerified,
    required String name,
    String? phone,
    String? address,
    DateTime? createdAt,
    List<_ij3i88ow.Order>? orders,
    List<_i4yp9mtd.InventoryMovement>? inventoryMovements,
    List<_icy1qtyi.VipCustomer>? vipCustomersAdded,
    List<_iuurxiuf.DeviceToken>? deviceTokens,
    List<_i3fhtrko.StaffMember>? staffMembersAdded,
    List<_iohhzbvb.AuditLog>? auditLogs,
  }) = _UserImpl;

  factory User.fromJson(Map<String, dynamic> jsonSerialization) {
    return User(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      firebaseUid: jsonSerialization['firebaseUid'] as String,
      email: jsonSerialization['email'] as String,
      emailVerified: jsonSerialization['emailVerified'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['emailVerified']),
      name: jsonSerialization['name'] as String,
      phone: jsonSerialization['phone'] as String?,
      address: jsonSerialization['address'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      orders: jsonSerialization['orders'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_ij3i88ow.Order>>(
              jsonSerialization['orders'],
            ),
      inventoryMovements: jsonSerialization['inventoryMovements'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_i4yp9mtd.InventoryMovement>>(
              jsonSerialization['inventoryMovements'],
            ),
      vipCustomersAdded: jsonSerialization['vipCustomersAdded'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_icy1qtyi.VipCustomer>>(
              jsonSerialization['vipCustomersAdded'],
            ),
      deviceTokens: jsonSerialization['deviceTokens'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_iuurxiuf.DeviceToken>>(
              jsonSerialization['deviceTokens'],
            ),
      staffMembersAdded: jsonSerialization['staffMembersAdded'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_i3fhtrko.StaffMember>>(
              jsonSerialization['staffMembersAdded'],
            ),
      auditLogs: jsonSerialization['auditLogs'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_iohhzbvb.AuditLog>>(
              jsonSerialization['auditLogs'],
            ),
    );
  }

  static final t = UserTable();

  static const db = UserRepository._();

  @override
  _is.UuidValue? id;

  /// uid de Firebase Auth (claim `sub` del ID token).
  String firebaseUid;

  String email;

  /// Lo último que dijo el ID token (email_verified). Lo usa el aviso push,
  /// que no tiene un token del cliente a mano.
  bool emailVerified;

  String name;

  String? phone;

  String? address;

  DateTime createdAt;

  List<_ij3i88ow.Order>? orders;

  List<_i4yp9mtd.InventoryMovement>? inventoryMovements;

  List<_icy1qtyi.VipCustomer>? vipCustomersAdded;

  List<_iuurxiuf.DeviceToken>? deviceTokens;

  List<_i3fhtrko.StaffMember>? staffMembersAdded;

  List<_iohhzbvb.AuditLog>? auditLogs;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  User copyWith({
    _is.UuidValue? id,
    String? firebaseUid,
    String? email,
    bool? emailVerified,
    String? name,
    String? phone,
    String? address,
    DateTime? createdAt,
    List<_ij3i88ow.Order>? orders,
    List<_i4yp9mtd.InventoryMovement>? inventoryMovements,
    List<_icy1qtyi.VipCustomer>? vipCustomersAdded,
    List<_iuurxiuf.DeviceToken>? deviceTokens,
    List<_i3fhtrko.StaffMember>? staffMembersAdded,
    List<_iohhzbvb.AuditLog>? auditLogs,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'User',
      if (id != null) 'id': id?.toJson(),
      'firebaseUid': firebaseUid,
      'email': email,
      'emailVerified': emailVerified,
      'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      'createdAt': createdAt.toJson(),
      if (orders != null)
        'orders': orders?.toJson(valueToJson: (v) => v.toJson()),
      if (inventoryMovements != null)
        'inventoryMovements': inventoryMovements?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      if (vipCustomersAdded != null)
        'vipCustomersAdded': vipCustomersAdded?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      if (deviceTokens != null)
        'deviceTokens': deviceTokens?.toJson(valueToJson: (v) => v.toJson()),
      if (staffMembersAdded != null)
        'staffMembersAdded': staffMembersAdded?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      if (auditLogs != null)
        'auditLogs': auditLogs?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'User',
      if (id != null) 'id': id?.toJson(),
      'firebaseUid': firebaseUid,
      'email': email,
      'emailVerified': emailVerified,
      'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      'createdAt': createdAt.toJson(),
      if (orders != null)
        'orders': orders?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (inventoryMovements != null)
        'inventoryMovements': inventoryMovements?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (vipCustomersAdded != null)
        'vipCustomersAdded': vipCustomersAdded?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (deviceTokens != null)
        'deviceTokens': deviceTokens?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (staffMembersAdded != null)
        'staffMembersAdded': staffMembersAdded?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (auditLogs != null)
        'auditLogs': auditLogs?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
    };
  }

  static UserInclude include({
    _ij3i88ow.OrderIncludeList? orders,
    _i4yp9mtd.InventoryMovementIncludeList? inventoryMovements,
    _icy1qtyi.VipCustomerIncludeList? vipCustomersAdded,
    _iuurxiuf.DeviceTokenIncludeList? deviceTokens,
    _i3fhtrko.StaffMemberIncludeList? staffMembersAdded,
    _iohhzbvb.AuditLogIncludeList? auditLogs,
  }) {
    return UserInclude._(
      orders: orders,
      inventoryMovements: inventoryMovements,
      vipCustomersAdded: vipCustomersAdded,
      deviceTokens: deviceTokens,
      staffMembersAdded: staffMembersAdded,
      auditLogs: auditLogs,
    );
  }

  static UserIncludeList includeList({
    _is.WhereExpressionBuilder<UserTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UserTable>? orderBy,
    _is.OrderByListBuilder<UserTable>? orderByList,
    UserInclude? include,
  }) {
    return UserIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(User.t),
      orderByList: orderByList?.call(User.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserImpl extends User {
  _UserImpl({
    _is.UuidValue? id,
    required String firebaseUid,
    required String email,
    bool? emailVerified,
    required String name,
    String? phone,
    String? address,
    DateTime? createdAt,
    List<_ij3i88ow.Order>? orders,
    List<_i4yp9mtd.InventoryMovement>? inventoryMovements,
    List<_icy1qtyi.VipCustomer>? vipCustomersAdded,
    List<_iuurxiuf.DeviceToken>? deviceTokens,
    List<_i3fhtrko.StaffMember>? staffMembersAdded,
    List<_iohhzbvb.AuditLog>? auditLogs,
  }) : super._(
         id: id,
         firebaseUid: firebaseUid,
         email: email,
         emailVerified: emailVerified,
         name: name,
         phone: phone,
         address: address,
         createdAt: createdAt,
         orders: orders,
         inventoryMovements: inventoryMovements,
         vipCustomersAdded: vipCustomersAdded,
         deviceTokens: deviceTokens,
         staffMembersAdded: staffMembersAdded,
         auditLogs: auditLogs,
       );

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  User copyWith({
    Object? id = _Undefined,
    String? firebaseUid,
    String? email,
    bool? emailVerified,
    String? name,
    Object? phone = _Undefined,
    Object? address = _Undefined,
    DateTime? createdAt,
    Object? orders = _Undefined,
    Object? inventoryMovements = _Undefined,
    Object? vipCustomersAdded = _Undefined,
    Object? deviceTokens = _Undefined,
    Object? staffMembersAdded = _Undefined,
    Object? auditLogs = _Undefined,
  }) {
    return User(
      id: id is _is.UuidValue? ? id : this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      name: name ?? this.name,
      phone: phone is String? ? phone : this.phone,
      address: address is String? ? address : this.address,
      createdAt: createdAt ?? this.createdAt,
      orders: orders is List<_ij3i88ow.Order>?
          ? orders
          : this.orders?.map((e0) => e0.copyWith()).toList(),
      inventoryMovements:
          inventoryMovements is List<_i4yp9mtd.InventoryMovement>?
          ? inventoryMovements
          : this.inventoryMovements?.map((e0) => e0.copyWith()).toList(),
      vipCustomersAdded: vipCustomersAdded is List<_icy1qtyi.VipCustomer>?
          ? vipCustomersAdded
          : this.vipCustomersAdded?.map((e0) => e0.copyWith()).toList(),
      deviceTokens: deviceTokens is List<_iuurxiuf.DeviceToken>?
          ? deviceTokens
          : this.deviceTokens?.map((e0) => e0.copyWith()).toList(),
      staffMembersAdded: staffMembersAdded is List<_i3fhtrko.StaffMember>?
          ? staffMembersAdded
          : this.staffMembersAdded?.map((e0) => e0.copyWith()).toList(),
      auditLogs: auditLogs is List<_iohhzbvb.AuditLog>?
          ? auditLogs
          : this.auditLogs?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class UserUpdateTable extends _is.UpdateTable<UserTable> {
  UserUpdateTable(super.table);

  _is.ColumnValue<String, String> firebaseUid(String value) => _is.ColumnValue(
    table.firebaseUid,
    value,
  );

  _is.ColumnValue<String, String> email(String value) => _is.ColumnValue(
    table.email,
    value,
  );

  _is.ColumnValue<bool, bool> emailVerified(bool value) => _is.ColumnValue(
    table.emailVerified,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> phone(String? value) => _is.ColumnValue(
    table.phone,
    value,
  );

  _is.ColumnValue<String, String> address(String? value) => _is.ColumnValue(
    table.address,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class UserTable extends _is.Table<_is.UuidValue?> {
  UserTable({super.tableRelation}) : super(tableName: 'users') {
    updateTable = UserUpdateTable(this);
    firebaseUid = _is.ColumnString(
      'firebaseUid',
      this,
    );
    email = _is.ColumnString(
      'email',
      this,
    );
    emailVerified = _is.ColumnBool(
      'emailVerified',
      this,
      hasDefault: true,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    phone = _is.ColumnString(
      'phone',
      this,
    );
    address = _is.ColumnString(
      'address',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final UserUpdateTable updateTable;

  /// uid de Firebase Auth (claim `sub` del ID token).
  late final _is.ColumnString firebaseUid;

  late final _is.ColumnString email;

  /// Lo último que dijo el ID token (email_verified). Lo usa el aviso push,
  /// que no tiene un token del cliente a mano.
  late final _is.ColumnBool emailVerified;

  late final _is.ColumnString name;

  late final _is.ColumnString phone;

  late final _is.ColumnString address;

  late final _is.ColumnDateTime createdAt;

  _ij3i88ow.OrderTable? ___orders;

  _is.ManyRelation<_ij3i88ow.OrderTable>? _orders;

  _i4yp9mtd.InventoryMovementTable? ___inventoryMovements;

  _is.ManyRelation<_i4yp9mtd.InventoryMovementTable>? _inventoryMovements;

  _icy1qtyi.VipCustomerTable? ___vipCustomersAdded;

  _is.ManyRelation<_icy1qtyi.VipCustomerTable>? _vipCustomersAdded;

  _iuurxiuf.DeviceTokenTable? ___deviceTokens;

  _is.ManyRelation<_iuurxiuf.DeviceTokenTable>? _deviceTokens;

  _i3fhtrko.StaffMemberTable? ___staffMembersAdded;

  _is.ManyRelation<_i3fhtrko.StaffMemberTable>? _staffMembersAdded;

  _iohhzbvb.AuditLogTable? ___auditLogs;

  _is.ManyRelation<_iohhzbvb.AuditLogTable>? _auditLogs;

  _ij3i88ow.OrderTable get __orders {
    if (___orders != null) return ___orders!;
    ___orders = _is.createRelationTable(
      relationFieldName: '__orders',
      field: User.t.id,
      foreignField: _ij3i88ow.Order.t.customerId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ij3i88ow.OrderTable(tableRelation: foreignTableRelation),
    );
    return ___orders!;
  }

  _i4yp9mtd.InventoryMovementTable get __inventoryMovements {
    if (___inventoryMovements != null) return ___inventoryMovements!;
    ___inventoryMovements = _is.createRelationTable(
      relationFieldName: '__inventoryMovements',
      field: User.t.id,
      foreignField: _i4yp9mtd.InventoryMovement.t.userId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4yp9mtd.InventoryMovementTable(tableRelation: foreignTableRelation),
    );
    return ___inventoryMovements!;
  }

  _icy1qtyi.VipCustomerTable get __vipCustomersAdded {
    if (___vipCustomersAdded != null) return ___vipCustomersAdded!;
    ___vipCustomersAdded = _is.createRelationTable(
      relationFieldName: '__vipCustomersAdded',
      field: User.t.id,
      foreignField: _icy1qtyi.VipCustomer.t.addedByUserId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _icy1qtyi.VipCustomerTable(tableRelation: foreignTableRelation),
    );
    return ___vipCustomersAdded!;
  }

  _iuurxiuf.DeviceTokenTable get __deviceTokens {
    if (___deviceTokens != null) return ___deviceTokens!;
    ___deviceTokens = _is.createRelationTable(
      relationFieldName: '__deviceTokens',
      field: User.t.id,
      foreignField: _iuurxiuf.DeviceToken.t.userId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iuurxiuf.DeviceTokenTable(tableRelation: foreignTableRelation),
    );
    return ___deviceTokens!;
  }

  _i3fhtrko.StaffMemberTable get __staffMembersAdded {
    if (___staffMembersAdded != null) return ___staffMembersAdded!;
    ___staffMembersAdded = _is.createRelationTable(
      relationFieldName: '__staffMembersAdded',
      field: User.t.id,
      foreignField: _i3fhtrko.StaffMember.t.addedByUserId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3fhtrko.StaffMemberTable(tableRelation: foreignTableRelation),
    );
    return ___staffMembersAdded!;
  }

  _iohhzbvb.AuditLogTable get __auditLogs {
    if (___auditLogs != null) return ___auditLogs!;
    ___auditLogs = _is.createRelationTable(
      relationFieldName: '__auditLogs',
      field: User.t.id,
      foreignField: _iohhzbvb.AuditLog.t.actorUserId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iohhzbvb.AuditLogTable(tableRelation: foreignTableRelation),
    );
    return ___auditLogs!;
  }

  _is.ManyRelation<_ij3i88ow.OrderTable> get orders {
    if (_orders != null) return _orders!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'orders',
      field: User.t.id,
      foreignField: _ij3i88ow.Order.t.customerId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ij3i88ow.OrderTable(tableRelation: foreignTableRelation),
    );
    _orders = _is.ManyRelation<_ij3i88ow.OrderTable>(
      tableWithRelations: relationTable,
      table: _ij3i88ow.OrderTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _orders!;
  }

  _is.ManyRelation<_i4yp9mtd.InventoryMovementTable> get inventoryMovements {
    if (_inventoryMovements != null) return _inventoryMovements!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'inventoryMovements',
      field: User.t.id,
      foreignField: _i4yp9mtd.InventoryMovement.t.userId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4yp9mtd.InventoryMovementTable(tableRelation: foreignTableRelation),
    );
    _inventoryMovements = _is.ManyRelation<_i4yp9mtd.InventoryMovementTable>(
      tableWithRelations: relationTable,
      table: _i4yp9mtd.InventoryMovementTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _inventoryMovements!;
  }

  _is.ManyRelation<_icy1qtyi.VipCustomerTable> get vipCustomersAdded {
    if (_vipCustomersAdded != null) return _vipCustomersAdded!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'vipCustomersAdded',
      field: User.t.id,
      foreignField: _icy1qtyi.VipCustomer.t.addedByUserId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _icy1qtyi.VipCustomerTable(tableRelation: foreignTableRelation),
    );
    _vipCustomersAdded = _is.ManyRelation<_icy1qtyi.VipCustomerTable>(
      tableWithRelations: relationTable,
      table: _icy1qtyi.VipCustomerTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _vipCustomersAdded!;
  }

  _is.ManyRelation<_iuurxiuf.DeviceTokenTable> get deviceTokens {
    if (_deviceTokens != null) return _deviceTokens!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'deviceTokens',
      field: User.t.id,
      foreignField: _iuurxiuf.DeviceToken.t.userId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iuurxiuf.DeviceTokenTable(tableRelation: foreignTableRelation),
    );
    _deviceTokens = _is.ManyRelation<_iuurxiuf.DeviceTokenTable>(
      tableWithRelations: relationTable,
      table: _iuurxiuf.DeviceTokenTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _deviceTokens!;
  }

  _is.ManyRelation<_i3fhtrko.StaffMemberTable> get staffMembersAdded {
    if (_staffMembersAdded != null) return _staffMembersAdded!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'staffMembersAdded',
      field: User.t.id,
      foreignField: _i3fhtrko.StaffMember.t.addedByUserId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3fhtrko.StaffMemberTable(tableRelation: foreignTableRelation),
    );
    _staffMembersAdded = _is.ManyRelation<_i3fhtrko.StaffMemberTable>(
      tableWithRelations: relationTable,
      table: _i3fhtrko.StaffMemberTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _staffMembersAdded!;
  }

  _is.ManyRelation<_iohhzbvb.AuditLogTable> get auditLogs {
    if (_auditLogs != null) return _auditLogs!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'auditLogs',
      field: User.t.id,
      foreignField: _iohhzbvb.AuditLog.t.actorUserId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iohhzbvb.AuditLogTable(tableRelation: foreignTableRelation),
    );
    _auditLogs = _is.ManyRelation<_iohhzbvb.AuditLogTable>(
      tableWithRelations: relationTable,
      table: _iohhzbvb.AuditLogTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _auditLogs!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    firebaseUid,
    email,
    emailVerified,
    name,
    phone,
    address,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'orders') {
      return __orders;
    }
    if (relationField == 'inventoryMovements') {
      return __inventoryMovements;
    }
    if (relationField == 'vipCustomersAdded') {
      return __vipCustomersAdded;
    }
    if (relationField == 'deviceTokens') {
      return __deviceTokens;
    }
    if (relationField == 'staffMembersAdded') {
      return __staffMembersAdded;
    }
    if (relationField == 'auditLogs') {
      return __auditLogs;
    }
    return null;
  }
}

class UserInclude extends _is.IncludeObject {
  UserInclude._({
    _ij3i88ow.OrderIncludeList? orders,
    _i4yp9mtd.InventoryMovementIncludeList? inventoryMovements,
    _icy1qtyi.VipCustomerIncludeList? vipCustomersAdded,
    _iuurxiuf.DeviceTokenIncludeList? deviceTokens,
    _i3fhtrko.StaffMemberIncludeList? staffMembersAdded,
    _iohhzbvb.AuditLogIncludeList? auditLogs,
  }) {
    _orders = orders;
    _inventoryMovements = inventoryMovements;
    _vipCustomersAdded = vipCustomersAdded;
    _deviceTokens = deviceTokens;
    _staffMembersAdded = staffMembersAdded;
    _auditLogs = auditLogs;
  }

  _ij3i88ow.OrderIncludeList? _orders;

  _i4yp9mtd.InventoryMovementIncludeList? _inventoryMovements;

  _icy1qtyi.VipCustomerIncludeList? _vipCustomersAdded;

  _iuurxiuf.DeviceTokenIncludeList? _deviceTokens;

  _i3fhtrko.StaffMemberIncludeList? _staffMembersAdded;

  _iohhzbvb.AuditLogIncludeList? _auditLogs;

  @override
  Map<String, _is.Include?> get includes => {
    'orders': _orders,
    'inventoryMovements': _inventoryMovements,
    'vipCustomersAdded': _vipCustomersAdded,
    'deviceTokens': _deviceTokens,
    'staffMembersAdded': _staffMembersAdded,
    'auditLogs': _auditLogs,
  };

  @override
  _is.Table<_is.UuidValue?> get table => User.t;
}

class UserIncludeList extends _is.IncludeList {
  UserIncludeList._({
    _is.WhereExpressionBuilder<UserTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(User.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => User.t;
}

class UserRepository {
  const UserRepository._();

  final attach = const UserAttachRepository._();

  final attachRow = const UserAttachRowRepository._();

  final detach = const UserDetachRepository._();

  final detachRow = const UserDetachRowRepository._();

  /// Returns a list of [User]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<User>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UserTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UserTable>? orderBy,
    _is.OrderByListBuilder<UserTable>? orderByList,
    _is.Transaction? transaction,
    UserInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<User>(
      where: where?.call(User.t),
      orderBy: orderBy?.call(User.t),
      orderByList: orderByList?.call(User.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [User] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<User?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UserTable>? where,
    int? offset,
    _is.OrderByBuilder<UserTable>? orderBy,
    _is.OrderByListBuilder<UserTable>? orderByList,
    _is.Transaction? transaction,
    UserInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<User>(
      where: where?.call(User.t),
      orderBy: orderBy?.call(User.t),
      orderByList: orderByList?.call(User.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [User] by its [id] or null if no such row exists.
  Future<User?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    UserInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<User>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [User]s in the list and returns the inserted rows.
  ///
  /// The returned [User]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<User>> insert(
    _is.DatabaseSession session,
    List<User> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<User>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [User] and returns the inserted row.
  ///
  /// The returned [User] will have its `id` field set.
  Future<User> insertRow(
    _is.DatabaseSession session,
    User row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<User>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [User]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [User]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<User>> upsert(
    _is.DatabaseSession session,
    List<User> rows, {
    required _is.ColumnSelections<UserTable> conflictColumns,
    _is.ColumnSelections<UserTable>? updateColumns,
    _is.WhereExpressionBuilder<UserTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<User>(
      rows,
      conflictColumns: conflictColumns(User.t),
      updateColumns: updateColumns?.call(User.t),
      updateWhere: updateWhere?.call(User.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [User] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [User] will have its `id` field set.
  Future<User?> upsertRow(
    _is.DatabaseSession session,
    User row, {
    required _is.ColumnSelections<UserTable> conflictColumns,
    _is.ColumnSelections<UserTable>? updateColumns,
    _is.WhereExpressionBuilder<UserTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<User>(
      row,
      conflictColumns: conflictColumns(User.t),
      updateColumns: updateColumns?.call(User.t),
      updateWhere: updateWhere?.call(User.t),
      transaction: transaction,
    );
  }

  /// Updates all [User]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<User>> update(
    _is.DatabaseSession session,
    List<User> rows, {
    _is.ColumnSelections<UserTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<User>(
      rows,
      columns: columns?.call(User.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [User]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<User> updateRow(
    _is.DatabaseSession session,
    User row, {
    _is.ColumnSelections<UserTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<User>(
      row,
      columns: columns?.call(User.t),
      transaction: transaction,
    );
  }

  /// Updates a single [User] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<User?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<UserUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<User>(
      id,
      columnValues: columnValues(User.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [User]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<User>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<UserUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<UserTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UserTable>? orderBy,
    _is.OrderByListBuilder<UserTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<User>(
      columnValues: columnValues(User.t.updateTable),
      where: where(User.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(User.t),
      orderByList: orderByList?.call(User.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [User]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<User>> delete(
    _is.DatabaseSession session,
    List<User> rows, {
    _is.OrderByBuilder<UserTable>? orderBy,
    _is.OrderByListBuilder<UserTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<User>(
      rows,
      orderBy: orderBy?.call(User.t),
      orderByList: orderByList?.call(User.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [User].
  Future<User> deleteRow(
    _is.DatabaseSession session,
    User row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<User>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<User>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<UserTable> where,
    _is.OrderByBuilder<UserTable>? orderBy,
    _is.OrderByListBuilder<UserTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<User>(
      where: where(User.t),
      orderBy: orderBy?.call(User.t),
      orderByList: orderByList?.call(User.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UserTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<User>(
      where: where?.call(User.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [User] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<UserTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<User>(
      where: where(User.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class UserAttachRepository {
  const UserAttachRepository._();

  /// Creates a relation between this [User] and the given [Order]s
  /// by setting each [Order]'s foreign key `customerId` to refer to this [User].
  Future<void> orders(
    _is.DatabaseSession session,
    User user,
    List<_ij3i88ow.Order> order, {
    _is.Transaction? transaction,
  }) async {
    if (order.any((e) => e.id == null)) {
      throw ArgumentError.notNull('order.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $order = order.map((e) => e.copyWith(customerId: user.id)).toList();
    await session.db.update<_ij3i88ow.Order>(
      $order,
      columns: [_ij3i88ow.Order.t.customerId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [User] and the given [InventoryMovement]s
  /// by setting each [InventoryMovement]'s foreign key `userId` to refer to this [User].
  Future<void> inventoryMovements(
    _is.DatabaseSession session,
    User user,
    List<_i4yp9mtd.InventoryMovement> inventoryMovement, {
    _is.Transaction? transaction,
  }) async {
    if (inventoryMovement.any((e) => e.id == null)) {
      throw ArgumentError.notNull('inventoryMovement.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $inventoryMovement = inventoryMovement
        .map((e) => e.copyWith(userId: user.id))
        .toList();
    await session.db.update<_i4yp9mtd.InventoryMovement>(
      $inventoryMovement,
      columns: [_i4yp9mtd.InventoryMovement.t.userId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [User] and the given [VipCustomer]s
  /// by setting each [VipCustomer]'s foreign key `addedByUserId` to refer to this [User].
  Future<void> vipCustomersAdded(
    _is.DatabaseSession session,
    User user,
    List<_icy1qtyi.VipCustomer> vipCustomer, {
    _is.Transaction? transaction,
  }) async {
    if (vipCustomer.any((e) => e.id == null)) {
      throw ArgumentError.notNull('vipCustomer.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $vipCustomer = vipCustomer
        .map((e) => e.copyWith(addedByUserId: user.id))
        .toList();
    await session.db.update<_icy1qtyi.VipCustomer>(
      $vipCustomer,
      columns: [_icy1qtyi.VipCustomer.t.addedByUserId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [User] and the given [DeviceToken]s
  /// by setting each [DeviceToken]'s foreign key `userId` to refer to this [User].
  Future<void> deviceTokens(
    _is.DatabaseSession session,
    User user,
    List<_iuurxiuf.DeviceToken> deviceToken, {
    _is.Transaction? transaction,
  }) async {
    if (deviceToken.any((e) => e.id == null)) {
      throw ArgumentError.notNull('deviceToken.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $deviceToken = deviceToken
        .map((e) => e.copyWith(userId: user.id))
        .toList();
    await session.db.update<_iuurxiuf.DeviceToken>(
      $deviceToken,
      columns: [_iuurxiuf.DeviceToken.t.userId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [User] and the given [StaffMember]s
  /// by setting each [StaffMember]'s foreign key `addedByUserId` to refer to this [User].
  Future<void> staffMembersAdded(
    _is.DatabaseSession session,
    User user,
    List<_i3fhtrko.StaffMember> staffMember, {
    _is.Transaction? transaction,
  }) async {
    if (staffMember.any((e) => e.id == null)) {
      throw ArgumentError.notNull('staffMember.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $staffMember = staffMember
        .map((e) => e.copyWith(addedByUserId: user.id))
        .toList();
    await session.db.update<_i3fhtrko.StaffMember>(
      $staffMember,
      columns: [_i3fhtrko.StaffMember.t.addedByUserId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [User] and the given [AuditLog]s
  /// by setting each [AuditLog]'s foreign key `actorUserId` to refer to this [User].
  Future<void> auditLogs(
    _is.DatabaseSession session,
    User user,
    List<_iohhzbvb.AuditLog> auditLog, {
    _is.Transaction? transaction,
  }) async {
    if (auditLog.any((e) => e.id == null)) {
      throw ArgumentError.notNull('auditLog.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $auditLog = auditLog
        .map((e) => e.copyWith(actorUserId: user.id))
        .toList();
    await session.db.update<_iohhzbvb.AuditLog>(
      $auditLog,
      columns: [_iohhzbvb.AuditLog.t.actorUserId],
      transaction: transaction,
    );
  }
}

class UserAttachRowRepository {
  const UserAttachRowRepository._();

  /// Creates a relation between this [User] and the given [Order]
  /// by setting the [Order]'s foreign key `customerId` to refer to this [User].
  Future<void> orders(
    _is.DatabaseSession session,
    User user,
    _ij3i88ow.Order order, {
    _is.Transaction? transaction,
  }) async {
    if (order.id == null) {
      throw ArgumentError.notNull('order.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $order = order.copyWith(customerId: user.id);
    await session.db.updateRow<_ij3i88ow.Order>(
      $order,
      columns: [_ij3i88ow.Order.t.customerId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [User] and the given [InventoryMovement]
  /// by setting the [InventoryMovement]'s foreign key `userId` to refer to this [User].
  Future<void> inventoryMovements(
    _is.DatabaseSession session,
    User user,
    _i4yp9mtd.InventoryMovement inventoryMovement, {
    _is.Transaction? transaction,
  }) async {
    if (inventoryMovement.id == null) {
      throw ArgumentError.notNull('inventoryMovement.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $inventoryMovement = inventoryMovement.copyWith(userId: user.id);
    await session.db.updateRow<_i4yp9mtd.InventoryMovement>(
      $inventoryMovement,
      columns: [_i4yp9mtd.InventoryMovement.t.userId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [User] and the given [VipCustomer]
  /// by setting the [VipCustomer]'s foreign key `addedByUserId` to refer to this [User].
  Future<void> vipCustomersAdded(
    _is.DatabaseSession session,
    User user,
    _icy1qtyi.VipCustomer vipCustomer, {
    _is.Transaction? transaction,
  }) async {
    if (vipCustomer.id == null) {
      throw ArgumentError.notNull('vipCustomer.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $vipCustomer = vipCustomer.copyWith(addedByUserId: user.id);
    await session.db.updateRow<_icy1qtyi.VipCustomer>(
      $vipCustomer,
      columns: [_icy1qtyi.VipCustomer.t.addedByUserId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [User] and the given [DeviceToken]
  /// by setting the [DeviceToken]'s foreign key `userId` to refer to this [User].
  Future<void> deviceTokens(
    _is.DatabaseSession session,
    User user,
    _iuurxiuf.DeviceToken deviceToken, {
    _is.Transaction? transaction,
  }) async {
    if (deviceToken.id == null) {
      throw ArgumentError.notNull('deviceToken.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $deviceToken = deviceToken.copyWith(userId: user.id);
    await session.db.updateRow<_iuurxiuf.DeviceToken>(
      $deviceToken,
      columns: [_iuurxiuf.DeviceToken.t.userId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [User] and the given [StaffMember]
  /// by setting the [StaffMember]'s foreign key `addedByUserId` to refer to this [User].
  Future<void> staffMembersAdded(
    _is.DatabaseSession session,
    User user,
    _i3fhtrko.StaffMember staffMember, {
    _is.Transaction? transaction,
  }) async {
    if (staffMember.id == null) {
      throw ArgumentError.notNull('staffMember.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $staffMember = staffMember.copyWith(addedByUserId: user.id);
    await session.db.updateRow<_i3fhtrko.StaffMember>(
      $staffMember,
      columns: [_i3fhtrko.StaffMember.t.addedByUserId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [User] and the given [AuditLog]
  /// by setting the [AuditLog]'s foreign key `actorUserId` to refer to this [User].
  Future<void> auditLogs(
    _is.DatabaseSession session,
    User user,
    _iohhzbvb.AuditLog auditLog, {
    _is.Transaction? transaction,
  }) async {
    if (auditLog.id == null) {
      throw ArgumentError.notNull('auditLog.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $auditLog = auditLog.copyWith(actorUserId: user.id);
    await session.db.updateRow<_iohhzbvb.AuditLog>(
      $auditLog,
      columns: [_iohhzbvb.AuditLog.t.actorUserId],
      transaction: transaction,
    );
  }
}

class UserDetachRepository {
  const UserDetachRepository._();

  /// Detaches the relation between this [User] and the given [StaffMember]
  /// by setting the [StaffMember]'s foreign key `addedByUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> staffMembersAdded(
    _is.DatabaseSession session,
    List<_i3fhtrko.StaffMember> staffMember, {
    _is.Transaction? transaction,
  }) async {
    if (staffMember.any((e) => e.id == null)) {
      throw ArgumentError.notNull('staffMember.id');
    }

    var $staffMember = staffMember
        .map((e) => e.copyWith(addedByUserId: null))
        .toList();
    await session.db.update<_i3fhtrko.StaffMember>(
      $staffMember,
      columns: [_i3fhtrko.StaffMember.t.addedByUserId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [User] and the given [AuditLog]
  /// by setting the [AuditLog]'s foreign key `actorUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> auditLogs(
    _is.DatabaseSession session,
    List<_iohhzbvb.AuditLog> auditLog, {
    _is.Transaction? transaction,
  }) async {
    if (auditLog.any((e) => e.id == null)) {
      throw ArgumentError.notNull('auditLog.id');
    }

    var $auditLog = auditLog.map((e) => e.copyWith(actorUserId: null)).toList();
    await session.db.update<_iohhzbvb.AuditLog>(
      $auditLog,
      columns: [_iohhzbvb.AuditLog.t.actorUserId],
      transaction: transaction,
    );
  }
}

class UserDetachRowRepository {
  const UserDetachRowRepository._();

  /// Detaches the relation between this [User] and the given [StaffMember]
  /// by setting the [StaffMember]'s foreign key `addedByUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> staffMembersAdded(
    _is.DatabaseSession session,
    _i3fhtrko.StaffMember staffMember, {
    _is.Transaction? transaction,
  }) async {
    if (staffMember.id == null) {
      throw ArgumentError.notNull('staffMember.id');
    }

    var $staffMember = staffMember.copyWith(addedByUserId: null);
    await session.db.updateRow<_i3fhtrko.StaffMember>(
      $staffMember,
      columns: [_i3fhtrko.StaffMember.t.addedByUserId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [User] and the given [AuditLog]
  /// by setting the [AuditLog]'s foreign key `actorUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> auditLogs(
    _is.DatabaseSession session,
    _iohhzbvb.AuditLog auditLog, {
    _is.Transaction? transaction,
  }) async {
    if (auditLog.id == null) {
      throw ArgumentError.notNull('auditLog.id');
    }

    var $auditLog = auditLog.copyWith(actorUserId: null);
    await session.db.updateRow<_iohhzbvb.AuditLog>(
      $auditLog,
      columns: [_iohhzbvb.AuditLog.t.actorUserId],
      transaction: transaction,
    );
  }
}
