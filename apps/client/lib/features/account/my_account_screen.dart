import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/api_client.dart';
import '../../legal/legal_texts.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import '../shared/brand.dart';
import '../shared/error_message.dart';
import '../shared/info_line.dart';
import 'my_codes_section.dart';
import 'pending_profile.dart';
import 'profile_fields.dart';

/// "Mi cuenta": lo que pide un pedido además del correo confirmado (el
/// celular y aceptar los términos vigentes) y el DNI, opcional. El nombre y
/// el correo se ven, pero son los de la cuenta de Firebase.
///
/// Si al crear la cuenta no se pudieron guardar estos datos, los propone con
/// el error ([pendingProfileProvider]). Debajo, "Mis códigos" para activar
/// un código promocional ([codesFirst]: arriba de todo). Con [from] (una
/// ruta de la app), al guardar o al activar un código vuelve ahí, p. ej.
/// al carrito.
class MyAccountScreen extends ConsumerStatefulWidget {
  const MyAccountScreen({super.key, this.from, this.codesFirst = false});

  final String? from;
  final bool codesFirst;

  @override
  ConsumerState<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends ConsumerState<MyAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _dni = TextEditingController();
  bool _acceptedTerms = false;
  bool _busy = false;
  String? _error;
  String? _dniError;

  @override
  void initState() {
    super.initState();
    final user = _user;
    final pending = ref.read(pendingProfileProvider);
    _phone.text = pending?.phone ?? user?.phone ?? '';
    _dni.text = pending?.dni ?? user?.dni ?? '';
    if (pending != null) {
      // El DNI repetido va en su campo; lo demás, arriba del botón.
      if (pending.error.contains('DNI')) {
        _dniError = pending.error;
      } else {
        _error = pending.error;
      }
      _acceptedTerms = true;
      // Ya se mostró: no vuelve a aparecer.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(pendingProfileProvider.notifier).set(null),
      );
    }
  }

  SessionUser? get _user => switch (ref.read(sessionProvider)) {
    SignedIn(:final user) => user,
    _ => null,
  };

  @override
  void dispose() {
    _phone.dispose();
    _dni.dispose();
    super.dispose();
  }

  /// [widget.from] si es una ruta de la app (viene en la URL: nada de
  /// direcciones de afuera).
  String? get _returnTo {
    final from = widget.from;
    if (from == null || !from.startsWith('/')) return null;
    final uri = Uri.tryParse(from);
    return uri == null || uri.hasScheme || uri.hasAuthority ? null : from;
  }

  Future<void> _save(SessionUser user) async {
    setState(() {
      _error = null;
      _dniError = null;
    });
    if (_busy || !_formKey.currentState!.validate()) return;
    final termsAccepted = user.termsVersion == termsVersion;
    final dni = _dni.text.trim();
    setState(() => _busy = true);
    try {
      await ref
          .read(sessionProvider.notifier)
          .updateProfile(
            phone: _phone.text.trim(),
            dni: dni.isEmpty ? null : dni,
            clearDni: dni.isEmpty && user.dni != null,
            acceptTerms: !termsAccepted && _acceptedTerms,
          );
      if (!mounted) return;
      if (_returnTo case final returnTo?) {
        context.go(returnTo);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Guardamos tus datos.')));
      }
    } catch (error) {
      if (mounted) {
        final message = errorMessage(
          error,
          'No se pudieron guardar tus datos.',
        );
        setState(() {
          if (error is ApiFailure && error.status == 409) {
            _dniError = message;
          } else {
            _error = message;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final user = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user,
      _ => null,
    };
    final codes = MyCodesSection(
      onRedeemed: switch (_returnTo) {
        final returnTo? => () => context.go(returnTo),
        null => null,
      },
    );
    return PublicScaffold(
      title: 'Mi cuenta',
      maxWidth: 520,
      child: user == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.codesFirst) ...[codes, const Divider(height: 48)],
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Mi cuenta', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(user.name, style: theme.textTheme.titleMedium),
                      Text(user.email, style: muted),
                      const SizedBox(height: 16),
                      if (!user.profileComplete) ...[
                        const _IncompleteNote(),
                        const SizedBox(height: 16),
                      ],
                      PhoneField(controller: _phone),
                      const SizedBox(height: 16),
                      DniField(
                        controller: _dni,
                        errorText: _dniError,
                        onChanged: (_) {
                          if (_dniError != null) {
                            setState(() => _dniError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      if (user.termsVersion == termsVersion &&
                          user.termsAcceptedAt != null)
                        _AcceptedTerms(user.termsAcceptedAt!)
                      else
                        TermsCheckbox(
                          value: _acceptedTerms,
                          onChanged: (accepted) =>
                              setState(() => _acceptedTerms = accepted),
                        ),
                      if (_error case final error?) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            error,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : () => _save(user),
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar'),
                      ),
                    ],
                  ),
                ),
                if (!widget.codesFirst) ...[const Divider(height: 48), codes],
              ],
            ),
    );
  }
}

/// Qué falta para pedir.
class _IncompleteNote extends StatelessWidget {
  const _IncompleteNote();

  @override
  Widget build(BuildContext context) {
    return const InfoLine(
      icon: Icons.info_outline,
      text:
          'Para hacer pedidos, completa tu celular y acepta los términos de '
          'uso y la política de privacidad.',
    );
  }
}

/// "Aceptaste los términos el …", con los dos textos para volver a leerlos.
class _AcceptedTerms extends StatelessWidget {
  const _AcceptedTerms(this.acceptedAt);

  final DateTime acceptedAt;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(acceptedAt.toLocal());
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Aceptaste los términos y la política de privacidad el $date.'),
        TextButton(
          onPressed: () => showLegalText(context, termsOfUse),
          child: Text(termsOfUse.title),
        ),
        TextButton(
          onPressed: () => showLegalText(context, privacyPolicy),
          child: Text(privacyPolicy.title),
        ),
      ],
    );
  }
}
