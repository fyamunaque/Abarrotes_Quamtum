import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/products/admin_products_providers.dart';
import '../../../catalog/product.dart';

/// Elegir un producto escribiendo parte del nombre o del SKU. Las opciones
/// vienen del servidor (también los dados de baja) cuando se deja de
/// escribir. Es un campo del formulario: sin un producto elegido de la
/// lista, no pasa la validación.
class ProductPicker extends ConsumerStatefulWidget {
  const ProductPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final Product? selected;

  /// Con el producto elegido, o null si se borró o cambió el texto.
  final ValueChanged<Product?> onChanged;

  final bool enabled;

  @override
  ConsumerState<ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<ProductPicker> {
  final _field = GlobalKey<FormFieldState<String>>();

  /// La última búsqueda pedida: las respuestas de otras se descartan.
  String _query = '';
  String? _error;

  Future<Iterable<Product>> _options(TextEditingValue value) async {
    final query = value.text.trim();
    _query = query;
    if (query.isEmpty || query == widget.selected?.name) return const [];
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (query != _query) return const [];
    try {
      final page = await ref
          .read(adminProductsRepositoryProvider)
          .list(search: query);
      if (mounted && _error != null) setState(() => _error = null);
      return query == _query ? page.items : const [];
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo buscar. Reintenta.');
      return const [];
    }
  }

  void _select(Product product) {
    widget.onChanged(product);
    // Si quedó el error de una validación anterior ("Elige un producto"),
    // se va al elegir uno.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_field.currentState case final field? when field.hasError) {
        field.validate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Autocomplete<Product>(
        initialValue: TextEditingValue(text: widget.selected?.name ?? ''),
        displayStringForOption: (product) => product.name,
        optionsBuilder: _options,
        onSelected: _select,
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            TextFormField(
              key: _field,
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              decoration: InputDecoration(
                labelText: 'Producto',
                hintText: 'Nombre o SKU',
                prefixIcon: const Icon(Icons.search),
                helperText: switch (widget.selected) {
                  final product? =>
                    '${product.sku} · stock ${product.stock}'
                        '${product.active ? '' : ' · de baja'}',
                  null => null,
                },
                errorText: _error,
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => onSubmitted(),
              onChanged: (text) {
                if (widget.selected != null && text != widget.selected!.name) {
                  widget.onChanged(null);
                }
              },
              validator: (_) => widget.selected == null
                  ? 'Elige un producto de la lista.'
                  : null,
            ),
        optionsViewBuilder: (context, onSelected, options) => _Options(
          width: constraints.maxWidth,
          options: options.toList(),
          onSelected: onSelected,
        ),
      ),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({
    required this.width,
    required this.options,
    required this.onSelected,
  });

  final double width;
  final List<Product> options;
  final ValueChanged<Product> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Material(
        elevation: 4,
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: 280),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              for (final product in options)
                ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.sku} · stock ${product.stock}'
                    '${product.active ? '' : ' · de baja'}',
                  ),
                  onTap: () => onSelected(product),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
