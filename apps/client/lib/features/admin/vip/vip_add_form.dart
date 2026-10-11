import 'package:flutter/material.dart';

import '../../../admin/emails.dart';
import '../shared/emails_add_form.dart';

/// Agregar clientes VIP: uno o varios correos, con el resumen de lo que
/// respondió el servidor (ver [EmailsAddForm]).
class VipAddForm extends StatelessWidget {
  const VipAddForm({super.key, required this.onSubmit});

  final Future<EmailAddSummary> Function(List<String> emails) onSubmit;

  static String _allAdded(int count) => count == 1
      ? 'Listo: el correo es VIP.'
      : 'Listo: los $count correos son VIP.';

  @override
  Widget build(BuildContext context) {
    return EmailsAddForm(
      onSubmit: onSubmit,
      texts: const EmailsAddTexts(
        note:
            'Ven las promociones VIP cuando ingresan con ese correo y lo '
            'tienen verificado.',
        allAdded: _allAdded,
        duplicatesNote: 'Ya eran VIP o se repetían en la lista.',
      ),
    );
  }
}
