import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_repository.dart';
import '../../config/app_version.dart';
import '../../router/route_guard.dart';
import '../../session/session.dart';
import '../../theme/brand_colors.dart';
import '../shared/brand.dart';

/// Estructura común de ingreso y registro: título, campos, botón principal y
/// un enlace a la otra pantalla. Valida los campos, muestra el progreso y el
/// error, y al terminar va a donde corresponda según el rol.
///
/// Desde [twoColumnsFrom] de ancho, a la izquierda va un panel de la marca
/// y el formulario a la derecha.
class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.submit,
    required this.switchLabel,
    required this.switchRoute,
    this.from,
  });

  final String title;

  /// Los campos. Reciben la acción de enviar, para el Enter del último.
  final List<Widget> Function(VoidCallback submit) fields;

  final String submitLabel;

  /// Ingresa o registra con lo que hay en los campos.
  final Future<SessionUser> Function() submit;

  final String switchLabel;
  final String switchRoute;

  /// La ruta que pidió el ingreso (ver [routeAfterSignIn]).
  final String? from;

  static const twoColumnsFrom = 900.0;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await widget.submit();
      if (mounted) context.go(routeAfterSignIn(user, widget.from));
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (error, stack) {
      if (mounted) {
        setState(() => _error = 'Algo salió mal. Vuelve a intentar.');
      }
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'auth'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= AuthForm.twoColumnsFrom;
    final form = Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            for (final field in widget.fields(_submit)) ...[
              field,
              const SizedBox(height: 16),
            ],
            if (_error case final error?) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.submitLabel),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _busy ? null : () => context.go(widget.switchRoute),
              child: Text(widget.switchLabel),
            ),
            // Qué versión es (el APK o la web compilada): sin ingresar.
            if (appVersionLabel case final version?) ...[
              const SizedBox(height: 24),
              Text(
                version,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return PublicScaffold(
      title: widget.title,
      maxWidth: wide ? 960 : 420,
      child: wide
          ? Row(
              children: [
                const Expanded(child: _BrandPanel()),
                const SizedBox(width: 48),
                SizedBox(width: 420, child: form),
              ],
            )
          : form,
    );
  }
}

/// En escritorio, al lado del formulario: el logo, el titular y qué ofrece
/// la tienda.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const _points = [
    (Icons.sell_outlined, 'Precios y promociones de la tienda'),
    (Icons.local_shipping_outlined, 'A domicilio o recojo en tienda'),
    (Icons.receipt_long_outlined, 'Sigue tu pedido'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSecondaryContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NeilsLogo(height: 96),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                'Tus abarrotes, a la puerta de tu casa',
                style: theme.textTheme.headlineSmall?.copyWith(color: color),
              ),
            ),
            const SizedBox(height: 20),
            for (final (icon, text) in _points)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Correo'),
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      validator: validateEmail,
    );
  }
}

/// Contraseña con el botón para verla. [isNew] en el registro: pide una
/// contraseña fuerte ([validateNewPassword]) y le sugiere al gestor de
/// contraseñas que cree una. [label] y [validator] cambian para "Repetir
/// contraseña". Sin [onSubmitted], Enter pasa al campo siguiente.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.isNew = false,
    this.label = 'Contraseña',
    this.validator,
  });

  final TextEditingController controller;
  final VoidCallback? onSubmitted;
  final bool isNew;
  final String label;
  final FormFieldValidator<String>? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.isNew && widget.validator == null
            ? 'Al menos 8 caracteres, con letras y números'
            : null,
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
      obscureText: _hidden,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      autofillHints: [
        widget.isNew ? AutofillHints.newPassword : AutofillHints.password,
      ],
      validator:
          widget.validator ??
          (widget.isNew ? validateNewPassword : validatePassword),
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
    );
  }
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Escribe tu correo.';
  if (!_emailPattern.hasMatch(email)) return 'Ese correo no es válido.';
  return null;
}

String? validatePassword(String? value) =>
    (value ?? '').isEmpty ? 'Escribe tu contraseña.' : null;

/// Una contraseña nueva: al menos 8 caracteres, con letras y números. Solo
/// al registrarse: ingresar con una contraseña de antes sigue funcionando.
/// Para que Firebase también lo exija, ver "Contraseñas" en
/// apps/client/README.md.
String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) return 'Usa al menos 8 caracteres.';
  if (!_letter.hasMatch(password) || !_digit.hasMatch(password)) {
    return 'Combina letras y números.';
  }
  return null;
}

final _letter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');
final _digit = RegExp(r'\d');

/// Qué tan segura es una contraseña nueva.
enum PasswordStrength {
  weak('débil'),
  medium('media'),
  strong('fuerte');

  const PasswordStrength(this.label);

  final String label;

  /// Débil si no cumple [validateNewPassword]; fuerte si además tiene dos
  /// de: 12 caracteres o más, mayúsculas y minúsculas, un símbolo.
  static PasswordStrength of(String password) {
    if (validateNewPassword(password) != null) return weak;
    final extras = [
      password.length >= 12,
      RegExp(r'[a-zñ]').hasMatch(password) &&
          RegExp(r'[A-ZÑ]').hasMatch(password),
      RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(password),
    ].where((met) => met).length;
    return extras >= 2 ? strong : medium;
  }
}

/// Debajo de la contraseña nueva: una barra de tres partes y "Seguridad:
/// media", que cambian mientras se escribe. Con la contraseña vacía, nada.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.text.isEmpty) return const SizedBox.shrink();
        final strength = PasswordStrength.of(controller.text);
        final color = switch (strength) {
          PasswordStrength.weak => theme.colorScheme.error,
          PasswordStrength.medium => StateColors.caution,
          PasswordStrength.strong => StateColors.positive,
        };
        return Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (final (i, level)
                        in PasswordStrength.values.indexed) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: level.index <= strength.index
                                ? color
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strength == PasswordStrength.strong
                    ? 'Seguridad: fuerte'
                    : 'Seguridad: ${strength.label}. Más segura con 12 '
                          'caracteres, mayúsculas y un símbolo.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Repetir contraseña": igual a la de [password].
FormFieldValidator<String> validateRepeatedPassword(
  TextEditingController password,
) =>
    (value) =>
        (value ?? '') == password.text ? null : 'Las contraseñas no coinciden.';

/// El servidor guarda hasta 100 caracteres.
String? validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Escribe tu nombre.';
  if (name.length > 100) return 'Usa hasta 100 caracteres.';
  return null;
}
