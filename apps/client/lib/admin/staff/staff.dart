import '../../session/staff_permission.dart';

/// En qué está una persona del equipo.
enum StaffMemberStatus {
  /// Tiene cuenta en la tienda: entra al panel con su rol (si verificó el
  /// correo).
  active,

  /// Está en el equipo, pero todavía no creó su cuenta con ese correo.
  pendingSignUp,

  /// Dada de baja: no tiene permisos, pero queda en el historial.
  deactivated,
}

/// Una persona del equipo: un correo con un rol.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.email,
    required this.active,
    required this.hasAccount,
    required this.createdAt,
    this.roleId,
    this.roleName,
    this.addedByName,
  });

  /// Como lo manda `/staff/members`.
  factory StaffMember.fromJson(Object? json) => switch (json) {
    {
          'id': final String id,
          'email': final String email,
          'active': final bool active,
          'hasAccount': final bool hasAccount,
          'createdAt': final String createdAt,
        } &&
        final Map<Object?, Object?> map =>
      StaffMember(
        id: id,
        email: email,
        active: active,
        hasAccount: hasAccount,
        createdAt: DateTime.parse(createdAt),
        roleId: switch (map['role']) {
          {'id': final String id} => id,
          _ => null,
        },
        roleName: switch (map['role']) {
          {'name': final String name} => name,
          _ => null,
        },
        addedByName: switch (map['addedBy']) {
          {'name': final String name} => name,
          _ => null,
        },
      ),
    _ => throw FormatException('No es una persona del equipo', json),
  };

  final String id;
  final String email;
  final bool active;

  /// Si ese correo ya tiene una cuenta en la tienda.
  final bool hasAccount;

  /// Cuándo se agregó.
  final DateTime createdAt;

  final String? roleId;
  final String? roleName;

  /// Quién lo agregó (null si lo agregó el sistema al arrancar).
  final String? addedByName;

  StaffMemberStatus get status => !active
      ? StaffMemberStatus.deactivated
      : hasAccount
      ? StaffMemberStatus.active
      : StaffMemberStatus.pendingSignUp;
}

/// Un rol del equipo: un nombre con sus permisos.
class StaffRole {
  const StaffRole({
    required this.id,
    required this.name,
    required this.permissions,
    this.isSystem = false,
    this.active = true,
    this.members = 0,
  });

  /// Como lo manda `/staff/roles`. Los permisos que esta versión de la app
  /// no conoce no se muestran.
  factory StaffRole.fromJson(Object? json) => switch (json) {
    {
      'id': final String id,
      'name': final String name,
      'permissions': final List<Object?> permissions,
      'isSystem': final bool isSystem,
      'active': final bool active,
      'members': final int members,
    } =>
      StaffRole(
        id: id,
        name: name,
        permissions: StaffPermission.fromKeys(permissions),
        isSystem: isSystem,
        active: active,
        members: members,
      ),
    _ => throw FormatException('No es un rol', json),
  };

  final String id;
  final String name;
  final Set<StaffPermission> permissions;

  /// El rol del sistema (Administrador): tiene todos los permisos y no se
  /// edita ni se borra.
  final bool isSystem;

  /// Un rol inactivo no da permisos ni se puede asignar.
  final bool active;

  /// Cuántas personas activas lo tienen.
  final int members;
}
