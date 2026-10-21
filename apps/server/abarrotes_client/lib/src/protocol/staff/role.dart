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
import '../staff/permission.dart' as _ikdgfgc9;
import '../staff/staff_member.dart' as _i3fhtrko;

/// Un rol del personal: un nombre y sus permisos. El de sistema
/// (Administrador) tiene siempre todos y no se edita ni se borra; los demás
/// los arma un admin (p. ej. las plantillas Almacenero y Cajera).
abstract class Role
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Role._({
    this.id,
    required this.name,
    required this.permissions,
    bool? isSystem,
    bool? active,
    DateTime? createdAt,
    this.members,
  }) : isSystem = isSystem ?? false,
       active = active ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory Role({
    _isc.UuidValue? id,
    required String name,
    required List<_ikdgfgc9.Permission> permissions,
    bool? isSystem,
    bool? active,
    DateTime? createdAt,
    List<_i3fhtrko.StaffMember>? members,
  }) = _RoleImpl;

  factory Role.fromJson(Map<String, dynamic> jsonSerialization) {
    return Role(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      permissions: _iv4mbvnl.Protocol().deserialize<List<_ikdgfgc9.Permission>>(
        jsonSerialization['permissions'],
      ),
      isSystem: jsonSerialization['isSystem'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['isSystem']),
      active: jsonSerialization['active'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['active']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      members: jsonSerialization['members'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<List<_i3fhtrko.StaffMember>>(
              jsonSerialization['members'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  String name;

  List<_ikdgfgc9.Permission> permissions;

  bool isSystem;

  /// Un rol inactivo no da permisos ni se puede asignar.
  bool active;

  DateTime createdAt;

  List<_i3fhtrko.StaffMember>? members;

  /// Returns a shallow copy of this [Role]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Role copyWith({
    _isc.UuidValue? id,
    String? name,
    List<_ikdgfgc9.Permission>? permissions,
    bool? isSystem,
    bool? active,
    DateTime? createdAt,
    List<_i3fhtrko.StaffMember>? members,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Role',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      'permissions': permissions.toJson(valueToJson: (v) => v.toJson()),
      'isSystem': isSystem,
      'active': active,
      'createdAt': createdAt.toJson(),
      if (members != null)
        'members': members?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Role',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      'permissions': permissions.toJson(valueToJson: (v) => v.toJson()),
      'isSystem': isSystem,
      'active': active,
      'createdAt': createdAt.toJson(),
      if (members != null)
        'members': members?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoleImpl extends Role {
  _RoleImpl({
    _isc.UuidValue? id,
    required String name,
    required List<_ikdgfgc9.Permission> permissions,
    bool? isSystem,
    bool? active,
    DateTime? createdAt,
    List<_i3fhtrko.StaffMember>? members,
  }) : super._(
         id: id,
         name: name,
         permissions: permissions,
         isSystem: isSystem,
         active: active,
         createdAt: createdAt,
         members: members,
       );

  /// Returns a shallow copy of this [Role]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Role copyWith({
    Object? id = _Undefined,
    String? name,
    List<_ikdgfgc9.Permission>? permissions,
    bool? isSystem,
    bool? active,
    DateTime? createdAt,
    Object? members = _Undefined,
  }) {
    return Role(
      id: id is _isc.UuidValue? ? id : this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions.map((e0) => e0).toList(),
      isSystem: isSystem ?? this.isSystem,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      members: members is List<_i3fhtrko.StaffMember>?
          ? members
          : this.members?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
