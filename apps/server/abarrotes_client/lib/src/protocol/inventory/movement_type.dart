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

/// incoming: entra stock (p. ej. al cancelar un pedido). outgoing: sale (al
/// crear un pedido). `in` es palabra reservada de Dart y no puede ser un valor.
enum MovementType implements _isc.SerializableModel {
  incoming,
  outgoing,
  adjustment;

  static MovementType fromJson(String name) {
    switch (name) {
      case 'incoming':
        return MovementType.incoming;
      case 'outgoing':
        return MovementType.outgoing;
      case 'adjustment':
        return MovementType.adjustment;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "MovementType"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
