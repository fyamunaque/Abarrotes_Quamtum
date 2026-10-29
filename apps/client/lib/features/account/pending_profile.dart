import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lo que se escribió al crear la cuenta y no se pudo guardar (p. ej. el DNI
/// ya estaba en otra cuenta), con el motivo. La cuenta igual quedó creada:
/// "Mi cuenta" lo propone y muestra el error para corregirlo.
typedef PendingProfile = ({String phone, String dni, String error});

final pendingProfileProvider =
    NotifierProvider<PendingProfileNotifier, PendingProfile?>(
      PendingProfileNotifier.new,
    );

class PendingProfileNotifier extends Notifier<PendingProfile?> {
  @override
  PendingProfile? build() => null;

  void set(PendingProfile? pending) => state = pending;
}
