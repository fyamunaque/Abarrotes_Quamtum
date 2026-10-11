import 'package:serverpod/serverpod.dart';

import '../common/api_route.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart';

/// Dónde se guarda el personal. Lo que se devuelve trae su rol (y quién lo
/// agregó, en el listado).
abstract interface class StaffRepository {
  /// La persona activa con [email] (ya normalizado), con su rol.
  Future<StaffMember?> findActiveByEmail(Session session, String email);

  Future<StaffMember?> findById(
    Session session,
    UuidValue id, {
    Transaction? transaction,
  });

  /// Las de [emails], activas o no.
  Future<List<StaffMember>> findByEmails(
    Session session,
    Set<String> emails, {
    Transaction? transaction,
  });

  /// Por correo. [search] busca en el correo.
  Future<(List<StaffMember>, int)> list(
    Session session,
    PageQuery page, {
    String? search,
    bool includeInactive = false,
  });

  /// Las activas con [roleId], bloqueadas (FOR UPDATE) hasta el fin de
  /// [transaction]: así dos cambios a la vez no dejan el rol sin nadie.
  Future<List<StaffMember>> lockActiveWithRole(
    Session session,
    UuidValue roleId, {
    required Transaction transaction,
  });

  /// Cuántas tiene [roleId] (también dadas de baja, salvo con [activeOnly]).
  Future<int> countWithRole(
    Session session,
    UuidValue roleId, {
    bool activeOnly = false,
    Transaction? transaction,
  });

  /// Cuántas activas tiene cada rol.
  Future<Map<UuidValue, int>> activeCountsByRole(Session session);

  /// Cuáles de [emails] ya tienen una cuenta en la tienda.
  Future<Set<String>> emailsWithAccount(Session session, Set<String> emails);

  Future<StaffMember> insert(
    Session session,
    StaffMember member, {
    Transaction? transaction,
  });

  Future<StaffMember> update(
    Session session,
    StaffMember member, {
    Transaction? transaction,
  });
}

class DbStaffRepository implements StaffRepository {
  const DbStaffRepository();

  static final _withRole = StaffMember.include(role: Role.include());
  static final _withRoleAndAdder = StaffMember.include(
    role: Role.include(),
    addedBy: User.include(),
  );

  @override
  Future<StaffMember?> findActiveByEmail(Session session, String email) =>
      StaffMember.db.findFirstRow(
        session,
        where: (member) =>
            member.email.equals(email) & member.active.equals(true),
        include: _withRole,
      );

  @override
  Future<StaffMember?> findById(
    Session session,
    UuidValue id, {
    Transaction? transaction,
  }) => StaffMember.db.findById(
    session,
    id,
    include: _withRoleAndAdder,
    transaction: transaction,
  );

  @override
  Future<List<StaffMember>> findByEmails(
    Session session,
    Set<String> emails, {
    Transaction? transaction,
  }) => StaffMember.db.find(
    session,
    where: (member) => member.email.inSet(emails),
    transaction: transaction,
  );

  @override
  Future<(List<StaffMember>, int)> list(
    Session session,
    PageQuery page, {
    String? search,
    bool includeInactive = false,
  }) async {
    Expression where(StaffMemberTable member) {
      Expression filter = Constant.bool(true);
      if (!includeInactive) filter &= member.active.equals(true);
      if (search != null) {
        filter &= member.email.ilike('%${escapeLike(search)}%');
      }
      return filter;
    }

    final members = await StaffMember.db.find(
      session,
      where: where,
      orderByList: (member) => [member.email.asc()],
      limit: page.limit,
      offset: page.offset,
      include: _withRoleAndAdder,
    );
    final total = await StaffMember.db.count(session, where: where);
    return (members, total);
  }

  @override
  Future<List<StaffMember>> lockActiveWithRole(
    Session session,
    UuidValue roleId, {
    required Transaction transaction,
  }) => StaffMember.db.find(
    session,
    where: (member) =>
        member.roleId.equals(roleId) & member.active.equals(true),
    orderBy: (member) => member.id,
    lockMode: LockMode.forUpdate,
    transaction: transaction,
  );

  @override
  Future<int> countWithRole(
    Session session,
    UuidValue roleId, {
    bool activeOnly = false,
    Transaction? transaction,
  }) => StaffMember.db.count(
    session,
    where: (member) => activeOnly
        ? member.roleId.equals(roleId) & member.active.equals(true)
        : member.roleId.equals(roleId),
    transaction: transaction,
  );

  @override
  Future<Map<UuidValue, int>> activeCountsByRole(Session session) async {
    final counts = <UuidValue, int>{};
    for (final member in await StaffMember.db.find(
      session,
      where: (member) => member.active.equals(true),
    )) {
      counts.update(member.roleId, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  @override
  Future<Set<String>> emailsWithAccount(
    Session session,
    Set<String> emails,
  ) async => emails.isEmpty
      ? const {}
      : {
          for (final user in await User.db.find(
            session,
            where: (user) => user.email.inSet(emails),
          ))
            user.email,
        };

  @override
  Future<StaffMember> insert(
    Session session,
    StaffMember member, {
    Transaction? transaction,
  }) => StaffMember.db.insertRow(session, member, transaction: transaction);

  @override
  Future<StaffMember> update(
    Session session,
    StaffMember member, {
    Transaction? transaction,
  }) => StaffMember.db.updateRow(session, member, transaction: transaction);
}
