import 'package:serverpod/serverpod.dart';

import '../common/api_route.dart';
import '../common/emails.dart' as emails;
import '../common/http_json.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart';

/// Un VIP como lo muestra el panel: con si su correo ya tiene cuenta.
typedef VipListItem = ({VipCustomer vip, bool hasAccount});

/// El resultado de agregar varios correos a la vez (ver `EmailAddSummary`).
typedef VipAddSummary = emails.EmailAddSummary;

/// Los clientes VIP: alta, baja y consulta. Las promociones solo preguntan
/// [isActiveVip] (a través de `VipShopperResolver`), así que este servicio no
/// sabe nada de ellas.
class VipService {
  const VipService();

  /// Cuántos correos se aceptan por alta.
  static const maxPerRequest = 500;

  /// Como se guardan: en minúsculas y sin espacios (en ninguna parte).
  static String normalizeEmail(String email) => emails.normalizeEmail(email);

  /// Un formato razonable de correo ya normalizado (ver `common/emails.dart`).
  static bool isValidEmail(String email) => emails.isValidEmail(email);

  /// Por correo. Sin [includeInactive], solo los activos. [search] busca en
  /// el correo.
  Future<(List<VipListItem>, int)> list(
    Session session,
    PageQuery page, {
    String? search,
    bool includeInactive = false,
  }) async {
    Expression where(VipCustomerTable vip) {
      Expression filter = Constant.bool(true);
      if (!includeInactive) filter &= vip.active.equals(true);
      if (search != null) {
        filter &= vip.email.ilike('%${escapeLike(normalizeEmail(search))}%');
      }
      return filter;
    }

    final vips = await VipCustomer.db.find(
      session,
      where: where,
      orderByList: (vip) => [vip.email.asc()],
      limit: page.limit,
      offset: page.offset,
      include: _include,
    );
    final total = await VipCustomer.db.count(session, where: where);
    return (await _withAccounts(session, vips), total);
  }

  /// Agrega [emails] a nombre de [by]. Los inválidos y los duplicados
  /// (repetidos en la lista o ya activos) se informan sin cortar el resto. Un
  /// correo dado de baja que vuelve se reactiva y cuenta como agregado.
  Future<VipAddSummary> add(
    Session session,
    List<String> requested, {
    required User by,
  }) async {
    final added = <String>[];
    final (:candidates, :duplicates, :invalid) = emails.sortEmails(requested);
    if (candidates.isEmpty) {
      return (added: added, duplicates: duplicates, invalid: invalid);
    }

    try {
      await session.db.transaction((transaction) async {
        final existing = {
          for (final vip in await VipCustomer.db.find(
            session,
            where: (vip) => vip.email.inSet(candidates.toSet()),
            transaction: transaction,
          ))
            vip.email: vip,
        };
        final created = <VipCustomer>[];
        for (final email in candidates) {
          final current = existing[email];
          if (current == null) {
            created.add(VipCustomer(email: email, addedByUserId: by.id!));
            added.add(email);
          } else if (current.active) {
            duplicates.add(email);
          } else {
            await VipCustomer.db.updateRow(
              session,
              current.copyWith(active: true, addedByUserId: by.id!),
              columns: (vip) => [vip.active, vip.addedByUserId],
              transaction: transaction,
            );
            added.add(email);
          }
        }
        if (created.isNotEmpty) {
          await VipCustomer.db.insert(
            session,
            created,
            transaction: transaction,
          );
        }
      });
    } on DatabaseUniqueViolationException {
      // Otra alta con alguno de estos correos se guardó al mismo tiempo.
      throw const ApiException.conflict(
        'Otra persona agregó alguno de estos correos al mismo tiempo: '
        'vuelve a intentarlo',
      );
    }
    return (added: added, duplicates: duplicates, invalid: invalid);
  }

  /// Lo da de baja: deja de ser VIP, pero la fila queda (con quién lo agregó
  /// y cuándo). Darlo de baja dos veces no es error.
  Future<VipListItem> deactivate(Session session, UuidValue id) async {
    final vip = await VipCustomer.db.findById(session, id, include: _include);
    if (vip == null) throw const ApiException(404, 'Cliente VIP no encontrado');
    if (vip.active) {
      await VipCustomer.db.updateRow(
        session,
        vip.copyWith(active: false),
        columns: (vip) => [vip.active],
      );
    }
    final [item] = await _withAccounts(session, [vip.copyWith(active: false)]);
    return item;
  }

  /// Los correos de todos los VIP activos (p. ej. para avisarles de una
  /// promoción).
  Future<Set<String>> activeEmails(Session session) async => {
    for (final vip in await VipCustomer.db.find(
      session,
      where: (vip) => vip.active.equals(true),
    ))
      vip.email,
  };

  /// Si [email] (en cualquier forma) es de un VIP activo.
  Future<bool> isActiveVip(Session session, String email) async {
    final normalized = normalizeEmail(email);
    final vip = await VipCustomer.db.findFirstRow(
      session,
      where: (vip) => vip.email.equals(normalized) & vip.active.equals(true),
    );
    return vip != null;
  }

  /// Cada VIP con si su correo ya tiene cuenta (una sola consulta a users).
  Future<List<VipListItem>> _withAccounts(
    Session session,
    List<VipCustomer> vips,
  ) async {
    final emails = {for (final vip in vips) vip.email};
    final registered = emails.isEmpty
        ? const <String>{}
        : {
            for (final user in await User.db.find(
              session,
              where: (user) => user.email.inSet(emails),
            ))
              user.email,
          };
    return [
      for (final vip in vips)
        (vip: vip, hasAccount: registered.contains(vip.email)),
    ];
  }

  static final _include = VipCustomer.include(addedBy: User.include());
}
