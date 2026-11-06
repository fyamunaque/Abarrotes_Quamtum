import 'package:flutter/material.dart';

import '../../catalog/category.dart';
import '../../catalog/product.dart';
import '../../orders/fulfillment.dart';
import '../../orders/order_status.dart';
import '../admin/home/kpi_card.dart';
import '../catalog/category_card.dart';
import '../catalog/category_header.dart';
import '../catalog/line_total_pill.dart';
import '../catalog/product_card.dart';
import '../catalog/product_grid.dart';
import '../catalog/product_tile.dart';
import '../catalog/promo_ribbon.dart';
import '../catalog/stock_note.dart';
import '../home/promotions_banner.dart';
import '../orders/order_tracker.dart';
import '../shared/brand.dart';
import '../shared/brand_hero.dart';
import '../shared/cart_bar.dart';

/// Vitrina: los componentes con datos de ejemplo, para verlos y revisarlos
/// antes de que tengan pantallas con datos reales. Solo existe en debug (ver
/// router.dart).
class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  var _status = OrderStatus.pendingConfirmation;

  static const _offer = (
    type: 'buyXPayY',
    label: '2x1',
    title: null,
    description: '2x1 en este producto',
  );

  static const _products = [
    Product(
      id: 'jamonada',
      sku: '3580',
      name: 'Jamonada especial',
      priceCents: 1320,
      stock: 40,
      offers: [_offer],
    ),
    Product(
      id: 'aceite',
      sku: '1201',
      name: 'Aceite vegetal 1 L',
      priceCents: 1090,
      promoPriceCents: 890,
      stock: 4,
    ),
    Product(
      id: 'leche',
      sku: '2229',
      name: 'Leche evaporada entera, paquete de 6 latas de 400 g',
      priceCents: 2350,
      stock: 8,
    ),
    Product(
      id: 'azucar',
      sku: '0450',
      name: 'Azúcar rubia 1 kg',
      priceCents: 450,
      stock: 0,
    ),
  ];

  static const _category = Category(id: 'cat-embutidos', name: 'Embutidos');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 12),
      child: Text(title, style: text.titleLarge),
    );
    return PublicScaffold(
      title: 'Vitrina',
      maxWidth: 1120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Vitrina', style: text.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Componentes con datos de ejemplo. Esta página solo existe en '
            'los builds de debug. Agregar suma al carrito de verdad.',
            style: text.bodyMedium,
          ),
          section('Encabezado de la portada y sellos'),
          const BrandHero(
            titleStart: 'Tu negocio siempre abastecido ',
            titleAccent: "con Neil's.",
            body: 'Insumos gastronómicos de calidad.',
            actions: [],
          ),
          const SizedBox(height: 20),
          const TrustBadges(),
          section('Banda de promociones'),
          const PromotionsBanner(),
          section('Categorías'),
          Row(
            children: [
              SizedBox(
                width: 180,
                child: CategoryCard(category: _category, onTap: () {}),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const CategoryHeader(category: _category),
          section('Producto en lista (teléfono)'),
          for (final product in _products) ...[
            ProductTile(product: product),
            const SizedBox(height: 12),
          ],
          section('Tarjetas de producto (escritorio)'),
          ProductGrid(
            children: [
              for (final product in _products) ProductCard(product: product),
            ],
          ),
          section('Cinta, stock y total'),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const PromoRibbon([_offer]),
              for (final product in _products) StockNote(product),
              const LineTotalPill(1320),
            ],
          ),
          section('Barra del carrito'),
          CartBar(
            label: 'Continuar',
            count: 12,
            totalCents: 29984,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          const CartBar(
            label: 'Confirmar pedido',
            count: 3,
            totalCents: 4980,
            onPressed: null,
          ),
          section('Indicador del panel'),
          const SizedBox(
            width: 280,
            child: KpiCard(
              icon: Icons.point_of_sale_outlined,
              title: 'Ventas de hoy',
              value: 'S/ 1319.47',
              detail: '10 pedidos',
            ),
          ),
          section('Seguimiento de pedido'),
          Text(
            'Elige un estado para ver cómo se llena la línea.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          OrderTracker(
            status: _status,
            fulfillmentType:
                FulfillmentType.delivery.steps.contains(_status) ||
                    _status == OrderStatus.cancelled
                ? FulfillmentType.delivery
                : FulfillmentType.pickup,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in OrderStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: status == _status,
                  onSelected: (_) => setState(() => _status = status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
