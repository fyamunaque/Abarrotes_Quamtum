import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../catalog/catalog_providers.dart';
import '../../catalog/product.dart';
import '../../common/api_client.dart';
import '../../common/page_list.dart';
import '../../offers/offers_providers.dart';
import '../../router/routes.dart';
import '../../session/session_provider.dart';
import '../cart/add_to_cart.dart';
import '../offers/exclusive_offers.dart';
import '../shared/brand.dart';
import 'product_card.dart';
import 'product_grid.dart';

/// Catálogo: buscar, filtrar por categoría y los productos, página a página.
/// La categoría y lo buscado van en la URL (`?categoria=<id>&q=<texto>`), así
/// un enlace abre el catálogo ya filtrado.
///
/// Al abrirlo y al deslizar hacia abajo (pull-to-refresh) se vuelve a pedir
/// el perfil: si un admin hizo VIP a la cuenta, los precios cambian sin
/// cerrar la sesión.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, this.categoryId, this.search});

  /// null: todas las categorías.
  final String? categoryId;

  /// null: sin buscar.
  final String? search;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(sessionProvider.notifier).refreshProfile();
    });
  }

  CatalogQuery get _query {
    final text = widget.search?.trim();
    return (
      categoryId: widget.categoryId,
      search: text == null || text.isEmpty ? null : text,
    );
  }

  Future<void> _refresh() async {
    await ref.read(sessionProvider.notifier).refreshProfile();
    ref
      ..invalidate(exclusiveOffersProvider)
      ..invalidate(productListProvider(_query));
    await ref
        .read(productListProvider(_query).future)
        .catchError(
          // El error ya se muestra en la lista.
          (Object _) => const PageList<Product>([], total: 0),
        );
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
    return PublicScaffold(
      onRefresh: _refresh,
      title: switch (query.search) {
        final search? => '“$search” · Catálogo',
        null => 'Catálogo',
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Catálogo', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          _SearchField(query),
          const SizedBox(height: 12),
          _CategoryFilter(query),
          const SizedBox(height: 20),
          // Las de la cuenta VIP, arriba del catálogo completo (no de una
          // búsqueda o una categoría). Sin nada que mostrar, no aparece.
          if (query == (categoryId: null, search: null))
            const ExclusiveOffers(),
          _Products(query),
        ],
      ),
    );
  }
}

/// Buscar por nombre dentro de la categoría elegida. Enter o la lupa buscan;
/// la ✕ vuelve a mostrar todo.
class _SearchField extends StatefulWidget {
  const _SearchField(this.query);

  final CatalogQuery query;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.query.search);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(_SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La URL cambió desde afuera (atrás, un enlace): el campo la sigue.
    if (widget.query.search != oldWidget.query.search &&
        widget.query.search != _controller.text.trim()) {
      _controller.text = widget.query.search ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Para mostrar u ocultar la ✕.
  void _onTextChanged() => setState(() {});

  void _search() => context.go(
    Routes.catalogOf(widget.query.categoryId, search: _controller.text),
  );

  void _clear() {
    _controller.clear();
    context.go(Routes.catalogOf(widget.query.categoryId));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Buscar productos',
            prefixIcon: IconButton(
              tooltip: 'Buscar',
              icon: const Icon(Icons.search),
              onPressed: _search,
            ),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar la búsqueda',
                    icon: const Icon(Icons.close),
                    onPressed: _clear,
                  ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
        ),
      ),
    );
  }
}

/// "Todas" y una opción por categoría. Cambiar de categoría mantiene lo
/// buscado. Si las categorías no cargan, no se muestra: los productos se
/// pueden ver igual.
class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter(this.query);

  final CatalogQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value;
    if (categories == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todas'),
          selected: query.categoryId == null,
          onSelected: (_) =>
              context.go(Routes.catalogOf(null, search: query.search)),
        ),
        for (final category in categories)
          ChoiceChip(
            label: Text(category.name),
            selected: category.id == query.categoryId,
            onSelected: (_) =>
                context.go(Routes.catalogOf(category.id, search: query.search)),
          ),
      ],
    );
  }
}

class _Products extends ConsumerWidget {
  const _Products(this.query);

  final CatalogQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = productListProvider(query);
    return switch (ref.watch(provider)) {
      AsyncData(value: final list) when list.items.isEmpty => _Message(
        switch (query) {
          (search: final search?, categoryId: _) =>
            'No encontramos productos para “$search”.',
          (categoryId: null, search: null) => 'Todavía no hay productos.',
          _ => 'No hay productos en esta categoría.',
        },
        action: query.search == null && query.categoryId == null
            ? null
            : TextButton(
                onPressed: () => context.go(Routes.catalog),
                child: const Text('Ver todos los productos'),
              ),
      ),
      AsyncData(value: final list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductGrid(
            children: [
              for (final product in list.items)
                ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  onTap: () => context.go(Routes.product(product.id)),
                  onAdd: () => addToCart(context, ref, product),
                ),
            ],
          ),
          if (list.hasMore) ...[
            const SizedBox(height: 20),
            Center(
              child: list.loadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () => _loadMore(context, ref),
                      child: const Text('Ver más productos'),
                    ),
            ),
          ],
        ],
      ),
      AsyncError(:final error) => _Message(
        error is ApiFailure
            ? error.message
            : 'No se pudieron cargar los productos.',
        action: FilledButton.tonal(
          onPressed: () => ref.invalidate(provider),
          child: const Text('Reintentar'),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }

  Future<void> _loadMore(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(productListProvider(query).notifier).loadMore();
    } on ApiFailure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (action case final action?) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }
}
