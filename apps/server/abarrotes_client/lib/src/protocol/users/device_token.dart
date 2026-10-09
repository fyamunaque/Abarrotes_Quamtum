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

/// Un dispositivo (un teléfono o un navegador) donde la cuenta recibe avisos
/// push: su token de registro de FCM. Una cuenta puede tener varios.
abstract class DeviceToken
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DeviceToken._({
    this.id,
    required this.token,
    this.platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.userId,
    this.user,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory DeviceToken({
    _isc.UuidValue? id,
    required String token,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    required _isc.UuidValue userId,
    _iqzoui01.User? user,
  }) = _DeviceTokenImpl;

  factory DeviceToken.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceToken(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      token: jsonSerialization['token'] as String,
      platform: jsonSerialization['platform'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      user: jsonSerialization['user'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['user'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  /// El token de registro de FCM, que da la app (firebase_messaging).
  String token;

  /// android o web; solo informativo.
  String? platform;

  DateTime createdAt;

  /// La última vez que la app lo registró.
  DateTime updatedAt;

  _isc.UuidValue userId;

  _iqzoui01.User? user;

  /// Returns a shallow copy of this [DeviceToken]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DeviceToken copyWith({
    _isc.UuidValue? id,
    String? token,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    _isc.UuidValue? userId,
    _iqzoui01.User? user,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceToken',
      if (id != null) 'id': id?.toJson(),
      'token': token,
      if (platform != null) 'platform': platform,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'userId': userId.toJson(),
      if (user != null) 'user': user?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeviceToken',
      if (id != null) 'id': id?.toJson(),
      'token': token,
      if (platform != null) 'platform': platform,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'userId': userId.toJson(),
      if (user != null) 'user': user?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceTokenImpl extends DeviceToken {
  _DeviceTokenImpl({
    _isc.UuidValue? id,
    required String token,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    required _isc.UuidValue userId,
    _iqzoui01.User? user,
  }) : super._(
         id: id,
         token: token,
         platform: platform,
         createdAt: createdAt,
         updatedAt: updatedAt,
         userId: userId,
         user: user,
       );

  /// Returns a shallow copy of this [DeviceToken]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DeviceToken copyWith({
    Object? id = _Undefined,
    String? token,
    Object? platform = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    _isc.UuidValue? userId,
    Object? user = _Undefined,
  }) {
    return DeviceToken(
      id: id is _isc.UuidValue? ? id : this.id,
      token: token ?? this.token,
      platform: platform is String? ? platform : this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      user: user is _iqzoui01.User? ? user : this.user?.copyWith(),
    );
  }
}
