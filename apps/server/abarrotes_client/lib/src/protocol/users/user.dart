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
import 'package:abarrotes_client/src/protocol/protocol.dart' as _iv4mbvnl;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../inventory/inventory_movement.dart' as _i4yp9mtd;
import '../orders/order.dart' as _ij3i88ow;
import '../users/user_role.dart' as _iww5kqrp;

/// Cuenta de la plataforma. La autenticación vive en Firebase: aquí se guarda
/// el uid de Firebase y el rol, nunca una contraseña.
abstract class User
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  User._({
    this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
    this.phone,
    _iww5kqrp.UserRole? role,
    this.address,
    DateTime? createdAt,
    this.orders,
    this.inventoryMovements,
  }) : role = role ?? _iww5kqrp.UserRole.customer,
       createdAt = createdAt ?? DateTime.now();

  factory User({
    _isc.UuidValue? id,
    required String firebaseUid,
    required String email,
    required String name,
    String? phone,
    _iww5kqrp.UserRole? role,
    String? address,
    DateTime? createdAt,
    List<_ij3i88ow.Order>? orders,
    List<_i4yp9mtd.InventoryMovement>? inventoryMovements,
  }) = _UserImpl;

  factory User.fromJson(Map<String, dynamic> jsonSerialization) {
    return User(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      firebaseUid: jsonSerialization['firebaseUid'] as String,
      email: jsonSerialization['email'] as String,
      name: jsonSerialization['name'] as String,
      phone: jsonSerialization['phone'] as String?,
      role: jsonSerialization['role'] == null
          ? null
          : _iww5kqrp.UserRole.fromJson((jsonSerialization['role'] as String)),
      address: jsonSerialization['address'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      orders: jsonSerialization['orders'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<List<_ij3i88ow.Order>>(
              jsonSerialization['orders'],
            ),
      inventoryMovements: jsonSerialization['inventoryMovements'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<List<_i4yp9mtd.InventoryMovement>>(
              jsonSerialization['inventoryMovements'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  /// uid de Firebase Auth (claim `sub` del ID token).
  String firebaseUid;

  String email;

  String name;

  String? phone;

  _iww5kqrp.UserRole role;

  String? address;

  DateTime createdAt;

  List<_ij3i88ow.Order>? orders;

  List<_i4yp9mtd.InventoryMovement>? inventoryMovements;

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  User copyWith({
    _isc.UuidValue? id,
    String? firebaseUid,
    String? email,
    String? name,
    String? phone,
    _iww5kqrp.UserRole? role,
    String? address,
    DateTime? createdAt,
    List<_ij3i88ow.Order>? orders,
    List<_i4yp9mtd.InventoryMovement>? inventoryMovements,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'User',
      if (id != null) 'id': id?.toJson(),
      'firebaseUid': firebaseUid,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
      'role': role.toJson(),
      if (address != null) 'address': address,
      'createdAt': createdAt.toJson(),
      if (orders != null)
        'orders': orders?.toJson(valueToJson: (v) => v.toJson()),
      if (inventoryMovements != null)
        'inventoryMovements': inventoryMovements?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'User',
      if (id != null) 'id': id?.toJson(),
      'firebaseUid': firebaseUid,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
      'role': role.toJson(),
      if (address != null) 'address': address,
      'createdAt': createdAt.toJson(),
      if (orders != null)
        'orders': orders?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (inventoryMovements != null)
        'inventoryMovements': inventoryMovements?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserImpl extends User {
  _UserImpl({
    _isc.UuidValue? id,
    required String firebaseUid,
    required String email,
    required String name,
    String? phone,
    _iww5kqrp.UserRole? role,
    String? address,
    DateTime? createdAt,
    List<_ij3i88ow.Order>? orders,
    List<_i4yp9mtd.InventoryMovement>? inventoryMovements,
  }) : super._(
         id: id,
         firebaseUid: firebaseUid,
         email: email,
         name: name,
         phone: phone,
         role: role,
         address: address,
         createdAt: createdAt,
         orders: orders,
         inventoryMovements: inventoryMovements,
       );

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  User copyWith({
    Object? id = _Undefined,
    String? firebaseUid,
    String? email,
    String? name,
    Object? phone = _Undefined,
    _iww5kqrp.UserRole? role,
    Object? address = _Undefined,
    DateTime? createdAt,
    Object? orders = _Undefined,
    Object? inventoryMovements = _Undefined,
  }) {
    return User(
      id: id is _isc.UuidValue? ? id : this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone is String? ? phone : this.phone,
      role: role ?? this.role,
      address: address is String? ? address : this.address,
      createdAt: createdAt ?? this.createdAt,
      orders: orders is List<_ij3i88ow.Order>?
          ? orders
          : this.orders?.map((e0) => e0.copyWith()).toList(),
      inventoryMovements:
          inventoryMovements is List<_i4yp9mtd.InventoryMovement>?
          ? inventoryMovements
          : this.inventoryMovements?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
