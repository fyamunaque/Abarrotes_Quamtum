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
import '../users/user.dart' as _iqzoui01;

/// Un cliente VIP: un correo (en minúsculas y sin espacios) que accede a las
/// promociones con audiencia `vip`, si además verificó ese correo en Firebase.
/// Se da de baja con `active`, sin borrar la fila: queda el historial.
abstract class VipCustomer
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  VipCustomer._({
    this.id,
    required this.email,
    bool? active,
    DateTime? createdAt,
    required this.addedByUserId,
    this.addedBy,
  }) : active = active ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory VipCustomer({
    _isc.UuidValue? id,
    required String email,
    bool? active,
    DateTime? createdAt,
    required _isc.UuidValue addedByUserId,
    _iqzoui01.User? addedBy,
  }) = _VipCustomerImpl;

  factory VipCustomer.fromJson(Map<String, dynamic> jsonSerialization) {
    return VipCustomer(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      email: jsonSerialization['email'] as String,
      active: jsonSerialization['active'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['active']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      addedByUserId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['addedByUserId'],
      ),
      addedBy: jsonSerialization['addedBy'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['addedBy'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  String email;

  bool active;

  DateTime createdAt;

  /// Quién lo agregó (un admin).
  _isc.UuidValue addedByUserId;

  _iqzoui01.User? addedBy;

  /// Returns a shallow copy of this [VipCustomer]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  VipCustomer copyWith({
    _isc.UuidValue? id,
    String? email,
    bool? active,
    DateTime? createdAt,
    _isc.UuidValue? addedByUserId,
    _iqzoui01.User? addedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VipCustomer',
      if (id != null) 'id': id?.toJson(),
      'email': email,
      'active': active,
      'createdAt': createdAt.toJson(),
      'addedByUserId': addedByUserId.toJson(),
      if (addedBy != null) 'addedBy': addedBy?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VipCustomer',
      if (id != null) 'id': id?.toJson(),
      'email': email,
      'active': active,
      'createdAt': createdAt.toJson(),
      'addedByUserId': addedByUserId.toJson(),
      if (addedBy != null) 'addedBy': addedBy?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VipCustomerImpl extends VipCustomer {
  _VipCustomerImpl({
    _isc.UuidValue? id,
    required String email,
    bool? active,
    DateTime? createdAt,
    required _isc.UuidValue addedByUserId,
    _iqzoui01.User? addedBy,
  }) : super._(
         id: id,
         email: email,
         active: active,
         createdAt: createdAt,
         addedByUserId: addedByUserId,
         addedBy: addedBy,
       );

  /// Returns a shallow copy of this [VipCustomer]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  VipCustomer copyWith({
    Object? id = _Undefined,
    String? email,
    bool? active,
    DateTime? createdAt,
    _isc.UuidValue? addedByUserId,
    Object? addedBy = _Undefined,
  }) {
    return VipCustomer(
      id: id is _isc.UuidValue? ? id : this.id,
      email: email ?? this.email,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      addedBy: addedBy is _iqzoui01.User? ? addedBy : this.addedBy?.copyWith(),
    );
  }
}
