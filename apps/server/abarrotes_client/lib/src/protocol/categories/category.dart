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
import '../products/product.dart' as _iubf72bi;

abstract class Category
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Category._({
    this.id,
    required this.name,
    this.products,
  });

  factory Category({
    _isc.UuidValue? id,
    required String name,
    List<_iubf72bi.Product>? products,
  }) = _CategoryImpl;

  factory Category.fromJson(Map<String, dynamic> jsonSerialization) {
    return Category(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      products: jsonSerialization['products'] == null
          ? null
          : _iv4mbvnl.Protocol().deserialize<List<_iubf72bi.Product>>(
              jsonSerialization['products'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  String name;

  List<_iubf72bi.Product>? products;

  /// Returns a shallow copy of this [Category]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Category copyWith({
    _isc.UuidValue? id,
    String? name,
    List<_iubf72bi.Product>? products,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Category',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      if (products != null)
        'products': products?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Category',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      if (products != null)
        'products': products?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CategoryImpl extends Category {
  _CategoryImpl({
    _isc.UuidValue? id,
    required String name,
    List<_iubf72bi.Product>? products,
  }) : super._(
         id: id,
         name: name,
         products: products,
       );

  /// Returns a shallow copy of this [Category]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Category copyWith({
    Object? id = _Undefined,
    String? name,
    Object? products = _Undefined,
  }) {
    return Category(
      id: id is _isc.UuidValue? ? id : this.id,
      name: name ?? this.name,
      products: products is List<_iubf72bi.Product>?
          ? products
          : this.products?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
