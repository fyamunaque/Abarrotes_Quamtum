import 'package:flutter/material.dart';

import '../../../orders/fulfillment.dart';
import '../../../orders/order_status.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';

/// Pide el código que da el cliente para entregar su pedido: el de recojo,
/// que muestra en caja, o el de entrega, que le da al repartidor ([type]).
/// Entrega el pedido con [onSubmit]. Si el servidor lo rechaza (el código no
/// coincide), el motivo queda en el diálogo para volver a escribirlo.
///
/// Con [onDeliverWithoutCode] (a domicilio, solo quien administra la tienda)
/// ofrece además "Entregar sin código", con el motivo, por si el cliente no
/// lo tiene. Devuelve true si se entregó.
Future<bool> showOrderCodeDialog(
  BuildContext context, {
  required FulfillmentType type,
  required Future<void> Function(String code) onSubmit,
  Future<void> Function(String reason)? onDeliverWithoutCode,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _OrderCodeDialog(
        type: type,
        onSubmit: onSubmit,
        onDeliverWithoutCode: onDeliverWithoutCode,
      ),
    ) ??
    false;

/// El motivo más corto que acepta el servidor.
const _minReasonLength = 5;

class _OrderCodeDialog extends StatefulWidget {
  const _OrderCodeDialog({
    required this.type,
    required this.onSubmit,
    this.onDeliverWithoutCode,
  });

  final FulfillmentType type;
  final Future<void> Function(String code) onSubmit;
  final Future<void> Function(String reason)? onDeliverWithoutCode;

  @override
  State<_OrderCodeDialog> createState() => _OrderCodeDialogState();
}

class _OrderCodeDialogState extends State<_OrderCodeDialog> {
  final _code = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Entregando sin el código: se escribe el motivo.
  bool _withoutCode = false;

  bool get _pickup => widget.type == FulfillmentType.pickup;

  @override
  void dispose() {
    _code.dispose();
    _reason.dispose();
    super.dispose();
  }

  bool get _ready => _withoutCode
      ? _reason.text.trim().length >= _minReasonLength
      : _code.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_ready || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_withoutCode) {
        await widget.onDeliverWithoutCode!(_reason.text.trim());
      } else {
        await widget.onSubmit(_code.text.trim());
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = errorMessage(error, 'No se pudo entregar el pedido.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _switchMode(bool withoutCode) => setState(() {
    _withoutCode = withoutCode;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final submitLabel = _withoutCode
        ? 'Entregar sin código'
        : widget.type.actionLabelOf(OrderStatus.delivered);
    return AlertDialog(
      title: Text(_withoutCode ? 'Entregar sin código' : 'Entregar el pedido'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_withoutCode) ...[
            const Text(
              'Solo si el cliente no tiene su código. El motivo queda en el '
              'pedido y en la bitácora del equipo.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              autofocus: true,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                helperText: 'Por ejemplo: el cliente no tenía el celular.',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 255,
              minLines: 1,
              maxLines: 3,
              onChanged: (_) => setState(() => _error = null),
            ),
          ] else ...[
            TextField(
              controller: _code,
              autofocus: true,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: _pickup ? 'Código de recojo' : 'Código de entrega',
                helperText: _pickup
                    ? 'El que muestra el cliente.'
                    : 'El que te da el cliente.',
              ),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              maxLength: 6,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.onDeliverWithoutCode != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _busy ? null : () => _switchMode(true),
                  child: const Text('El cliente no tiene su código'),
                ),
              ),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 8),
            FormError(error),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy
              ? null
              : _withoutCode
              ? () => _switchMode(false)
              : () => Navigator.of(context).pop(false),
          child: const Text('Volver'),
        ),
        ListenableBuilder(
          listenable: Listenable.merge([_code, _reason]),
          builder: (_, _) => FilledButton(
            onPressed: _busy || !_ready ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(submitLabel),
          ),
        ),
      ],
    );
  }
}
