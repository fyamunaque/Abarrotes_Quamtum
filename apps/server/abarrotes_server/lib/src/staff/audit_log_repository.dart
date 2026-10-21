import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../common/pagination.dart';
import '../generated/protocol.dart';

/// La bitácora de los cambios del personal.
abstract interface class AuditLogRepository {
  /// Anota un cambio. [actorUserId] null: lo hizo el sistema. Va en la misma
  /// [transaction] que el cambio, así no queda uno sin el otro.
  Future<void> record(
    Session session, {
    required AuditAction action,
    UuidValue? actorUserId,
    String? targetEmail,
    Map<String, Object?>? details,
    Transaction? transaction,
  });

  /// Los más recientes primero, con quién los hizo.
  Future<(List<AuditLog>, int)> list(Session session, PageQuery page);
}

class DbAuditLogRepository implements AuditLogRepository {
  const DbAuditLogRepository();

  @override
  Future<void> record(
    Session session, {
    required AuditAction action,
    UuidValue? actorUserId,
    String? targetEmail,
    Map<String, Object?>? details,
    Transaction? transaction,
  }) async {
    await AuditLog.db.insertRow(
      session,
      AuditLog(
        action: action,
        actorUserId: actorUserId,
        targetEmail: targetEmail,
        details: details == null ? null : jsonEncode(details),
        createdAt: DateTime.now().toUtc(),
      ),
      transaction: transaction,
    );
  }

  @override
  Future<(List<AuditLog>, int)> list(Session session, PageQuery page) async {
    final entries = await AuditLog.db.find(
      session,
      orderByList: (log) => [log.createdAt.desc(), log.id.desc()],
      limit: page.limit,
      offset: page.offset,
      include: AuditLog.include(actor: User.include()),
    );
    return (entries, await AuditLog.db.count(session));
  }
}
