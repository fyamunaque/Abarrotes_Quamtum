import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/brand.dart';

/// Estructura común de ingreso y registro: título, campos, botón principal y
/// un enlace a la otra pantalla. El botón queda deshabilitado mientras no
/// esté conectado Firebase Auth.
class AuthForm extends StatelessWidget {
  const AuthForm({
    super.key,
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.switchLabel,
    required this.switchRoute,
  });

  final String title;
  final List<Widget> fields;
  final String submitLabel;
  final String switchLabel;
  final String switchRoute;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PublicScaffold(
      maxWidth: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: text.headlineMedium),
          const SizedBox(height: 24),
          for (final field in fields) ...[field, const SizedBox(height: 16)],
          FilledButton(onPressed: null, child: Text(submitLabel)),
          const SizedBox(height: 8),
          Text(
            'Muy pronto vas a poder usar tu cuenta.',
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go(switchRoute),
            child: Text(switchLabel),
          ),
        ],
      ),
    );
  }
}
