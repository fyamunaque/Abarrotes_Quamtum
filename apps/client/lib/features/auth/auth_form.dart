import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_repository.dart';
import '../../router/route_guard.dart';
import '../../session/session.dart';
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

/// Contraseña con el botón para verla. [isNew] en el registro: pide el mínimo
/// de Firebase y le sugiere al gestor de contraseñas que cree una.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.isNew = false,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool isNew;

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
        labelText: 'Contraseña',
        helperText: widget.isNew ? 'Al menos 6 caracteres' : null,
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
      obscureText: _hidden,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      autofillHints: [
        widget.isNew ? AutofillHints.newPassword : AutofillHints.password,
      ],
      validator: widget.isNew ? validateNewPassword : validatePassword,
      onFieldSubmitted: (_) => widget.onSubmitted(),
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

/// El mínimo de Firebase Auth.
String? validateNewPassword(String? value) =>
    (value ?? '').length < 6 ? 'Usa al menos 6 caracteres.' : null;

/// El servidor guarda hasta 100 caracteres.
String? validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Escribe tu nombre.';
  if (name.length > 100) return 'Usa hasta 100 caracteres.';
  return null;
}
