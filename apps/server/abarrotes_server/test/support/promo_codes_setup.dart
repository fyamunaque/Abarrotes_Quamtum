import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

import 'test_tokens.dart';

/// Un día de la tienda a [offset] días de [testNow].
String testDay(int offset) => addDays(storeDay(testNow), offset);

/// Un código encendido de [startOffset] a [endOffset] días desde hoy, con
/// un 2x1 de [product].
Future<PromoCode> insertCode(
  Session session,
  Product product, {
  String code = 'VERANO-10',
  bool active = true,
  int startOffset = 0,
  int endOffset = 29,
  int? benefitDays,
  int? maxRedemptions,
  int? usesPerCustomer,
  int? minPurchaseCents,
  bool newCustomersOnly = false,
  PromoCodeEligibility eligibility = PromoCodeEligibility.everyone,
  List<String> allowedEmails = const [],
}) async {
  final promoCode = await PromoCode.db.insertRow(
    session,
    PromoCode(
      code: code,
      active: active,
      startDate: storeDayStart(testDay(startOffset)),
      endDate: storeDayStart(testDay(endOffset + 1)),
      benefitDays: benefitDays,
      maxRedemptions: maxRedemptions,
      usesPerCustomer: usesPerCustomer,
      minPurchaseCents: minPurchaseCents,
      newCustomersOnly: newCustomersOnly,
      eligibility: eligibility,
    ),
  );
  for (final email in allowedEmails) {
    await PromoCodeAllowedEmail.db.insertRow(
      session,
      PromoCodeAllowedEmail(promoCodeId: promoCode.id!, email: email),
    );
  }
  await Promotion.db.insertRow(
    session,
    Promotion(
      productId: product.id!,
      type: PromotionType.buyXPayY,
      buyQuantity: 2,
      payQuantity: 1,
      startDate: storeDayStart(testDay(startOffset)),
      endDate: storeDayStart(testDay(endOffset + 1)),
      audience: PromotionAudience.code,
      promoCodeId: promoCode.id,
    ),
  );
  return promoCode;
}

/// El arroz de S/ 4.50, con [stock] unidades.
Future<Product> insertRice(Session session, {int stock = 0}) async {
  final category = await Category.db.insertRow(
    session,
    Category(name: 'Abarrotes'),
  );
  return Product.db.insertRow(
    session,
    Product(
      name: 'Arroz Costeño 1 kg',
      sku: 'ARROZ-1',
      priceCents: 450,
      currentStock: stock,
      categoryId: category.id!,
    ),
  );
}
