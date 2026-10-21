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

/// Qué cambió en la bitácora del personal (AuditLog).
enum AuditAction implements _isc.SerializableModel {
  roleCreated,
  roleUpdated,
  roleDeleted,
  staffAdded,
  staffReactivated,
  staffRoleChanged,
  staffDeactivated,
  staffSeeded;

  static AuditAction fromJson(String name) {
    switch (name) {
      case 'roleCreated':
        return AuditAction.roleCreated;
      case 'roleUpdated':
        return AuditAction.roleUpdated;
      case 'roleDeleted':
        return AuditAction.roleDeleted;
      case 'staffAdded':
        return AuditAction.staffAdded;
      case 'staffReactivated':
        return AuditAction.staffReactivated;
      case 'staffRoleChanged':
        return AuditAction.staffRoleChanged;
      case 'staffDeactivated':
        return AuditAction.staffDeactivated;
      case 'staffSeeded':
        return AuditAction.staffSeeded;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "AuditAction"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
