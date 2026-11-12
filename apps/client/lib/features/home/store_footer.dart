import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../store/store_providers.dart';
import '../../theme/palette.dart';

/// El pie de la portada en escritorio: el nombre y la dirección de la tienda
/// (de `GET /store`; sin dirección cargada, solo el nombre) y los enlaces a
/// lo de todos los días.
class StoreFooter extends ConsumerWidget {
  const StoreFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeSettingsProvider).value;
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    final address = store?.address.trim() ?? '';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 12,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store?.name ?? "Neil's Food Services",
                  style: text.titleSmall,
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: text.bodyMedium?.copyWith(color: palette.inkMuted),
                  ),
                ],
              ],
            ),
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () => context.go(Routes.catalog),
                  child: const Text('Catálogo'),
                ),
                TextButton(
                  onPressed: () => context.go(Routes.promotions),
                  child: const Text('Promociones'),
                ),
                TextButton(
                  onPressed: () => context.go(Routes.myOrders),
                  child: const Text('Mis pedidos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
