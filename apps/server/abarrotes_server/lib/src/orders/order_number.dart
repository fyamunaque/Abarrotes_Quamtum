// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

/// El número del primer pedido.
const firstOrderNumber = 1001;

/// El número para el pedido que se crea en [transaction]: el más alto que
/// hay + 1 (o [firstOrderNumber]).
///
/// Toma un bloqueo de Postgres que dura hasta que la transacción termina: dos
/// pedidos que se crean a la vez esperan su turno y no sacan el mismo número.
/// El índice único de `number` queda de respaldo.
Future<int> nextOrderNumber(Session session, Transaction transaction) async {
  await session.db.unsafeQuery(
    'SELECT pg_advisory_xact_lock($_lockKey)',
    transaction: transaction,
  );
  final rows = await session.db.unsafeQuery(
    'SELECT MAX("number") FROM "orders"',
    transaction: transaction,
  );
  final highest = rows.first.first as int?;
  return highest == null ? firstOrderNumber : highest + 1;
}

/// La llave del bloqueo de los números de pedido (cualquier número fijo que
/// no use otro bloqueo de la app).
const _lockKey = 81240001;
