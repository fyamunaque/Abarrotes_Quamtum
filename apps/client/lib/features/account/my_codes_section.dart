import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/money.dart';
import '../../promo_codes/my_promo_code.dart';
import '../../promo_codes/my_promo_codes_providers.dart';
import '../../theme/brand_colors.dart';
import '../shared/date_format.dart';
import '../shared/error_message.dart';

/// "Mis códigos" en Mi cuenta: "Escribe tu código" con "Activar" (el error
/// del servidor debajo del campo) y los códigos que la cuenta tiene activos
/// con lo que dan, cuándo vencen y cuántos usos le quedan. Al activar uno,
/// [onRedeemed] (p. ej. volver al carrito).
class MyCodesSection extends ConsumerStatefulWidget {
  const MyCodesSection({super.key, this.onRedeemed});

  final VoidCallback? onRedeemed;

  @override
  ConsumerState<MyCodesSection> createState() => _MyCodesSectionState();
}

class _MyCodesSectionState extends ConsumerState<MyCodesSection> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _code.text.trim();
    if (_busy || code.isEmpty) {
      setState(() => _error = code.isEmpty ? 'Escribe el código.' : null);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final redeemed = await ref
          .read(myPromoCodesProvider.notifier)
          .redeem(code);
      if (!mounted) return;
      _code.clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Activaste el código ${redeemed.code}.')),
        );
      widget.onRedeemed?.call();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = errorMessage(error, 'No se pudo activar el código.'),
        );
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
    final codes = ref.watch(myPromoCodesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mis códigos', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Activa un código promocional: sus promociones se aplican en el '
          'carrito.',
          style: muted,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _code,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: 'Escribe tu código',
                  hintText: 'Como te lo dieron',
                  errorText: _error,
                  errorMaxLines: 3,
                ),
                inputFormatters: [
                  const _UpperCaseFormatter(),
                  LengthLimitingTextInputFormatter(40),
                ],
                textInputAction: TextInputAction.done,
                autocorrect: false,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _redeem(),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FilledButton.tonal(
                onPressed: _busy ? null : _redeem,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Activar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        switch (codes) {
          AsyncData(:final value) when value.isEmpty => Text(
            'Todavía no activaste ningún código.',
            style: muted,
          ),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final code in value) _CodeCard(code)],
          ),
          AsyncError(:final error) => Text(
            errorMessage(error, 'No se pudieron cargar tus códigos.'),
            style: muted,
          ),
          _ => const LinearProgressIndicator(),
        },
      ],
    );
  }
}

/// Un código activado: el texto, lo que da, cuándo vence y cuántos usos
/// le quedan.
class _CodeCard extends StatelessWidget {
  const _CodeCard(this.code);

  final MyPromoCode code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final uses = switch (code.usesLeft) {
      null => 'Sin límite de usos',
      1 => 'Te queda 1 uso',
      final left => 'Te quedan $left usos',
    };
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: NeilsColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(code.code, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final promotion in code.promotions)
              Text(promotion, style: theme.textTheme.bodyMedium),
            if (code.minPurchaseCents case final minimum?)
              Text(
                'Con compras desde ${formatSoles(minimum)}',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 4),
            Text(
              'Vence el ${formatStoreDay(context, code.lastDay)}',
              style: muted,
            ),
            Text(uses, style: muted),
          ],
        ),
      ),
    );
  }
}

/// El código en mayúsculas mientras se escribe (el servidor lo acepta como
/// sea; así se lee como en el aviso).
class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
