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
import '../staff/role.dart' as _i9j0u4yz;
import '../users/user.dart' as _iqzoui01;

/// Una persona del personal: su correo (en minúsculas y sin espacios) y su
/// rol. Sus permisos rigen si ingresa con ese correo verificado. Se da de
/// baja con active, sin borrar la fila.
abstract class StaffMember
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  StaffMember._({
    this.id,
    required this.email,
    required this.roleId,
    this.role,
    this.addedByUserId,
    this.addedBy,
    DateTime? createdAt,
    bool? active,
  }) : createdAt = createdAt ?? DateTime.now(),
       active = active ?? true;

  factory StaffMember({
    _isc.UuidValue? id,
    required String email,
    required _isc.UuidValue roleId,
    _i9j0u4yz.Role? role,
    _isc.UuidValue? addedByUserId,
    _iqzoui01.User? addedBy,
    DateTime? createdAt,
    bool? active,
  }) = _StaffMemberImpl;

  factory StaffMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return StaffMember(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      email: jsonSerialization['email'] as String,
      roleId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['roleId']),
      role: jsonSerialization['role'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_i9j0u4yz.Role>(
              jsonSerialization['role'],
            ),
      addedByUserId: jsonSerialization['addedByUserId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['addedByUserId'],
            ),
      addedBy: jsonSerialization['addedBy'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['addedBy'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      active: jsonSerialization['active'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['active']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  String email;

  _isc.UuidValue roleId;

  _i9j0u4yz.Role? role;

  /// Quién lo agregó; null si lo agregó el sistema (siembra o migración).
  _isc.UuidValue? addedByUserId;

  _iqzoui01.User? addedBy;

  DateTime createdAt;

  bool active;

  /// Returns a shallow copy of this [StaffMember]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  StaffMember copyWith({
    _isc.UuidValue? id,
    String? email,
    _isc.UuidValue? roleId,
    _i9j0u4yz.Role? role,
    _isc.UuidValue? addedByUserId,
    _iqzoui01.User? addedBy,
    DateTime? createdAt,
    bool? active,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StaffMember',
      if (id != null) 'id': id?.toJson(),
      'email': email,
      'roleId': roleId.toJson(),
      if (role != null) 'role': role?.toJson(),
      if (addedByUserId != null) 'addedByUserId': addedByUserId?.toJson(),
      if (addedBy != null) 'addedBy': addedBy?.toJson(),
      'createdAt': createdAt.toJson(),
      'active': active,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StaffMember',
      if (id != null) 'id': id?.toJson(),
      'email': email,
      'roleId': roleId.toJson(),
      if (role != null) 'role': role?.toJsonForProtocol(),
      if (addedByUserId != null) 'addedByUserId': addedByUserId?.toJson(),
      if (addedBy != null) 'addedBy': addedBy?.toJsonForProtocol(),
      'createdAt': createdAt.toJson(),
      'active': active,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StaffMemberImpl extends StaffMember {
  _StaffMemberImpl({
    _isc.UuidValue? id,
    required String email,
    required _isc.UuidValue roleId,
    _i9j0u4yz.Role? role,
    _isc.UuidValue? addedByUserId,
    _iqzoui01.User? addedBy,
    DateTime? createdAt,
    bool? active,
  }) : super._(
         id: id,
         email: email,
         roleId: roleId,
         role: role,
         addedByUserId: addedByUserId,
         addedBy: addedBy,
         createdAt: createdAt,
         active: active,
       );

  /// Returns a shallow copy of this [StaffMember]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  StaffMember copyWith({
    Object? id = _Undefined,
    String? email,
    _isc.UuidValue? roleId,
    Object? role = _Undefined,
    Object? addedByUserId = _Undefined,
    Object? addedBy = _Undefined,
    DateTime? createdAt,
    bool? active,
  }) {
    return StaffMember(
      id: id is _isc.UuidValue? ? id : this.id,
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
      role: role is _i9j0u4yz.Role? ? role : this.role?.copyWith(),
      addedByUserId: addedByUserId is _isc.UuidValue?
          ? addedByUserId
          : this.addedByUserId,
      addedBy: addedBy is _iqzoui01.User? ? addedBy : this.addedBy?.copyWith(),
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
    );
  }
}
