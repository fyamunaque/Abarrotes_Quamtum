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
import '../staff/audit_action.dart' as _id696o20;
import '../users/user.dart' as _iqzoui01;

/// La bitácora de los cambios del personal: quién hizo qué, a quién y cuándo.
abstract class AuditLog
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AuditLog._({
    this.id,
    this.actorUserId,
    this.actor,
    required this.action,
    this.targetEmail,
    this.details,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AuditLog({
    _isc.UuidValue? id,
    _isc.UuidValue? actorUserId,
    _iqzoui01.User? actor,
    required _id696o20.AuditAction action,
    String? targetEmail,
    String? details,
    DateTime? createdAt,
  }) = _AuditLogImpl;

  factory AuditLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuditLog(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      actorUserId: jsonSerialization['actorUserId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['actorUserId'],
            ),
      actor: jsonSerialization['actor'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['actor'],
            ),
      action: _id696o20.AuditAction.fromJson(
        (jsonSerialization['action'] as String),
      ),
      targetEmail: jsonSerialization['targetEmail'] as String?,
      details: jsonSerialization['details'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  /// Quién lo hizo; null si fue el sistema.
  _isc.UuidValue? actorUserId;

  _iqzoui01.User? actor;

  _id696o20.AuditAction action;

  /// El correo de la persona afectada (null en los cambios de un rol).
  String? targetEmail;

  /// Lo que cambió, como JSON (p. ej. {"from":"Almacenero","to":"Cajera"}).
  String? details;

  DateTime createdAt;

  /// Returns a shallow copy of this [AuditLog]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AuditLog copyWith({
    _isc.UuidValue? id,
    _isc.UuidValue? actorUserId,
    _iqzoui01.User? actor,
    _id696o20.AuditAction? action,
    String? targetEmail,
    String? details,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuditLog',
      if (id != null) 'id': id?.toJson(),
      if (actorUserId != null) 'actorUserId': actorUserId?.toJson(),
      if (actor != null) 'actor': actor?.toJson(),
      'action': action.toJson(),
      if (targetEmail != null) 'targetEmail': targetEmail,
      if (details != null) 'details': details,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuditLog',
      if (id != null) 'id': id?.toJson(),
      if (actorUserId != null) 'actorUserId': actorUserId?.toJson(),
      if (actor != null) 'actor': actor?.toJsonForProtocol(),
      'action': action.toJson(),
      if (targetEmail != null) 'targetEmail': targetEmail,
      if (details != null) 'details': details,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuditLogImpl extends AuditLog {
  _AuditLogImpl({
    _isc.UuidValue? id,
    _isc.UuidValue? actorUserId,
    _iqzoui01.User? actor,
    required _id696o20.AuditAction action,
    String? targetEmail,
    String? details,
    DateTime? createdAt,
  }) : super._(
         id: id,
         actorUserId: actorUserId,
         actor: actor,
         action: action,
         targetEmail: targetEmail,
         details: details,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AuditLog]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AuditLog copyWith({
    Object? id = _Undefined,
    Object? actorUserId = _Undefined,
    Object? actor = _Undefined,
    _id696o20.AuditAction? action,
    Object? targetEmail = _Undefined,
    Object? details = _Undefined,
    DateTime? createdAt,
  }) {
    return AuditLog(
      id: id is _isc.UuidValue? ? id : this.id,
      actorUserId: actorUserId is _isc.UuidValue?
          ? actorUserId
          : this.actorUserId,
      actor: actor is _iqzoui01.User? ? actor : this.actor?.copyWith(),
      action: action ?? this.action,
      targetEmail: targetEmail is String? ? targetEmail : this.targetEmail,
      details: details is String? ? details : this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
