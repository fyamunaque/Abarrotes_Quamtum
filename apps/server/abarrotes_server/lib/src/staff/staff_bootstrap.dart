import 'package:serverpod/serverpod.dart';

import '../common/emails.dart';
import '../generated/protocol.dart' hide AuditLogRepository, RoleRepository;
import 'audit_log_repository.dart';
import 'role_repository.dart';
import 'staff_repository.dart';

/// El nombre del rol de sistema.
const administratorRoleName = 'Administrador';

/// Las plantillas editables con que arranca una tienda nueva (las mismas que
/// siembra la migración 20261011064431487-permisos-personal).
final staffRoleTemplates = <(String, List<Permission>)>[
  (
    'Almacenero',
    [
      Permission.productsView,
      Permission.inventoryView,
      Permission.inventoryAdjust,
      Permission.statsView,
    ],
  ),
  (
    'Cajera',
    [
      Permission.productsView,
      Permission.ordersView,
      Permission.ordersUpdateStatus,
      Permission.customersView,
    ],
  ),
];

/// Lo que el personal necesita para arrancar: los roles iniciales y el primer
/// administrador. Se corre al arrancar el servidor y no repite nada.
class StaffBootstrap {
  const StaffBootstrap({
    this._roles = const DbRoleRepository(),
    this._staff = const DbStaffRepository(),
    this._audit = const DbAuditLogRepository(),
  });

  final RoleRepository _roles;
  final StaffRepository _staff;
  final AuditLogRepository _audit;

  /// El rol de sistema. En una base nueva (sin él) lo crea junto con las
  /// plantillas; si ya existe, no toca nada (las plantillas son del admin).
  Future<Role> ensureRoles(Session session) async {
    final existing = await _roles.findSystem(session);
    if (existing != null) return existing;
    return session.db.transaction((transaction) async {
      final system = await _roles.insert(
        session,
        Role(
          name: administratorRoleName,
          permissions: Permission.values,
          isSystem: true,
        ),
        transaction: transaction,
      );
      for (final (name, permissions) in staffRoleTemplates) {
        if (await _roles.findByName(
              session,
              name,
              transaction: transaction,
            ) ==
            null) {
          await _roles.insert(
            session,
            Role(name: name, permissions: permissions),
            transaction: transaction,
          );
        }
      }
      return system;
    });
  }

  /// Agrega [email] como Administrador si todavía no está en el personal.
  /// Si ya está, aunque esté dado de baja, no lo toca: se respeta lo que
  /// decidió un admin. Devuelve si lo agregó.
  Future<bool> seedFirstAdmin(Session session, String email) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      throw ArgumentError.value(email, 'email', 'no es un correo válido');
    }
    final system = await ensureRoles(session);
    if ((await _staff.findByEmails(session, {normalized})).isNotEmpty) {
      return false;
    }
    await session.db.transaction((transaction) async {
      await _staff.insert(
        session,
        StaffMember(email: normalized, roleId: system.id!),
        transaction: transaction,
      );
      await _audit.record(
        session,
        action: AuditAction.staffSeeded,
        targetEmail: normalized,
        details: {'role': system.name, 'from': 'firstAdminEmail'},
        transaction: transaction,
      );
    });
    return true;
  }
}
