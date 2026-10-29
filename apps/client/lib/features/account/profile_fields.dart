import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../legal/legal_texts.dart';

/// [text] como celular peruano normalizado ("987654321"), o null si no es uno:
/// 9 dígitos que empiezan con 9, con espacios, guiones o +51 delante. Las
/// mismas reglas que `normalizePhone` en apps/server.
String? normalizePhone(String text) {
  var digits = text.replaceAll(RegExp(r'[\s\-.()]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  if (digits.length == 11 && digits.startsWith('51')) {
    digits = digits.substring(2);
  }
  return RegExp(r'^9\d{8}$').hasMatch(digits) ? digits : null;
}

String? validatePhone(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Escribe tu celular.';
  if (normalizePhone(text) == null) {
    return 'Usa un celular de 9 dígitos que empiece con 9.';
  }
  return null;
}

/// Opcional: vacío está bien.
String? validateDni(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return RegExp(r'^\d{8}$').hasMatch(text) ? null : 'El DNI tiene 8 dígitos.';
}

/// Por qué conviene agregar el DNI, aunque sea opcional.
const dniHelp =
    'Con tu DNI, la tienda puede confirmar que eres tú al entregar o recoger '
    'tu pedido: tu cuenta queda más protegida.';

/// El celular, obligatorio para pedir: la tienda lo usa para coordinar la
/// entrega.
class PhoneField extends StatelessWidget {
  const PhoneField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Celular',
        prefixText: '+51 ',
        hintText: '987 654 321',
        helperText: 'Para coordinar la entrega de tus pedidos.',
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-+]')),
      ],
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      validator: validatePhone,
    );
  }
}

/// El DNI, opcional, con [dniHelp] debajo. [errorText] es un error que vino
/// del servidor (p. ej. que ya está en otra cuenta).
class DniField extends StatelessWidget {
  const DniField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'DNI (opcional)',
        helperText: dniHelp,
        helperMaxLines: 3,
        errorText: errorText,
        errorMaxLines: 3,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      textInputAction: TextInputAction.next,
      validator: validateDni,
      onChanged: onChanged,
    );
  }
}

/// "Acepto los Términos de uso y la Política de privacidad": obligatoria.
/// Los dos nombres abren el texto en un diálogo, así no se pierde lo escrito
/// en el formulario.
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  static const required =
      'Para continuar, acepta los términos de uso y la política de privacidad.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget link(LegalText text) => TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => showLegalText(context, text),
      child: Text(text.title),
    );
    return FormField<bool>(
      initialValue: value,
      // El valor del campo, que cambia al tocar la casilla (antes de que se
      // reconstruya con el nuevo [value]).
      validator: (checked) => checked == true ? null : required,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: (checked) {
                  onChanged(checked ?? false);
                  field.didChange(checked);
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Acepto los'),
                      link(termsOfUse),
                      const Text('y la'),
                      link(privacyPolicy),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (field.errorText case final error?)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// [text] en un diálogo que se puede desplazar.
Future<void> showLegalText(BuildContext context, LegalText text) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(text.title),
      scrollable: true,
      content: SizedBox(
        width: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (heading, body) in text.sections) ...[
              Text(heading, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(body),
              const SizedBox(height: 16),
            ],
            Text(
              'Versión del $termsVersion.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
