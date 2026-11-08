import 'package:flutter_test/flutter_test.dart';
import 'package:neils/catalog/product.dart';

/// Lo que costarían N unidades, con las promociones por cantidad, como las
/// cobra el servidor (promotion_engine.dart).
void main() {
  Product product({
    int priceCents = 450,
    int? promoPriceCents,
    List<QuantityDeal> deals = const [],
  }) => Product(
    id: 'p',
    name: 'Jamonada',
    priceCents: priceCents,
    promoPriceCents: promoPriceCents,
    stock: 50,
    quantityDeals: deals,
  );

  const twoForOne = (
    type: 'buyXPayY',
    buyQuantity: 2,
    payQuantity: 1,
    percent: null,
  );
  const secondHalf = (
    type: 'extraUnit',
    buyQuantity: 2,
    payQuantity: null,
    percent: 50,
  );

  test('sin promociones por cantidad, el precio por las unidades', () {
    expect(product().totalFor(3), 1350);
    expect(product(promoPriceCents: 400).totalFor(3), 1200);
  });

  test('un 2x1 cobra una de cada dos', () {
    final p = product(deals: const [twoForOne]);
    expect(p.totalFor(1), 450);
    expect(p.totalFor(2), 450);
    expect(p.totalFor(3), 900);
  });

  test('la 2.ª al 50 % descuenta la mitad de cada segunda', () {
    final p = product(deals: const [secondHalf]);
    expect(p.totalFor(2), 675);
    expect(p.totalFor(3), 1125);
  });

  test('sobre el precio especial, como el servidor', () {
    expect(
      product(promoPriceCents: 400, deals: const [twoForOne]).totalFor(2),
      400,
    );
  });

  test('lee las promociones por cantidad del JSON', () {
    final p = Product.fromJson({
      'id': 'p-1',
      'name': 'Jamonada',
      'price': '4.5',
      'currentStock': 20,
      'promotion': null,
      'promotions': [
        {
          'id': 'pr-1',
          'type': 'buyXPayY',
          'label': '2x1',
          'audience': 'everyone',
          'buyQuantity': 2,
          'payQuantity': 1,
        },
        {
          'id': 'pr-2',
          'type': 'extraUnit',
          'label': '3.ª al 25 %',
          'audience': 'everyone',
          'buyQuantity': 3,
          'percent': 25,
        },
      ],
    });

    expect(p.quantityDeals, [
      (type: 'buyXPayY', buyQuantity: 2, payQuantity: 1, percent: null),
      (type: 'extraUnit', buyQuantity: 3, payQuantity: null, percent: 25),
    ]);
  });
}
