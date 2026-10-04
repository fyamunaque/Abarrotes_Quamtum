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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Insumo de la tienda (bolsas, envases...): no se vende en el catálogo.
abstract class Supply
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Supply._({
    this.id,
    required this.name,
    required this.unit,
    int? quantity,
    int? minQuantity,
    DateTime? createdAt,
  }) : quantity = quantity ?? 0,
       minQuantity = minQuantity ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory Supply({
    _isc.UuidValue? id,
    required String name,
    required String unit,
    int? quantity,
    int? minQuantity,
    DateTime? createdAt,
  }) = _SupplyImpl;

  factory Supply.fromJson(Map<String, dynamic> jsonSerialization) {
    return Supply(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      unit: jsonSerialization['unit'] as String,
      quantity: jsonSerialization['quantity'] as int?,
      minQuantity: jsonSerialization['minQuantity'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  String name;

  String unit;

  int quantity;

  int minQuantity;

  DateTime createdAt;

  /// Returns a shallow copy of this [Supply]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Supply copyWith({
    _isc.UuidValue? id,
    String? name,
    String? unit,
    int? quantity,
    int? minQuantity,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Supply',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Supply',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SupplyImpl extends Supply {
  _SupplyImpl({
    _isc.UuidValue? id,
    required String name,
    required String unit,
    int? quantity,
    int? minQuantity,
    DateTime? createdAt,
  }) : super._(
         id: id,
         name: name,
         unit: unit,
         quantity: quantity,
         minQuantity: minQuantity,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Supply]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Supply copyWith({
    Object? id = _Undefined,
    String? name,
    String? unit,
    int? quantity,
    int? minQuantity,
    DateTime? createdAt,
  }) {
    return Supply(
      id: id is _isc.UuidValue? ? id : this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
