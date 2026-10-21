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

/// Los datos de la tienda que ve el cliente (p. ej. al elegir recojo). Hay
/// un solo registro: singleton es siempre true y su índice único no deja
/// crear otro.
abstract class StoreSettings
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  StoreSettings._({
    this.id,
    bool? singleton,
    required this.name,
    required this.address,
    this.reference,
    this.phone,
    this.openingHours,
    this.pickupInstructions,
    DateTime? updatedAt,
    this.updatedByUserId,
    this.updatedBy,
  }) : singleton = singleton ?? true,
       updatedAt = updatedAt ?? DateTime.now();

  factory StoreSettings({
    _isc.UuidValue? id,
    bool? singleton,
    required String name,
    required String address,
    String? reference,
    String? phone,
    String? openingHours,
    String? pickupInstructions,
    DateTime? updatedAt,
    _isc.UuidValue? updatedByUserId,
    _iqzoui01.User? updatedBy,
  }) = _StoreSettingsImpl;

  factory StoreSettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return StoreSettings(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      singleton: jsonSerialization['singleton'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['singleton']),
      name: jsonSerialization['name'] as String,
      address: jsonSerialization['address'] as String,
      reference: jsonSerialization['reference'] as String?,
      phone: jsonSerialization['phone'] as String?,
      openingHours: jsonSerialization['openingHours'] as String?,
      pickupInstructions: jsonSerialization['pickupInstructions'] as String?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      updatedByUserId: jsonSerialization['updatedByUserId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['updatedByUserId'],
            ),
      updatedBy: jsonSerialization['updatedBy'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['updatedBy'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  bool singleton;

  String name;

  String address;

  /// Cómo llegar ("frente al parque Kennedy").
  String? reference;

  String? phone;

  /// Horario de atención, en texto ("Lun a sáb de 8 a 20 h").
  String? openingHours;

  /// Qué hacer al llegar a recoger un pedido.
  String? pickupInstructions;

  DateTime updatedAt;

  /// Quién lo editó por última vez.
  _isc.UuidValue? updatedByUserId;

  _iqzoui01.User? updatedBy;

  /// Returns a shallow copy of this [StoreSettings]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  StoreSettings copyWith({
    _isc.UuidValue? id,
    bool? singleton,
    String? name,
    String? address,
    String? reference,
    String? phone,
    String? openingHours,
    String? pickupInstructions,
    DateTime? updatedAt,
    _isc.UuidValue? updatedByUserId,
    _iqzoui01.User? updatedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StoreSettings',
      if (id != null) 'id': id?.toJson(),
      'singleton': singleton,
      'name': name,
      'address': address,
      if (reference != null) 'reference': reference,
      if (phone != null) 'phone': phone,
      if (openingHours != null) 'openingHours': openingHours,
      if (pickupInstructions != null) 'pickupInstructions': pickupInstructions,
      'updatedAt': updatedAt.toJson(),
      if (updatedByUserId != null) 'updatedByUserId': updatedByUserId?.toJson(),
      if (updatedBy != null) 'updatedBy': updatedBy?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StoreSettings',
      if (id != null) 'id': id?.toJson(),
      'singleton': singleton,
      'name': name,
      'address': address,
      if (reference != null) 'reference': reference,
      if (phone != null) 'phone': phone,
      if (openingHours != null) 'openingHours': openingHours,
      if (pickupInstructions != null) 'pickupInstructions': pickupInstructions,
      'updatedAt': updatedAt.toJson(),
      if (updatedByUserId != null) 'updatedByUserId': updatedByUserId?.toJson(),
      if (updatedBy != null) 'updatedBy': updatedBy?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StoreSettingsImpl extends StoreSettings {
  _StoreSettingsImpl({
    _isc.UuidValue? id,
    bool? singleton,
    required String name,
    required String address,
    String? reference,
    String? phone,
    String? openingHours,
    String? pickupInstructions,
    DateTime? updatedAt,
    _isc.UuidValue? updatedByUserId,
    _iqzoui01.User? updatedBy,
  }) : super._(
         id: id,
         singleton: singleton,
         name: name,
         address: address,
         reference: reference,
         phone: phone,
         openingHours: openingHours,
         pickupInstructions: pickupInstructions,
         updatedAt: updatedAt,
         updatedByUserId: updatedByUserId,
         updatedBy: updatedBy,
       );

  /// Returns a shallow copy of this [StoreSettings]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  StoreSettings copyWith({
    Object? id = _Undefined,
    bool? singleton,
    String? name,
    String? address,
    Object? reference = _Undefined,
    Object? phone = _Undefined,
    Object? openingHours = _Undefined,
    Object? pickupInstructions = _Undefined,
    DateTime? updatedAt,
    Object? updatedByUserId = _Undefined,
    Object? updatedBy = _Undefined,
  }) {
    return StoreSettings(
      id: id is _isc.UuidValue? ? id : this.id,
      singleton: singleton ?? this.singleton,
      name: name ?? this.name,
      address: address ?? this.address,
      reference: reference is String? ? reference : this.reference,
      phone: phone is String? ? phone : this.phone,
      openingHours: openingHours is String? ? openingHours : this.openingHours,
      pickupInstructions: pickupInstructions is String?
          ? pickupInstructions
          : this.pickupInstructions,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByUserId: updatedByUserId is _isc.UuidValue?
          ? updatedByUserId
          : this.updatedByUserId,
      updatedBy: updatedBy is _iqzoui01.User?
          ? updatedBy
          : this.updatedBy?.copyWith(),
    );
  }
}
