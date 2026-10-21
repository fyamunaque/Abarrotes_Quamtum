import 'package:flutter/material.dart';

import '../../../orders/fulfillment.dart';

/// Cómo se entrega un pedido, con su ícono y en texto: "Domicilio" o
/// "Recojo".
class FulfillmentBadge extends StatelessWidget {
  const FulfillmentBadge(this.type, {super.key});

  final FulfillmentType type;

  static String label(FulfillmentType type) => switch (type) {
    FulfillmentType.delivery => 'Domicilio',
    FulfillmentType.pickup => 'Recojo',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          switch (type) {
            FulfillmentType.delivery => Icons.local_shipping_outlined,
            FulfillmentType.pickup => Icons.storefront_outlined,
          },
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(label(type))),
      ],
    );
  }
}
