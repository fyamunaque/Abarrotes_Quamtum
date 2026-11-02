import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promotions/promotion_engine.dart';
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';

void main() {
  UuidValue id(int n) => UuidValue.fromString(
    '0190a1b2-0000-7000-8000-${n.toString().padLeft(12, '0')}',
  );
  final arroz = id(1);
  final sal = id(2);
  final day = DateTime.utc(2026, 10, 1);
  var next = 100;

  Promotion promo(
    UuidValue productId,
    PromotionType type, {
    int? price,
    int? percent,
    int? buy,
    int? pay,
    int? giftQuantity,
  }) => Promotion(
    id: id(next++),
    productId: productId,
    type: type,
    promoPriceCents: price,
    percent: percent,
    buyQuantity: buy,
    payQuantity: pay,
    giftProductId: type == PromotionType.gift ? sal : null,
    giftProduct: type == PromotionType.gift
        ? Product(
            id: sal,
            name: 'Sal 1 kg',
            sku: 'SAL',
            priceCents: 150,
            categoryId: id(9),
          )
        : null,
    giftQuantity: giftQuantity,
    startDate: day,
    endDate: day,
  );

  PricingLine line(UuidValue productId, int price, int quantity) => (
    productId: productId,
    name: productId == arroz ? 'Arroz' : 'Aceite',
    listUnitPriceCents: price,
    quantity: quantity,
  );

  GiftProduct salGift({int stock = 10, bool active = true}) => (
    id: sal,
    name: 'Sal 1 kg',
    priceCents: 150,
    active: active,
    stock: stock,
  );

  PricedLine only(PricedCart cart) => cart.lines.where((l) => !l.isGift).single;

  List<String> labels(PricedLine line) => [
    for (final p in line.promotions) p.label,
  ];

  test('el ejemplo de la spec', () {
    final cart = priceCart(
      [line(arroz, 2490, 5)],
      {
        arroz: [
          promo(arroz, PromotionType.specialPrice, price: 2290),
          promo(arroz, PromotionType.percentOff, percent: 10),
          promo(arroz, PromotionType.buyXPayY, buy: 2, pay: 1),
        ],
      },
      {},
    );

    final arrozLine = only(cart);
    expect(arrozLine.unitPriceCents, 2061);
    expect(arrozLine.lineTotalCents, 6183);
    expect(cart.subtotalCents, 12450);
    expect(cart.discountCents, 6267);
    expect(cart.totalCents, 6183);
    expect(labels(arrozLine), [
      'Precio especial S/ 22.90',
      '10 % menos',
      '2x1',
    ]);
    // Lo que ahorró cada una suma el descuento.
    expect(
      arrozLine.promotions.fold<int>(0, (sum, p) => sum + p.savedCents),
      6267,
    );
  });

  test('dos precios especiales: el más bajo', () {
    final cart = priceCart(
      [line(arroz, 2490, 1)],
      {
        arroz: [
          promo(arroz, PromotionType.specialPrice, price: 2290),
          promo(arroz, PromotionType.specialPrice, price: 1990),
        ],
      },
      {},
    );

    expect(only(cart).unitPriceCents, 1990);
    expect(labels(only(cart)), ['Precio especial S/ 19.90']);
  });

  test('porcentajes en cadena, redondeo por paso', () {
    final cart = priceCart(
      [line(arroz, 999, 1)],
      {
        arroz: [
          promo(arroz, PromotionType.percentOff, percent: 20),
          promo(arroz, PromotionType.percentOff, percent: 10),
        ],
      },
      {},
    );

    expect(only(cart).unitPriceCents, 719);
  });

  test('cantidad que no completa un grupo', () {
    final single = priceCart(
      [line(arroz, 1000, 1)],
      {
        arroz: [promo(arroz, PromotionType.buyXPayY, buy: 2, pay: 1)],
      },
      {},
    );
    expect(only(single).lineTotalCents, 1000);
    expect(only(single).promotions, isEmpty);

    final three = priceCart(
      [line(arroz, 1000, 3)],
      {
        arroz: [promo(arroz, PromotionType.extraUnit, buy: 2, percent: 50)],
      },
      {},
    );
    expect(only(three).lineTotalCents, 2500);
  });

  test('NxM antes que la unidad extra y cada unidad una vez', () {
    final cart = priceCart(
      [line(arroz, 1000, 4)],
      {
        arroz: [
          promo(arroz, PromotionType.extraUnit, buy: 2, percent: 50),
          promo(arroz, PromotionType.buyXPayY, buy: 2, pay: 1),
        ],
      },
      {},
    );

    expect(only(cart).lineTotalCents, 2000);
    expect(labels(only(cart)), ['2x1']);
  });

  test('entre dos NxM gana el que más ahorra', () {
    Map<UuidValue, List<Promotion>> both() => {
      arroz: [
        promo(arroz, PromotionType.buyXPayY, buy: 3, pay: 2),
        promo(arroz, PromotionType.buyXPayY, buy: 2, pay: 1),
      ],
    };

    expect(
      only(priceCart([line(arroz, 1000, 6)], both(), {})).lineTotalCents,
      3000,
    );
    expect(
      only(priceCart([line(arroz, 1000, 5)], both(), {})).lineTotalCents,
      3000,
    );
  });

  test('unidad extra', () {
    final cart = priceCart(
      [line(arroz, 1000, 5)],
      {
        arroz: [promo(arroz, PromotionType.extraUnit, buy: 2, percent: 50)],
      },
      {},
    );

    expect(only(cart).lineTotalCents, 4000);
    expect(labels(only(cart)), ['2.ª al 50 %']);
  });

  test('regalo', () {
    final cart = priceCart(
      [line(arroz, 1000, 5)],
      {
        arroz: [
          promo(arroz, PromotionType.gift, buy: 2, giftQuantity: 1),
        ],
      },
      {sal: salGift()},
    );

    final gift = cart.lines.singleWhere((l) => l.isGift);
    expect(gift.productId, sal);
    expect(gift.quantity, 2);
    expect(gift.unitPriceCents, 0);
    expect(gift.lineTotalCents, 0);
    expect(gift.listUnitPriceCents, 150);
    expect(labels(gift), ['Regalo: Sal 1 kg']);
    expect(gift.promotions.single.savedCents, 300);
    expect(cart.totalCents, 5000);
    expect(cart.notices, isEmpty);
  });

  test('regalo sin stock suficiente', () {
    Map<UuidValue, List<Promotion>> gift() => {
      arroz: [promo(arroz, PromotionType.gift, buy: 2, giftQuantity: 1)],
    };

    final short = priceCart(
      [line(arroz, 1000, 5)],
      gift(),
      {
        sal: salGift(stock: 1),
      },
    );
    expect(short.lines.singleWhere((l) => l.isGift).quantity, 1);
    expect(short.notices, ['Solo quedaba 1 de Sal 1 kg para regalo']);

    for (final unavailable in [
      {sal: salGift(stock: 0)},
      {sal: salGift(active: false)},
      <UuidValue, GiftProduct>{},
    ]) {
      final cart = priceCart([line(arroz, 1000, 5)], gift(), unavailable);
      expect(cart.lines.where((l) => l.isGift), isEmpty);
      expect(cart.notices, ['Sal 1 kg ya no está disponible para regalo']);
    }
  });

  test('el regalo cuenta lo que ya se compra del mismo producto', () {
    final cart = priceCart(
      [line(arroz, 1000, 2), line(sal, 150, 3)],
      {
        arroz: [promo(arroz, PromotionType.gift, buy: 2, giftQuantity: 1)],
      },
      {sal: salGift(stock: 3)},
    );

    expect(cart.lines.where((l) => l.isGift), isEmpty);
    expect(cart.notices, ['Sal 1 kg ya no está disponible para regalo']);
  });

  test('los regalos no entran en otras promociones', () {
    final cart = priceCart(
      [line(arroz, 1000, 4)],
      {
        arroz: [promo(arroz, PromotionType.gift, buy: 2, giftQuantity: 1)],
        sal: [promo(sal, PromotionType.buyXPayY, buy: 2, pay: 1)],
      },
      {sal: salGift()},
    );

    final gift = cart.lines.singleWhere((l) => l.isGift);
    expect(gift.quantity, 2);
    expect(labels(gift), ['Regalo: Sal 1 kg']);
  });

  test('sin promociones', () {
    final cart = priceCart([line(arroz, 450, 3)], {}, {});

    expect(cart.totalCents, 1350);
    expect(cart.subtotalCents, 1350);
    expect(cart.discountCents, 0);
    expect(only(cart).promotions, isEmpty);
    expect(cart.appliedPromotionIds, isEmpty);
  });

  test('unitPriceFor: solo los pasos 1 y 2', () {
    expect(
      unitPriceFor(2490, [
        promo(arroz, PromotionType.specialPrice, price: 2290),
        promo(arroz, PromotionType.percentOff, percent: 10),
        promo(arroz, PromotionType.buyXPayY, buy: 2, pay: 1),
      ]),
      2061,
    );
    expect(unitPriceFor(2490, []), 2490);
  });
}
