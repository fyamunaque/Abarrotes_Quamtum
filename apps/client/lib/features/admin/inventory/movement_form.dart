import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../admin/inventory/movement.dart';
import '../../../catalog/product.dart';
import '../../../theme/brand_colors.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/product_picker.dart';

/// Registrar una entrada, una salida o un ajuste de stock. Valida como el
/// servidor (en un ajuste la cantidad lleva signo y el motivo es
/// obligatorio) y muestra cómo queda el stock antes de registrarlo. Se
/// cierra con el movimiento registrado.
class MovementForm extends StatefulWidget {
  const MovementForm({super.key, required this.onSubmit});

  final Future<Movement> Function(MovementInput input) onSubmit;

  @override
  State<MovementForm> createState() => _MovementFormState();
}

class _MovementFormState extends State<MovementForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  Product? _product;
  MovementType _type = MovementType.incoming;
  bool _busy = false;
  String? _error;

  static const _maxQuantity = 1000000;

  bool get _adjustment => _type == MovementType.adjustment;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  /// Cuánto cambia el stock con lo que hay escrito, o null si no es válido.
  int? get _change {
    final quantity = int.tryParse(_quantity.text);
    if (quantity == null || _validateQuantity(_quantity.text) != null) {
      return null;
    }
    return _type == MovementType.outgoing ? -quantity : quantity;
  }

  String? _validateQuantity(String? value) {
    final quantity = int.tryParse(value ?? '');
    if (quantity == null) return 'Escribe la cantidad.';
    if (_adjustment && quantity == 0) return 'No puede ser 0.';
    if (!_adjustment && quantity < 1) return 'Tiene que ser mayor que 0.';
    if (quantity.abs() > _maxQuantity) return 'Máximo $_maxQuantity.';
    return null;
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final movement = await widget.onSubmit(
        MovementInput(
          productId: _product!.id,
          type: _type,
          quantity: int.parse(_quantity.text),
          reason: _reason.text,
        ),
      );
      if (mounted) Navigator.of(context).pop(movement);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = errorMessage(
            error,
            'No se pudo registrar el movimiento.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductPicker(
            selected: _product,
            enabled: !_busy,
            onChanged: (product) => setState(() => _product = product),
          ),
          const SizedBox(height: 16),
          SegmentedButton<MovementType>(
            segments: [
              for (final type in MovementType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: _busy
                ? null
                : (selection) => setState(() => _type = selection.single),
          ),
          const SizedBox(height: 16),
          TextFormField(
            // Al cambiar a ajuste o volver, el campo cambia de reglas.
            key: ValueKey(_adjustment),
            controller: _quantity,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: _adjustment ? 'Corrección' : 'Cantidad',
              helperText: _adjustment
                  ? 'Con signo: -3 si faltan 3, 5 si sobran 5.'
                  : null,
            ),
            keyboardType: TextInputType.numberWithOptions(signed: _adjustment),
            inputFormatters: [
              if (_adjustment)
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))
              else
                FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_adjustment ? 8 : 7),
            ],
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            validator: _validateQuantity,
          ),
          if (_StockPreview.of(_product, _change) case final preview?) ...[
            const SizedBox(height: 8),
            preview,
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _reason,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: _adjustment ? 'Motivo' : 'Motivo (opcional)',
              hintText: switch (_type) {
                MovementType.incoming => 'Compra al proveedor',
                MovementType.outgoing => 'Merma, uso interno',
                MovementType.adjustment => 'Conteo de inventario',
              },
            ),
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (_adjustment && text.isEmpty) {
                return 'Escribe el motivo del ajuste.';
              }
              if (text.length > 300) return 'Máximo 300 caracteres.';
              return null;
            },
          ),
          const SizedBox(height: 24),
          if (_error case final error?) ...[
            FormError(error),
            const SizedBox(height: 16),
          ],
          FormActions(submitLabel: 'Registrar', onSubmit: _submit, busy: _busy),
        ],
      ),
    );
  }
}

/// "Stock: 40 → 37", o el aviso de que no alcanza.
class _StockPreview extends StatelessWidget {
  const _StockPreview(this.product, this.change);

  static Widget? of(Product? product, int? change) =>
      product == null || change == null ? null : _StockPreview(product, change);

  final Product product;
  final int change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final after = product.stock + change;
    return Semantics(
      liveRegion: true,
      child: Text(
        after < 0
            ? 'No alcanza: hay ${product.stock} en stock.'
            : 'Stock: ${product.stock} → $after',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: after < 0
              ? OrderStatusColors.cancelled
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
