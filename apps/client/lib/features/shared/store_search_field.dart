import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';

/// El buscador de la barra de la tienda, en forma de píldora: buscar lleva
/// al catálogo con lo escrito (por nombre o por código).
class StoreSearchField extends StatefulWidget {
  const StoreSearchField({super.key, this.initial});

  final String? initial;

  @override
  State<StoreSearchField> createState() => _StoreSearchFieldState();
}

class _StoreSearchFieldState extends State<StoreSearchField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final text = _controller.text.trim();
    context.go(
      text.isEmpty ? Routes.catalog : Routes.catalogOf(null, search: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pill = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(999)),
    );
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _search(),
      decoration: InputDecoration(
        hintText: 'Buscar por código o nombre del producto…',
        isDense: true,
        prefixIcon: IconButton(
          tooltip: 'Buscar',
          icon: const Icon(Icons.search),
          onPressed: _search,
        ),
        border: pill,
        enabledBorder: pill.copyWith(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}
