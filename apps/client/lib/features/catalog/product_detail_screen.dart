import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/cart_provider.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/category.dart';
import '../../catalog/product.dart';
import '../../common/api_client.dart';
import '../../router/routes.dart';
import '../../theme/palette.dart';
import '../shared/account.dart';
import '../shared/brand.dart';
import '../shared/cart_button.dart';
import 'offer_badges.dart';
import 'price_tag.dart';
import 'product_photo.dart';
import 'product_strip.dart';
import 'product_tile.dart';
import 'promo_tag.dart';
import 'stock_note.dart';

/// El detalle de un producto: foto, precio, descripción y agregar al carrito
/// eligiendo la cantidad. Debajo, "Más de" su categoría: otros productos de
/// la misma categoría.
///
/// En el teléfono, la foto a todo el ancho con "Volver" y el carrito flotando
/// encima (sin la barra de la tienda). En escritorio, la ruta "Catálogo ›
/// categoría" arriba y la foto y los datos en dos columnas.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId, this.initial});

  final String productId;

  /// El producto como lo mostraba la lista que lo abrió: se ve de entrada
  /// (así su foto viaja desde la fila o la tarjeta) mientras llega el
  /// actualizado.
  final Product? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = productProvider(productId);
    final state = ref.watch(provider);
    final compact = MediaQuery.sizeOf(context).width < AccountActions.wideFrom;
    final shown = switch (state) {
      AsyncData(value: final product) => product,
      AsyncLoading() => initial,
      _ => null,
    };
    final Widget? problem = switch (state) {
      AsyncData() => null,
      // 404: no existe o se dio de baja; 400: el id del enlace no es
      // válido. Para la persona es lo mismo.
      AsyncError(error: ApiFailure(status: 400 || 404)) => _Unavailable(
        onCatalog: () => context.go(Routes.catalog),
      ),
      AsyncError(:final error) => Column(
        children: [
          Text(
            error is ApiFailure
                ? error.message
                : 'No se pudo cargar el producto.',
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => ref.invalidate(provider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
      _ when initial != null => null,
      _ => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
    // "Más de": cuando ya llegó el producto actualizado.
    final related = switch (state) {
      AsyncData(value: Product(:final category?, :final id)) => _Related(
        category: category,
        productId: id,
      ),
      _ => null,
    };
    return PublicScaffold(
      // El nombre del producto, cuando ya cargó.
      title: shown?.name ?? 'Producto',
      phoneBar: false,
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (shown != null && problem == null)
                  _PhoneDetail(shown)
                else ...[
                  _FloatingBar(category: shown?.category),
                  Padding(padding: const EdgeInsets.all(16), child: problem),
                ],
                if (related != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: related,
                  ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Breadcrumb(category: shown?.category),
                const SizedBox(height: 12),
                if (shown != null && problem == null)
                  _DesktopDetail(shown)
                else
                  ?problem,
                ?related,
              ],
            ),
    );
  }
}

/// Volver: a donde se venía si se puede; si no, al catálogo de la categoría
/// del producto (o al catálogo).
void _back(BuildContext context, Category? category) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    Navigator.maybePop(context);
  } else if (router.canPop()) {
    router.pop();
  } else {
    router.go(Routes.catalogOf(category?.id));
  }
}

/// La foto del producto: el mismo [Hero] que la fila y la tarjeta.
Widget _photo(Product product) => AspectRatio(
  aspectRatio: 4 / 3,
  child: Hero(
    tag: productHeroTag(product),
    child: ProductPhoto(
      product.imageUrl,
      name: product.name,
      colorKey: product.category?.id,
      initialSize: 72,
    ),
  ),
);

/// La ruta de escritorio: "Catálogo › Embutidos", cada parte un enlace.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({this.category});

  final Category? category;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('ruta'),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: () => context.go(Routes.catalog),
          child: const Text('Catálogo'),
        ),
        if (category case final category?) ...[
          ExcludeSemantics(
            child: Icon(
              Icons.chevron_right,
              size: 18,
              color: context.palette.inkMuted,
            ),
          ),
          TextButton(
            onPressed: () => context.go(Routes.catalogOf(category.id)),
            child: Text(category.name),
          ),
        ],
      ],
    );
  }
}

/// Un botón redondo sobre la foto: claro, con borde fino, para que se vea
/// sobre cualquier foto.
class _Floating extends StatelessWidget {
  const _Floating({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        shape: BoxShape.circle,
        border: Border.all(color: palette.line),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: palette.ink),
        child: child,
      ),
    );
  }
}

/// "Volver" y el carrito, sobre la foto (o arriba de todo, sin foto).
class _FloatingBar extends StatelessWidget {
  const _FloatingBar({this.category});

  final Category? category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _Floating(
            child: IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _back(context, category),
            ),
          ),
          const Spacer(),
          const _Floating(child: CartButton()),
        ],
      ),
    );
  }
}

/// El teléfono: la foto a todo el ancho con [_FloatingBar] encima, y debajo
/// los datos.
class _PhoneDetail extends StatelessWidget {
  const _PhoneDetail(this.product);

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            _photo(product),
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: _FloatingBar(category: product.category),
            ),
          ],
        ),
        Padding(padding: const EdgeInsets.all(16), child: _Info(product)),
      ],
    );
  }
}

/// Escritorio: la foto y los datos en dos columnas.
class _DesktopDetail extends StatelessWidget {
  const _DesktopDetail(this.product);

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _photo(product),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(child: _Info(product)),
      ],
    );
  }
}

/// El código y el nombre, el precio, el stock, las promociones, la
/// descripción y la fila para agregar ("Agregar", o "Editar" si ya está en el
/// carrito).
class _Info extends ConsumerWidget {
  const _Info(this.product);

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inCart = ref.watch(
      cartProvider.select((cart) => cart.quantityOf(product.id)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.category case final category?)
          Text(
            category.name,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Text(productTitle(product), style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        PriceTag(product, fontSize: 30),
        const SizedBox(height: 6),
        // En el detalle hay lugar: la etiqueta y la disponibilidad.
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [PromoTag(product.offers), StockNote(product)],
        ),
        if (product.offers.isNotEmpty) ...[
          const SizedBox(height: 12),
          // La explicación de la promoción, en su recuadro.
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.palette.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: OfferDescriptions(product.offers),
            ),
          ),
        ],
        if (product.description case final description?) ...[
          const SizedBox(height: 16),
          Text(description, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 24),
        ProductQuantityActions(product: product),
        if (inCart > 0) ...[
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Tienes $inCart en el carrito.'),
              TextButton(
                onPressed: () => context.go(Routes.cart),
                child: const Text('Ver carrito'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Más de Lácteos": otros productos de la categoría. Mientras cargan, si
/// fallan o si no hay otros, no ocupa lugar.
class _Related extends ConsumerWidget {
  const _Related({required this.category, required this.productId});

  final Category category;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref
        .watch(
          relatedProductsProvider((
            categoryId: category.id,
            productId: productId,
          )),
        )
        .value;
    if (products == null || products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: ProductStrip(title: 'Más de ${category.name}', products: products),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onCatalog});

  final VoidCallback onCatalog;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Text(
              'Este producto ya no está disponible.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCatalog,
              child: const Text('Ver el catálogo'),
            ),
          ],
        ),
      ),
    );
  }
}
