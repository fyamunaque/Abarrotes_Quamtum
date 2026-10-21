import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import '../generated/protocol.dart';

/// Los datos de la tienda: un solo registro, que se crea la primera vez que
/// alguien con `store.manage` los edita.
class StoreSettingsService {
  const StoreSettingsService();

  /// Lo que se muestra mientras nadie los cargó (no se guarda).
  static StoreSettings get defaults =>
      StoreSettings(name: "Neil's Food Services", address: '');

  /// Los datos guardados o, si todavía no hay, los de [defaults].
  Future<StoreSettings> get(Session session) async =>
      await StoreSettings.db.findFirstRow(session) ?? defaults;

  /// Aplica [edit] sobre los datos actuales (los de [defaults] la primera
  /// vez) y los guarda a nombre de [by]. Nombre y dirección no pueden quedar
  /// vacíos. La fila se bloquea mientras tanto: dos ediciones a la vez se
  /// ordenan, y si las dos son la primera, el índice único de `singleton`
  /// deja pasar una sola.
  Future<StoreSettings> update(
    Session session,
    StoreSettings Function(StoreSettings current) edit, {
    required User by,
  }) async {
    try {
      return await session.db.transaction((transaction) async {
        final current = await StoreSettings.db.findFirstRow(
          session,
          lockMode: LockMode.forUpdate,
          transaction: transaction,
        );
        final edited = edit(current ?? defaults).copyWith(
          updatedAt: DateTime.now().toUtc(),
          updatedByUserId: by.id,
        );
        if (edited.name.trim().isEmpty) {
          throw const ApiException.badRequest('Falta el nombre de la tienda');
        }
        if (edited.address.trim().isEmpty) {
          throw const ApiException.badRequest(
            'Falta la dirección de la tienda',
          );
        }
        return current == null
            ? await StoreSettings.db.insertRow(
                session,
                edited,
                transaction: transaction,
              )
            : await StoreSettings.db.updateRow(
                session,
                edited,
                transaction: transaction,
              );
      });
    } on DatabaseUniqueViolationException {
      throw const ApiException.conflict(
        'Otra persona guardó los datos de la tienda al mismo tiempo: vuelve '
        'a intentarlo',
      );
    }
  }
}
