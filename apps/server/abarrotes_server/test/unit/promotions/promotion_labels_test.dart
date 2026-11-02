import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promotions/promotion_labels.dart';
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';

void main() {
  final id = UuidValue.fromString('0190a1b2-0000-7000-8000-000000000001');
  final day = DateTime.utc(2026, 10, 1);

  Promotion promotion(
    PromotionType type, {
    int? promoPriceCents,
    int? percent,
    int? buyQuantity,
    int? payQuantity,
    Product? giftProduct,
    int? giftQuantity,
  }) => Promotion(
    productId: id,
    type: type,
    promoPriceCents: promoPriceCents,
    percent: percent,
    buyQuantity: buyQuantity,
    payQuantity: payQuantity,
    giftProductId: giftProduct?.id,
    giftProduct: giftProduct,
    giftQuantity: giftQuantity,
    startDate: day,
    endDate: day,
  );

  test('precio especial, con el precio en soles', () {
    expect(
      promotionLabel(
        promotion(PromotionType.specialPrice, promoPriceCents: 1990),
      ),
      'Precio especial S/ 19.90',
    );
  });

  test('porcentaje', () {
    expect(
      promotionLabel(promotion(PromotionType.percentOff, percent: 20)),
      '20 % menos',
    );
  });

  test('NxM', () {
    expect(
      promotionLabel(
        promotion(PromotionType.buyXPayY, buyQuantity: 2, payQuantity: 1),
      ),
      '2x1',
    );
    expect(
      promotionLabel(
        promotion(PromotionType.buyXPayY, buyQuantity: 3, payQuantity: 2),
      ),
      '3x2',
    );
  });

  test('unidad extra', () {
    expect(
      promotionLabel(
        promotion(PromotionType.extraUnit, buyQuantity: 2, percent: 50),
      ),
      '2.ª al 50 %',
    );
    expect(
      promotionLabel(
        promotion(PromotionType.extraUnit, buyQuantity: 3, percent: 25),
      ),
      '3.ª al 25 %',
    );
  });

  test('regalo, con el producto si viene incluido', () {
    final sal = Product(
      id: id,
      name: 'Sal 1 kg',
      sku: 'SAL',
      priceCents: 150,
      categoryId: id,
    );

    expect(
      promotionLabel(
        promotion(
          PromotionType.gift,
          buyQuantity: 2,
          giftProduct: sal,
          giftQuantity: 1,
        ),
      ),
      'Regalo: Sal 1 kg',
    );
    expect(
      promotionLabel(
        promotion(PromotionType.gift, buyQuantity: 2, giftQuantity: 1),
      ),
      'Regalo',
    );
  });
}
