import 'package:serverpod/serverpod.dart';

import '../common/api_route.dart';
import '../generated/protocol.dart';

/// Dónde se guardan los roles del personal.
abstract interface class RoleRepository {
  /// Todos, el de sistema primero y después por nombre.
  Future<List<Role>> list(Session session);

  Future<Role?> findById(
    Session session,
    UuidValue id, {
    Transaction? transaction,
  });

  /// Sin distinguir mayúsculas.
  Future<Role?> findByName(
    Session session,
    String name, {
    Transaction? transaction,
  });

  /// El rol de sistema (Administrador), si ya existe.
  Future<Role?> findSystem(Session session, {Transaction? transaction});

  Future<Role> insert(Session session, Role role, {Transaction? transaction});

  Future<Role> update(Session session, Role role, {Transaction? transaction});

  Future<void> delete(Session session, Role role, {Transaction? transaction});
}

class DbRoleRepository implements RoleRepository {
  const DbRoleRepository();

  @override
  Future<List<Role>> list(Session session) async {
    final roles = await Role.db.find(
      session,
      orderBy: (role) => role.name,
    );
    return [
      ...roles.where((role) => role.isSystem),
      ...roles.where((role) => !role.isSystem),
    ];
  }

  @override
  Future<Role?> findById(
    Session session,
    UuidValue id, {
    Transaction? transaction,
  }) => Role.db.findById(session, id, transaction: transaction);

  @override
  Future<Role?> findByName(
    Session session,
    String name, {
    Transaction? transaction,
  }) => Role.db.findFirstRow(
    session,
    where: (role) => role.name.ilike(escapeLike(name.trim())),
    transaction: transaction,
  );

  @override
  Future<Role?> findSystem(Session session, {Transaction? transaction}) =>
      Role.db.findFirstRow(
        session,
        where: (role) => role.isSystem.equals(true),
        orderBy: (role) => role.createdAt,
        transaction: transaction,
      );

  @override
  Future<Role> insert(Session session, Role role, {Transaction? transaction}) =>
      Role.db.insertRow(session, role, transaction: transaction);

  @override
  Future<Role> update(Session session, Role role, {Transaction? transaction}) =>
      Role.db.updateRow(session, role, transaction: transaction);

  @override
  Future<void> delete(
    Session session,
    Role role, {
    Transaction? transaction,
  }) async {
    await Role.db.deleteRow(session, role, transaction: transaction);
  }
}
