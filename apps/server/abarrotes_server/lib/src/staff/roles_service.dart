import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import '../generated/protocol.dart' hide AuditLogRepository, RoleRepository;
import 'audit_log_repository.dart';
import 'permissions.dart';
import 'role_repository.dart';
import 'staff_repository.dart';

/// Un rol con cuántas personas activas lo tienen.
typedef RoleWithMembers = ({Role role, int members});

/// Los roles del personal: crear, editar y borrar, con sus reglas. Cada
/// cambio queda en la bitácora, en la misma transacción.
class RolesService {
  const RolesService({
    this._roles = const DbRoleRepository(),
    this._staff = const DbStaffRepository(),
    this._audit = const DbAuditLogRepository(),
  });

  final RoleRepository _roles;
  final StaffRepository _staff;
  final AuditLogRepository _audit;

  /// El de sistema primero, después por nombre.
  Future<List<RoleWithMembers>> list(Session session) async {
    final counts = await _staff.activeCountsByRole(session);
    return [
      for (final role in await _roles.list(session))
        (role: role, members: counts[role.id] ?? 0),
    ];
  }

  Future<RoleWithMembers> get(Session session, UuidValue id) async {
    final role = await _find(session, id);
    final members = await _staff.countWithRole(
      session,
      id,
      activeOnly: true,
    );
    return (role: role, members: members);
  }

  /// Reglas: el nombre no se repite (sin distinguir mayúsculas) y tiene al
  /// menos un permiso (lo valida la ruta).
  Future<Role> create(
    Session session, {
    required String name,
    required Set<Permission> permissions,
    required User actor,
  }) async {
    await _assertNameFree(session, name);
    return _write(
      session,
      name,
      () => session.db.transaction((transaction) async {
        final role = await _roles.insert(
          session,
          Role(name: name, permissions: _ordered(permissions)),
          transaction: transaction,
        );
        await _audit.record(
          session,
          action: AuditAction.roleCreated,
          actorUserId: actor.id,
          details: {'role': name, 'permissions': permissionKeys(permissions)},
          transaction: transaction,
        );
        return role;
      }),
    );
  }

  /// Los campos en null no cambian. Un rol de sistema no se edita.
  Future<Role> update(
    Session session,
    UuidValue id, {
    String? name,
    Set<Permission>? permissions,
    bool? active,
    required User actor,
  }) async {
    final current = await _find(session, id);
    _assertNotSystem(current);
    if (name != null && name.toLowerCase() != current.name.toLowerCase()) {
      await _assertNameFree(session, name);
    }
    final updated = current.copyWith(
      name: name,
      permissions: permissions == null ? null : _ordered(permissions),
      active: active,
    );
    final changes = {
      if (updated.name != current.name)
        'name': {'from': current.name, 'to': updated.name},
      if (permissions != null &&
          !_samePermissions(current.permissions, updated.permissions))
        'permissions': {
          'from': permissionKeys(current.permissions),
          'to': permissionKeys(updated.permissions),
        },
      if (updated.active != current.active)
        'active': {'from': current.active, 'to': updated.active},
    };
    if (changes.isEmpty) return current;

    return _write(
      session,
      updated.name,
      () => session.db.transaction((transaction) async {
        final saved = await _roles.update(
          session,
          updated,
          transaction: transaction,
        );
        await _audit.record(
          session,
          action: AuditAction.roleUpdated,
          actorUserId: actor.id,
          details: {'role': current.name, ...changes},
          transaction: transaction,
        );
        return saved;
      }),
    );
  }

  /// No se borra el de sistema ni uno con personal asignado (también dado de
  /// baja: la fila lo sigue nombrando).
  Future<void> delete(
    Session session,
    UuidValue id, {
    required User actor,
  }) async {
    final role = await _find(session, id);
    _assertNotSystem(role);
    final members = await _staff.countWithRole(session, id);
    if (members > 0) {
      throw ApiException.conflict(
        'El rol ${role.name} tiene $members '
        '${members == 1 ? 'persona asignada' : 'personas asignadas'} '
        '(también cuentan las dadas de baja): cámbiales el rol antes',
      );
    }
    try {
      await session.db.transaction((transaction) async {
        await _roles.delete(session, role, transaction: transaction);
        await _audit.record(
          session,
          action: AuditAction.roleDeleted,
          actorUserId: actor.id,
          details: {'role': role.name},
          transaction: transaction,
        );
      });
    } on DatabaseForeignKeyViolationException {
      // Alguien le asignó el rol a una persona mientras tanto.
      throw ApiException.conflict(
        'El rol ${role.name} tiene personal asignado: cámbiales el rol antes',
      );
    }
  }

  Future<Role> _find(Session session, UuidValue id) async =>
      await _roles.findById(session, id) ??
      (throw const ApiException(404, 'Rol no encontrado'));

  void _assertNotSystem(Role role) {
    if (role.isSystem) {
      throw ApiException.conflict(
        'El rol ${role.name} es del sistema: no se edita ni se borra',
      );
    }
  }

  Future<void> _assertNameFree(Session session, String name) async {
    if (await _roles.findByName(session, name) != null) {
      throw _nameTaken(name);
    }
  }

  /// Escribe, traduciendo la carrera de dos roles con el mismo nombre.
  Future<Role> _write(
    Session session,
    String name,
    Future<Role> Function() write,
  ) async {
    try {
      return await write();
    } on DatabaseUniqueViolationException {
      throw _nameTaken(name);
    }
  }

  static ApiException _nameTaken(String name) =>
      ApiException.conflict('Ya existe un rol llamado $name');

  /// En el orden del catálogo, sin repetir.
  static List<Permission> _ordered(Set<Permission> permissions) => [
    for (final permission in Permission.values)
      if (permissions.contains(permission)) permission,
  ];

  static bool _samePermissions(List<Permission> a, List<Permission> b) =>
      a.toSet().length == b.toSet().length && a.toSet().containsAll(b);
}
