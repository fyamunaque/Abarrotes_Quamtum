import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/routes.dart';
import '../../session/session_provider.dart';
import 'auth_form.dart';
import 'password_reset_dialog.dart';

/// Ingreso. [from] es la ruta protegida que lo trajo aquí (p. ej. /admin):
/// después de ingresar se vuelve a ella si la cuenta puede verla.
/// "¿Olvidaste tu contraseña?" manda el enlace para crear una nueva.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      title: 'Ingresar',
      from: widget.from,
      fields: (submit) => [
        EmailField(controller: _email),
        PasswordField(controller: _password, onSubmitted: submit),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => showPasswordResetDialog(
              context,
              email: _email.text.trim(),
              onSend: ref.read(sessionProvider.notifier).sendPasswordReset,
            ),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
      ],
      submitLabel: 'Ingresar',
      submit: () => ref
          .read(sessionProvider.notifier)
          .signIn(email: _email.text, password: _password.text),
      switchLabel: '¿No tienes cuenta? Crea una',
      switchRoute: Routes.register,
    );
  }
}
