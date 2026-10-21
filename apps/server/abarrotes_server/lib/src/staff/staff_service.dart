import 'package:serverpod/serverpod.dart';

import '../common/emails.dart';
import '../common/http_json.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart' hide AuditLogRepository, RoleRepository;
import 'audit_log_repository.dart';
import 'role_repository.dart';
import 'staff_repository.dart';

/// Una persona del personal como la muestra el panel: con si su correo ya
/// tiene cuenta.
typedef StaffListItem = ({StaffMember member, bool hasAccount});

/// Quien hace un cambio: su cuenta y el correo con que entró (para no dejar
/// que se quite el rol a sí mismo).
typedef StaffActor = ({User user, String email});

/// El personal: agregar por correo, cambiar de rol y dar de baja, con sus
/// reglas. Cada cambio queda en la bitácora, en la misma transacción.
///
/// La regla del último Administrador se controla con las filas de los
/// Administradores activos bloqueadas: dos bajas a la vez no dejan la tienda
/// sin ninguno.
class StaffService {
  const StaffService({
    this._roles = const DbRoleRepository(),
    this._staff = const DbStaffRepository(),
    this._audit = const DbAuditLogRepository(),
  });

  final RoleRepository _roles;
  final StaffRepository _staff;
  final AuditLogRepository _audit;

  /// Cuántos correos se aceptan por alta.
  static const maxPerRequest = 500;

  Future<(List<StaffListItem>, int)> list(
    Session session,
    PageQuery page, {
    String? search,
    bool includeInactive = false,
  }) async {
    final (members, total) = await _staff.list(
      session,
      page,
      search: search == null ? null : normalizeEmail(search),
      includeInactive: includeInactive,
    );
    return (await _withAccounts(session, members), total);
  }

  /// Agrega [emails] con el rol [roleId]. Los inválidos y los duplicados
  /// (repetidos o ya activos, con cualquier rol) se informan sin cortar el
  /// resto. Un correo dado de baja vuelve con ese rol y cuenta como agregado.
  Future<EmailAddSummary> add(
    Session session,
    List<String> emails, {
    required UuidValue roleId,
    required StaffActor actor,
  }) async {
    final role = await _assignableRole(session, roleId);
    final added = <String>[];
    final (:candidates, :duplicates, :invalid) = sortEmails(emails);
    if (candidates.isEmpty) {
      return (added: added, duplicates: duplicates, invalid: invalid);
    }

    try {
      await session.db.transaction((transaction) async {
        final existing = {
          for (final member in await _staff.findByEmails(
            session,
            candidates.toSet(),
            transaction: transaction,
          ))
            member.email: member,
        };
        for (final email in candidates) {
          final current = existing[email];
          if (current != null && current.active) {
            duplicates.add(email);
            continue;
          }
          if (current == null) {
            await _staff.insert(
              session,
              StaffMember(
                email: email,
                roleId: role.id!,
                addedByUserId: actor.user.id,
              ),
              transaction: transaction,
            );
          } else {
            await _staff.update(
              session,
              current.copyWith(
                roleId: role.id,
                active: true,
                addedByUserId: actor.user.id,
              ),
              transaction: transaction,
            );
          }
          await _audit.record(
            session,
            action: current == null
                ? AuditAction.staffAdded
                : AuditAction.staffReactivated,
            actorUserId: actor.user.id,
            targetEmail: email,
            details: {'role': role.name},
            transaction: transaction,
          );
          added.add(email);
        }
      });
    } on DatabaseUniqueViolationException {
      throw const ApiException.conflict(
        'Otra persona agregó alguno de estos correos al mismo tiempo: '
        'vuelve a intentarlo',
      );
    }
    return (added: added, duplicates: duplicates, invalid: invalid);
  }

  /// Le pone el rol [roleId]. No se puede cambiar el propio rol, ni quitarle
  /// el rol de Administrador al último activo.
  Future<StaffListItem> changeRole(
    Session session,
    UuidValue id, {
    required UuidValue roleId,
    required StaffActor actor,
  }) async {
    final member = await _find(session, id);
    if (member.email == actor.email) {
      throw const ApiException.conflict('No puedes cambiar tu propio rol');
    }
    final role = await _assignableRole(session, roleId);
    if (member.roleId == role.id) return _item(session, member);

    final previous = member.role!;
    await session.db.transaction((transaction) async {
      if (member.active) {
        await _assertNotLastAdmin(session, member, transaction: transaction);
      }
      await _staff.update(
        session,
        member.copyWith(roleId: role.id),
        transaction: transaction,
      );
      await _audit.record(
        session,
        action: AuditAction.staffRoleChanged,
        actorUserId: actor.user.id,
        targetEmail: member.email,
        details: {'from': previous.name, 'to': role.name},
        transaction: transaction,
      );
    });
    return _item(session, await _find(session, id));
  }

  /// La da de baja: pierde sus permisos en la petición siguiente, pero la
  /// fila queda. No se puede dar de baja a sí mismo ni al último
  /// Administrador activo. Darla de baja dos veces no es error.
  Future<StaffListItem> deactivate(
    Session session,
    UuidValue id, {
    required StaffActor actor,
  }) async {
    final member = await _find(session, id);
    if (member.email == actor.email) {
      throw const ApiException.conflict('No puedes darte de baja a ti mismo');
    }
    if (!member.active) return _item(session, member);

    await session.db.transaction((transaction) async {
      await _assertNotLastAdmin(session, member, transaction: transaction);
      await _staff.update(
        session,
        member.copyWith(active: false),
        transaction: transaction,
      );
      await _audit.record(
        session,
        action: AuditAction.staffDeactivated,
        actorUserId: actor.user.id,
        targetEmail: member.email,
        details: {'role': member.role!.name},
        transaction: transaction,
      );
    });
    return _item(session, await _find(session, id));
  }

  /// Si [member] tiene el rol de sistema, tiene que quedar otro activo. Las
  /// filas de los Administradores quedan bloqueadas hasta el fin de
  /// [transaction].
  Future<void> _assertNotLastAdmin(
    Session session,
    StaffMember member, {
    required Transaction transaction,
  }) async {
    if (member.role?.isSystem != true) return;
    final admins = await _staff.lockActiveWithRole(
      session,
      member.roleId,
      transaction: transaction,
    );
    final others = admins.where((admin) => admin.id != member.id);
    if (others.isEmpty) {
      throw ApiException.conflict(
        '${member.email} es el último ${member.role!.name} activo: agrega '
        'otro antes de quitarle el rol',
      );
    }
  }

  /// Un rol que existe y está activo.
  Future<Role> _assignableRole(Session session, UuidValue roleId) async {
    final role =
        await _roles.findById(session, roleId) ??
        (throw const ApiException.badRequest('El rol indicado no existe'));
    if (!role.active) {
      throw ApiException.conflict(
        'El rol ${role.name} está inactivo: actívalo antes de asignarlo',
      );
    }
    return role;
  }

  Future<StaffMember> _find(Session session, UuidValue id) async =>
      await _staff.findById(session, id) ??
      (throw const ApiException(404, 'Persona del personal no encontrada'));

  Future<StaffListItem> _item(Session session, StaffMember member) async =>
      (await _withAccounts(session, [member])).single;

  Future<List<StaffListItem>> _withAccounts(
    Session session,
    List<StaffMember> members,
  ) async {
    final registered = await _staff.emailsWithAccount(session, {
      for (final member in members) member.email,
    });
    return [
      for (final member in members)
        (member: member, hasAccount: registered.contains(member.email)),
    ];
  }
}
