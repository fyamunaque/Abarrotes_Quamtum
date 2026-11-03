import 'dart:async';
import 'dart:convert';

import 'package:neils/admin/emails.dart';
import 'package:neils/admin/inventory/inventory_providers.dart';
import 'package:neils/admin/inventory/inventory_repository.dart';
import 'package:neils/admin/inventory/movement.dart';
import 'package:neils/admin/orders/admin_order.dart';
import 'package:neils/admin/orders/admin_orders_repository.dart';
import 'package:neils/admin/products/admin_products_repository.dart';
import 'package:neils/admin/products/photo_picker.dart';
import 'package:neils/admin/products/product_input.dart';
import 'package:neils/admin/promo_codes/promo_code.dart';
import 'package:neils/admin/promo_codes/promo_codes_repository.dart';
import 'package:neils/admin/promotions/promotion.dart';
import 'package:neils/admin/promotions/promotions_repository.dart';
import 'package:neils/admin/staff/staff.dart';
import 'package:neils/admin/staff/staff_repository.dart';
import 'package:neils/admin/stats/stats.dart';
import 'package:neils/admin/stats/stats_repository.dart';
import 'package:neils/admin/vip/vip_customer.dart';
import 'package:neils/admin/vip/vip_repository.dart';
import 'package:neils/auth/auth_repository.dart';
import 'package:neils/catalog/catalog_repository.dart';
import 'package:neils/catalog/category.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/common/page_list.dart';
import 'package:neils/legal/legal_texts.dart' as legal;
import 'package:neils/offers/offer.dart';
import 'package:neils/offers/offers_repository.dart';
import 'package:neils/orders/fulfillment.dart';
import 'package:neils/orders/order.dart';
import 'package:neils/orders/order_filter.dart';
import 'package:neils/orders/order_repository.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/orders/quote.dart';
import 'package:neils/promo_codes/my_promo_code.dart';
import 'package:neils/promo_codes/my_promo_codes_repository.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/staff_permission.dart';
import 'package:neils/store/store_repository.dart';
import 'package:neils/store/store_settings.dart';
import 'package:neils/users/user_repository.dart';

import 'support.dart';

const groceries = Category(id: 'cat-abarrotes', name: 'Abarrotes');
const dairy = Category(id: 'cat-lacteos', name: 'Lácteos');

const rice = Product(
  id: 'arroz',
  name: 'Arroz extra 5 kg',
  priceCents: 2490,
  stock: 40,
  category: groceries,
  description: 'Grano largo, bolsa de 5 kg.',
);
const oil = Product(
  id: 'aceite',
  name: 'Aceite vegetal 1 L',
  priceCents: 1090,
  promoPriceCents: 890,
  stock: 3,
  category: groceries,
);
const milk = Product(
  id: 'leche',
  name: 'Leche evaporada 400 g',
  priceCents: 420,
  stock: 48,
  category: dairy,
);

/// A qué estados puede pasar un pedido, como lo calcula el servidor con el
/// flujo de su tipo de entrega (`FulfillmentFlow` en apps/server): el paso
/// siguiente y, mientras no esté entregado, cancelado. La app no lo calcula:
/// lo lee de `allowedNextStatuses`; esto es para el servidor simulado.
List<OrderStatus> allowedNextFor(FulfillmentType type, OrderStatus status) {
  final steps = type.steps;
  final i = steps.indexOf(status);
  if (i < 0 || i == steps.length - 1) return const [];
  return [steps[i + 1], OrderStatus.cancelled];
}

/// Los datos de la tienda en memoria. Con [failure], `settings` falla.
class FakeStoreRepository implements StoreRepository {
  FakeStoreRepository([this.store = sampleStore]);

  StoreSettings store;
  ApiFailure? failure;

  /// Si no es null, `update` falla con esto.
  ApiFailure? updateFailure;

  /// Lo que se guardó, en orden.
  final saved = <StoreSettings>[];

  @override
  Future<StoreSettings> settings() async {
    if (failure case final failure?) throw failure;
    return store;
  }

  @override
  Future<StoreSettings> update(StoreSettings settings) async {
    if (updateFailure case final failure?) throw failure;
    saved.add(settings);
    return store = settings;
  }
}

/// La tienda de los tests.
const sampleStore = StoreSettings(
  name: "Neil's Food Services",
  address: 'Av. Arequipa 1234, Lince',
  reference: 'Frente al parque',
  openingHours: 'Lun a sáb de 8 a 20 h',
  pickupInstructions: 'Muestra tu código en caja.',
);

/// Los pedidos del panel en memoria. Valida el cambio de estado como el
/// servidor (`allowedNextStatuses` y el código al recoger), con sus
/// mensajes.
class FakeAdminOrdersRepository implements AdminOrdersRepository {
  FakeAdminOrdersRepository(this.orders, {this.pageSize = 20});

  final List<AdminOrder> orders;
  final int pageSize;

  /// Si no es null, el próximo cambio de estado falla con esto (p. ej. otra
  /// persona ya lo cambió).
  ApiFailure? failNext;

  final changes = <(String, OrderStatus)>[];

  /// Lo que se mandó en cada cambio de estado: el código de recojo, el de
  /// entrega y el motivo para entregar sin él.
  final pickupCodes = <String?>[];
  final deliveryCodes = <String?>[];
  final withoutCodeReasons = <String?>[];

  /// El código de entrega de los pedidos que lo tienen: el que el cliente
  /// le da al repartidor (el panel no lo recibe).
  static const deliveryCode = 'P4R9TW';

  /// Cuántas veces se pidió una página.
  int listCalls = 0;

  /// Si no es null, pedir una página falla con esto.
  ApiFailure? failList;

  @override
  Future<PageList<AdminOrder>> list({
    int page = 1,
    OrderStatus? status,
    FulfillmentType? fulfillmentType,
    int? number,
    int? limit,
  }) async {
    listCalls++;
    if (failList case final failure?) throw failure;
    final size = limit ?? pageSize;
    final matching = [
      for (final order in orders)
        if ((status == null || order.order.status == status) &&
            (fulfillmentType == null ||
                order.order.fulfillmentType == fulfillmentType) &&
            (number == null || order.order.number == number))
          order,
    ];
    return PageList(
      matching.skip((page - 1) * size).take(size).toList(),
      total: matching.length,
      page: page,
      pageSize: size,
    );
  }

  @override
  Future<AdminOrder> changeStatus(
    String id,
    OrderStatus status, {
    String? pickupCode,
    String? deliveryCode,
    String? withoutCodeReason,
  }) async {
    pickupCodes.add(pickupCode);
    deliveryCodes.add(deliveryCode);
    withoutCodeReasons.add(withoutCodeReason);
    if (failNext case final failure?) {
      failNext = null;
      throw failure;
    }
    final i = orders.indexWhere((order) => order.id == id);
    final current = orders[i].order;
    if (!current.allowedNextStatuses.contains(status)) {
      throw ApiFailure(
        'Un pedido ${current.statusLabel.toLowerCase()} no puede '
        'pasar a ${current.fulfillmentType.labelOf(status).toLowerCase()}',
        status: 400,
      );
    }
    if (current.status == OrderStatus.readyForPickup &&
        status == OrderStatus.delivered &&
        pickupCode?.replaceAll(' ', '').toUpperCase() != current.pickupCode) {
      throw const ApiFailure('El código de recojo no coincide', status: 400);
    }
    if (current.status == OrderStatus.outForDelivery &&
        status == OrderStatus.delivered &&
        current.hasDeliveryCode &&
        withoutCodeReason == null &&
        deliveryCode?.replaceAll(' ', '').toUpperCase() !=
            FakeAdminOrdersRepository.deliveryCode) {
      throw const ApiFailure('El código de entrega no coincide', status: 400);
    }
    changes.add((id, status));
    return orders[i] = withStatus(
      orders[i],
      status,
      withoutCodeReason: withoutCodeReason,
    );
  }

  static AdminOrder withStatus(
    AdminOrder order,
    OrderStatus status, {
    String? withoutCodeReason,
  }) => AdminOrder(
    order: Order(
      id: order.order.id,
      number: order.order.number,
      status: status,
      fulfillmentType: order.order.fulfillmentType,
      totalCents: order.order.totalCents,
      deliveryAddress: order.order.deliveryAddress,
      pickupCode: order.order.pickupCode,
      hasDeliveryCode: order.order.hasDeliveryCode,
      deliveredWithoutCodeReason:
          withoutCodeReason ?? order.order.deliveredWithoutCodeReason,
      readyForPickupAt: status == OrderStatus.readyForPickup
          ? DateTime.now()
          : order.order.readyForPickupAt,
      createdAt: order.order.createdAt,
      lines: order.order.lines,
      allowedNextStatuses: allowedNextFor(order.order.fulfillmentType, status),
    ),
    customer: order.customer,
  );
}

/// Un pedido del panel para los tests: a domicilio (con [hasDeliveryCode],
/// de los que se entregan con el código del cliente) o, con [pickupCode], de
/// recojo en tienda. Con los estados siguientes que mandaría el servidor.
/// Las líneas de un pedido con un 2x1 en el arroz y una sal de regalo:
/// subtotal S/ 49.80, descuentos S/ 24.90 y total S/ 24.90.
const promotionOrderLines = [
  OrderLine(
    productId: 'arroz',
    name: 'Arroz extra 5 kg',
    quantity: 2,
    listUnitPriceCents: 2490,
    unitPriceCents: 2490,
    lineTotalCents: 2490,
    promotions: [(label: '2x1', savedCents: 2490)],
  ),
  OrderLine(
    productId: 'sal',
    name: 'Sal 1 kg',
    quantity: 1,
    listUnitPriceCents: 150,
    unitPriceCents: 0,
    lineTotalCents: 0,
    isGift: true,
    promotions: [(label: 'Regalo: Sal 1 kg', savedCents: 150)],
  ),
];

AdminOrder adminOrder(
  String id,
  OrderStatus status, {
  String customer = 'Ana Quispe',
  int day = 4,
  String? pickupCode,
  bool hasDeliveryCode = false,
  DateTime? readyForPickupAt,
  int? number,

  /// Con otras líneas (las de [promotionOrderLines]): el total es lo que
  /// suman y el subtotal, el total más [discountCents].
  List<OrderLine>? lines,
  int discountCents = 0,
}) => AdminOrder(
  order: Order(
    id: id,
    number: number,
    status: status,
    readyForPickupAt: readyForPickupAt,
    fulfillmentType: pickupCode == null
        ? FulfillmentType.delivery
        : FulfillmentType.pickup,
    allowedNextStatuses: allowedNextFor(
      pickupCode == null ? FulfillmentType.delivery : FulfillmentType.pickup,
      status,
    ),
    pickupCode: pickupCode,
    hasDeliveryCode: hasDeliveryCode,
    totalCents: switch (lines) {
      final lines? => lines.fold(0, (sum, line) => sum + line.lineTotalCents),
      null => 3380,
    },
    subtotalCents: switch (lines) {
      final lines? =>
        lines.fold(0, (sum, line) => sum + line.lineTotalCents) + discountCents,
      null => null,
    },
    discountCents: discountCents,
    deliveryAddress: pickupCode == null ? 'Av. Arequipa 123, Lince' : null,
    createdAt: DateTime.utc(2026, 10, day, 15, 30),
    lines:
        lines ??
        const [
          OrderLine(
            productId: 'arroz',
            name: 'Arroz extra 5 kg',
            quantity: 1,
            unitPriceCents: 2490,
          ),
          OrderLine(
            productId: 'aceite',
            name: 'Aceite vegetal 1 L',
            quantity: 1,
            unitPriceCents: 890,
          ),
        ],
  ),
  customer: OrderCustomer(
    name: customer,
    email: 'ana@tienda.pe',
    phone: '987654321',
    dni: '45678912',
  ),
);

/// Un PNG de 1 × 1, para que la vista previa de una foto elegida tenga una
/// imagen de verdad.
final samplePhoto = (
  bytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
  contentType: 'image/png',
);

/// Elegir una foto sin el diálogo del sistema: devuelve [photo] (null es
/// cancelar) y anota de dónde se pidió.
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker({this.canUseCamera = false});

  @override
  final bool canUseCamera;

  PickedPhoto? photo = samplePhoto;
  final sources = <PhotoSource>[];

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    sources.add(source);
    return photo;
  }
}

/// Los productos del panel en memoria, por nombre. Responde 409 a un SKU que
/// ya existe, como el servidor.
class FakeAdminProductsRepository implements AdminProductsRepository {
  FakeAdminProductsRepository(List<Product> products, {this.pageSize = 20})
    : products = [...products];

  final List<Product> products;
  final int pageSize;

  /// Lo que se mandó al crear (`null` como id) o editar, en orden.
  final sent = <(String?, ProductInput)>[];

  /// Si no es null, la próxima escritura falla con esto.
  ApiFailure? failNext;

  @override
  Future<PageList<Product>> list({
    int page = 1,
    String? search,
    String? categoryId,
  }) async {
    final query = search?.trim().toLowerCase() ?? '';
    final matching = [
      for (final product in products)
        if ((query.isEmpty ||
                product.name.toLowerCase().contains(query) ||
                product.sku.toLowerCase().contains(query)) &&
            (categoryId == null || product.category?.id == categoryId))
          product,
    ]..sort((a, b) => a.name.compareTo(b.name));
    return PageList(
      matching.skip((page - 1) * pageSize).take(pageSize).toList(),
      total: matching.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Product> create(ProductInput input) async {
    _check(null, input);
    final product = _apply(
      Product(
        id: 'nuevo-${products.length + 1}',
        name: '',
        priceCents: 0,
        stock: input.initialStock,
      ),
      input,
    );
    products.add(product);
    return product;
  }

  @override
  Future<Product> update(String id, ProductInput input) async {
    _check(id, input);
    final i = products.indexWhere((product) => product.id == id);
    return products[i] = _apply(products[i], input);
  }

  @override
  Future<Product> deactivate(String id) async {
    if (failNext case final failure?) {
      failNext = null;
      throw failure;
    }
    final i = products.indexWhere((product) => product.id == id);
    final product = products[i];
    return products[i] = _apply(
      product,
      ProductInput(
        name: product.name,
        sku: product.sku,
        priceCents: product.priceCents,
        categoryId: product.category!.id,
        minStock: product.minStock,
        active: false,
        description: product.description,
        imageUrl: product.imageUrl,
        expirationDate: product.expirationDate,
      ),
    );
  }

  /// Las fotos subidas: el id del producto, los bytes y su tipo, en orden.
  final uploads = <(String, List<int>, String)>[];

  /// Si no es null, la próxima subida de una foto falla con esto.
  ApiFailure? uploadFailure;

  /// Como el servidor: la foto queda en una ruta relativa nueva.
  @override
  Future<Product> uploadImage(
    String id,
    List<int> bytes, {
    required String contentType,
  }) async {
    if (uploadFailure case final failure?) {
      uploadFailure = null;
      throw failure;
    }
    uploads.add((id, bytes, contentType));
    final i = products.indexWhere((product) => product.id == id);
    final product = products[i];
    return products[i] = Product(
      id: product.id,
      name: product.name,
      sku: product.sku,
      priceCents: product.priceCents,
      promoPriceCents: product.promoPriceCents,
      stock: product.stock,
      minStock: product.minStock,
      active: product.active,
      description: product.description,
      imageUrl: '/images/products/$id/foto${uploads.length}.jpg',
      expirationDate: product.expirationDate,
      category: product.category,
    );
  }

  void _check(String? id, ProductInput input) {
    if (failNext case final failure?) {
      failNext = null;
      throw failure;
    }
    if (products.any((p) => p.sku == input.sku && p.id != id)) {
      throw ApiFailure(
        'Ya existe un producto con el SKU ${input.sku}',
        status: 409,
      );
    }
    sent.add((id, input));
  }

  static Product _apply(Product product, ProductInput input) => Product(
    id: product.id,
    name: input.name,
    sku: input.sku,
    priceCents: input.priceCents,
    promoPriceCents: product.promoPriceCents,
    stock: product.stock,
    minStock: input.minStock,
    active: input.active,
    description: input.description,
    imageUrl: input.imageUrl,
    expirationDate: switch (input.expirationDate) {
      final day? => DateTime.utc(day.year, day.month, day.day),
      null => null,
    },
    category: [groceries, dairy].firstWhere((c) => c.id == input.categoryId),
  );
}

/// El inventario en memoria: el stock de [products] y su historial, el más
/// reciente primero. Responde 409 si una salida o un ajuste deja el stock en
/// negativo, como el servidor.
class FakeInventoryRepository implements InventoryRepository {
  FakeInventoryRepository(
    List<Product> products, {
    List<Movement> movements = const [],
    this.pageSize = 20,
  }) : stock = {for (final p in products) p.id: p.stock},
       _products = {for (final p in products) p.id: p},
       history = [...movements];

  final Map<String, int> stock;
  final Map<String, Product> _products;
  final List<Movement> history;
  final int pageSize;
  final recorded = <MovementInput>[];

  /// Los filtros con que se pidió cada página.
  final queries = <MovementsFilter>[];

  /// Filtra como el servidor: [search] en el nombre o el SKU (sin
  /// mayúsculas) o, si es un número, el N.º del pedido; los días, en la
  /// hora del dispositivo.
  @override
  Future<PageList<Movement>> movements({
    int page = 1,
    String? search,
    MovementOrigin? origin,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    queries.add((
      search: search ?? '',
      origin: origin,
      categoryId: categoryId,
      from: from,
      to: to,
    ));
    final text = (search ?? '').toLowerCase();
    final number = int.tryParse(text);
    bool matches(Movement m) {
      final local = m.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      return (origin == null ||
              (origin == MovementOrigin.orders) == (m.orderId != null)) &&
          (categoryId == null ||
              _products[m.productId]?.category?.id == categoryId) &&
          (text.isEmpty ||
              m.productName.toLowerCase().contains(text) ||
              m.sku.toLowerCase().contains(text) ||
              (number != null && m.orderNumber == number)) &&
          (from == null || !day.isBefore(from)) &&
          (to == null || !day.isAfter(to));
    }

    final matching = history.where(matches).toList();
    return PageList(
      matching.skip((page - 1) * pageSize).take(pageSize).toList(),
      total: matching.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Movement> record(MovementInput input) async {
    final product = _products[input.productId]!;
    final current = stock[product.id]!;
    final change = input.type == MovementType.outgoing
        ? -input.quantity
        : input.quantity;
    if (current + change < 0) {
      throw ApiFailure(
        'Stock insuficiente: ${product.name} tiene $current unidades',
        status: 409,
      );
    }
    recorded.add(input);
    stock[product.id] = current + change;
    final movement = Movement(
      id: 'mov-${history.length + 1}',
      type: input.type,
      quantity: input.quantity,
      reason: input.toJson()['reason'] as String?,
      createdAt: DateTime.utc(2026, 10, 4, 16),
      productId: product.id,
      productName: product.name,
      sku: product.sku,
      userName: 'Ana Staff',
    );
    history.insert(0, movement);
    return movement;
  }
}

/// Las promociones en memoria, como el servidor: el precio menor que el
/// normal (400), sin cruzarse con otra encendida del mismo producto y la
/// misma audiencia (409) y el estado calculado con [today].
class FakePromotionsRepository implements PromotionsRepository {
  FakePromotionsRepository(
    List<Promotion> promotions, {
    this.products = const [],
    this.today = '2026-10-04',
    this.pageSize = 20,
  }) : promotions = [...promotions];

  final List<Promotion> promotions;

  /// Los que se pueden elegir al crear.
  final List<Product> products;
  final String today;
  final int pageSize;

  /// Lo que se guardó al crear (`null` como id) o editar, en orden, y si
  /// se mandó con `confirmOverlap`.
  final sent = <(String?, PromotionInput)>[];
  final confirmed = <bool>[];
  final deleted = <String>[];

  @override
  Future<PageList<Promotion>> list({
    int page = 1,
    PromotionStatus? status,
  }) async {
    final matching = [
      for (final promotion in promotions)
        if (status == null || promotion.status == status) promotion,
    ]..sort((a, b) => b.startDate.compareTo(a.startDate));
    return PageList(
      matching.skip((page - 1) * pageSize).take(pageSize).toList(),
      total: matching.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Promotion> create(
    PromotionInput input, {
    bool confirmOverlap = false,
  }) async {
    final product = products.firstWhere((p) => p.id == input.productId);
    final promotion = _build(
      'promo-${promotions.length + 1}',
      product.id,
      product.name,
      product.sku,
      product.priceCents,
      input,
    );
    _check(promotion, null, confirmOverlap);
    sent.add((null, input));
    confirmed.add(confirmOverlap);
    promotions.add(promotion);
    return promotion;
  }

  @override
  Future<Promotion> update(
    String id,
    PromotionInput input, {
    bool confirmOverlap = false,
  }) async {
    final i = promotions.indexWhere((p) => p.id == id);
    final current = promotions[i];
    final promotion = _build(
      id,
      current.productId,
      current.productName,
      current.sku,
      current.priceCents,
      input,
    );
    _check(promotion, id, confirmOverlap);
    sent.add((id, input));
    confirmed.add(confirmOverlap);
    return promotions[i] = promotion;
  }

  @override
  Future<void> delete(String id) async {
    promotions.removeWhere((p) => p.id == id);
    deleted.add(id);
  }

  Promotion _build(
    String id,
    String productId,
    String name,
    String sku,
    int priceCents,
    PromotionInput input,
  ) => Promotion(
    id: id,
    productId: productId,
    productName: name,
    sku: sku,
    priceCents: priceCents,
    type: input.type,
    promoPriceCents: input.type == PromotionType.specialPrice
        ? input.promoPriceCents
        : null,
    percent: input.percent,
    buyQuantity: input.buyQuantity,
    payQuantity: input.payQuantity,
    giftProductId: input.giftProductId,
    giftProductName: products
        .where((p) => p.id == input.giftProductId)
        .firstOrNull
        ?.name,
    giftQuantity: input.giftQuantity,
    startDate: input.startDate,
    endDate: input.endDate,
    active: input.active,
    audience: input.audience,
    title: input.title,
    recipients: input.audience == PromotionAudience.selected
        ? input.recipients
        : const [],
    promoCodeId: input.audience == PromotionAudience.code
        ? input.promoCodeId
        : null,
    status: !input.active
        ? PromotionStatus.disabled
        : today.compareTo(input.startDate) < 0
        ? PromotionStatus.scheduled
        : today.compareTo(input.endDate) > 0
        ? PromotionStatus.expired
        : PromotionStatus.active,
  );

  /// Como el servidor: el precio especial, menor que el normal; si se
  /// cruza con otras encendidas del producto (cualquier audiencia), 409
  /// con la lista, salvo con [confirmOverlap].
  void _check(Promotion promotion, String? id, bool confirmOverlap) {
    if (promotion.type == PromotionType.specialPrice &&
        promotion.promoPriceCents! >= promotion.priceCents) {
      throw ApiFailure(
        'El precio promocional debe ser menor al precio normal '
        '(${promotion.priceCents / 100})',
        status: 400,
      );
    }
    if (!promotion.active || confirmOverlap) return;
    final overlaps = [
      for (final other in promotions)
        if (other.id != id &&
            other.active &&
            other.productId == promotion.productId &&
            other.startDate.compareTo(promotion.endDate) <= 0 &&
            other.endDate.compareTo(promotion.startDate) >= 0)
          (
            label: other.label,
            audience: other.audience,
            startDate: other.startDate,
            endDate: other.endDate,
          ),
    ];
    if (overlaps.isNotEmpty) throw PromotionOverlap(overlaps);
  }
}

/// Los códigos promocionales en memoria, como el servidor: filtra por estado
/// y por texto; sus promociones son las de [promotions] con su id; no se
/// enciende sin promociones.
class FakePromoCodesRepository implements PromoCodesRepository {
  FakePromoCodesRepository(List<PromoCode> codes, {this.promotions})
    : codes = [...codes];

  final List<PromoCode> codes;

  /// De donde salen las promociones de cada código.
  final FakePromotionsRepository? promotions;

  /// Lo que se mandó al crear (`null` como id) o editar, en orden.
  final sent = <(String?, PromoCodeInput)>[];

  /// Los filtros de cada página pedida: (estado, búsqueda).
  final requests = <(PromoCodeStatus?, String)>[];

  /// Si no es null, `delete` falla con esto.
  ApiFailure? deleteFailure;

  List<Promotion> _promotionsOf(String id) => [
    for (final promotion in promotions?.promotions ?? const <Promotion>[])
      if (promotion.promoCodeId == id) promotion,
  ];

  PromoCode _withPromotions(PromoCode code) => PromoCode(
    id: code.id,
    code: code.code,
    active: code.active,
    status: code.status,
    startDate: code.startDate,
    endDate: code.endDate,
    benefitDays: code.benefitDays,
    maxRedemptions: code.maxRedemptions,
    usesPerCustomer: code.usesPerCustomer,
    minPurchaseCents: code.minPurchaseCents,
    newCustomersOnly: code.newCustomersOnly,
    eligibility: code.eligibility,
    allowedEmails: code.allowedEmails,
    promotions: _promotionsOf(code.id),
    redemptions: code.redemptions,
    orders: code.orders,
  );

  @override
  Future<PageList<PromoCode>> list({
    int page = 1,
    PromoCodeStatus? status,
    String search = '',
  }) async {
    requests.add((status, search));
    final matching = [
      for (final code in codes)
        if ((status == null || code.status == status) &&
            code.code.contains(search.trim().toUpperCase()))
          _withPromotions(code),
    ];
    return PageList(matching, total: matching.length, page: 1, pageSize: 20);
  }

  @override
  Future<PromoCode> get(String id) async =>
      _withPromotions(codes.firstWhere((code) => code.id == id));

  @override
  Future<PromoCode> create(PromoCodeInput input) async {
    final code = _build('code-${codes.length + 1}', input, null);
    sent.add((null, input));
    codes.insert(0, code);
    return code;
  }

  @override
  Future<PromoCode> update(String id, PromoCodeInput input) async {
    final i = codes.indexWhere((code) => code.id == id);
    if (input.active && _promotionsOf(id).isEmpty) {
      throw const ApiFailure(
        'Agrega al menos una promoción antes de encender el código',
        status: 400,
      );
    }
    final code = _build(id, input, codes[i]);
    sent.add((id, input));
    return codes[i] = code;
  }

  @override
  Future<void> delete(String id) async {
    if (deleteFailure case final failure?) throw failure;
    codes.removeWhere((code) => code.id == id);
  }

  PromoCode _build(String id, PromoCodeInput input, PromoCode? current) =>
      PromoCode(
        id: id,
        code: input.code,
        active: input.active,
        status: input.active ? PromoCodeStatus.active : PromoCodeStatus.paused,
        startDate: input.startDate,
        endDate: input.endDate,
        benefitDays: input.benefitDays,
        maxRedemptions: input.maxRedemptions,
        usesPerCustomer: input.usesPerCustomer,
        minPurchaseCents: input.minPurchaseCents,
        newCustomersOnly: input.newCustomersOnly,
        eligibility: input.eligibility,
        allowedEmails: input.allowedEmails,
        redemptions: current?.redemptions ?? 0,
        orders: current?.orders ?? 0,
      );
}

/// El código VERANO-10 activado: un 2x1 del arroz, dos usos.
final summerCode = MyPromoCode(
  code: 'VERANO-10',
  expiresAt: DateTime.utc(2026, 12, 1, 5),
  usesLeft: 2,
  promotions: const ['2x1 en Arroz extra 5 kg'],
);

/// Los códigos de la cuenta en memoria: [available] son los que se pueden
/// activar (por su texto, en mayúsculas); los demás dan el 404 del
/// servidor.
class FakeMyPromoCodesRepository implements MyPromoCodesRepository {
  FakeMyPromoCodesRepository({
    List<MyPromoCode> mine = const [],
    this.available = const {},
  }) : codes = [...mine];

  final List<MyPromoCode> codes;
  final Map<String, MyPromoCode> available;

  /// Los textos que se mandaron a activar, como se escribieron.
  final redeemed = <String>[];

  @override
  Future<List<MyPromoCode>> mine(String idToken) async => [...codes];

  @override
  Future<MyPromoCode> redeem(String idToken, String code) async {
    redeemed.add(code);
    final found = available[code.trim().toUpperCase()];
    if (found == null) {
      throw const ApiFailure(
        'El código no existe o ya no está vigente',
        status: 404,
      );
    }
    if (codes.any((c) => c.code == found.code)) {
      throw const ApiFailure('Ya activaste este código', status: 409);
    }
    codes.add(found);
    return found;
  }
}

/// Los clientes VIP en memoria, como el servidor: solo los activos, por
/// correo y con búsqueda; el alta normaliza, valida, separa los duplicados
/// (repetidos o ya activos) y reactiva a los dados de baja; la baja es lógica.
class FakeVipRepository implements VipRepository {
  FakeVipRepository(
    List<VipCustomer> customers, {
    this.registered = const {},
    this.pageSize = 20,
  }) : customers = [...customers];

  final List<VipCustomer> customers;

  /// Los correos que ya tienen cuenta (para los que se agregan).
  final Set<String> registered;
  final int pageSize;

  /// Lo que se mandó al agregar y los ids que se quitaron, en orden.
  final sent = <List<String>>[];
  final removed = <String>[];

  /// Con un valor, el alta falla con ese error.
  ApiFailure? addFailure;

  @override
  Future<PageList<VipCustomer>> list({int page = 1, String search = ''}) async {
    final query = normalizeEmail(search);
    final matching = [
      for (final vip in customers)
        if (vip.active && vip.email.contains(query)) vip,
    ]..sort((a, b) => a.email.compareTo(b.email));
    return PageList(
      matching.skip((page - 1) * pageSize).take(pageSize).toList(),
      total: matching.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<EmailAddSummary> add(List<String> emails) async {
    if (addFailure case final failure?) throw failure;
    sent.add(emails);
    final added = <String>[];
    final duplicates = <String>[];
    final invalid = <String>[];
    final seen = <String>{};
    for (final raw in emails) {
      final email = normalizeEmail(raw);
      if (!isValidEmail(email)) {
        invalid.add(raw.trim());
        continue;
      }
      if (!seen.add(email)) {
        duplicates.add(email);
        continue;
      }
      final i = customers.indexWhere((vip) => vip.email == email);
      if (i >= 0 && customers[i].active) {
        duplicates.add(email);
        continue;
      }
      final vip = VipCustomer(
        id: i >= 0 ? customers[i].id : 'vip-${customers.length + 1}',
        email: email,
        active: true,
        createdAt: DateTime.utc(2026, 10, 9, 15),
        hasAccount: registered.contains(email),
        addedByName: 'Ana admin',
      );
      if (i >= 0) {
        customers[i] = vip;
      } else {
        customers.add(vip);
      }
      added.add(email);
    }
    return EmailAddSummary(
      added: added,
      duplicates: duplicates,
      invalid: invalid,
    );
  }

  @override
  Future<VipCustomer> remove(String id) async {
    final i = customers.indexWhere((vip) => vip.id == id);
    final current = customers[i];
    removed.add(id);
    return customers[i] = VipCustomer(
      id: current.id,
      email: current.email,
      active: false,
      createdAt: current.createdAt,
      hasAccount: current.hasAccount,
      addedByName: current.addedByName,
    );
  }
}

/// Los reportes del inicio del panel en memoria. Con [failing], ese reporte
/// falla.
class FakeStatsRepository implements StatsRepository {
  FakeStatsRepository({
    this.overviewData,
    this.sales,
    this.top = const [],
    this.low = const [],
    this.expiringItems = const [],
  });

  StatsOverview? overviewData;
  SalesReport? sales;
  List<TopProduct> top;
  List<LowStockItem> low;
  List<ExpiringItem> expiringItems;

  /// 'overview', 'sales', 'top', 'low' o 'expiring'.
  final failing = <String>{};
  int calls = 0;

  Future<T> _answer<T>(String report, T Function() data) async {
    calls++;
    if (failing.contains(report)) {
      throw const ApiFailure('El servidor no está disponible.');
    }
    return data();
  }

  @override
  Future<StatsOverview> overview() => _answer('overview', () => overviewData!);

  @override
  Future<SalesReport> sales30Days() => _answer('sales', () => sales!);

  @override
  Future<List<TopProduct>> topProducts({int limit = 5}) =>
      _answer('top', () => top.take(limit).toList());

  @override
  Future<List<LowStockItem>> lowStock() => _answer('low', () => low);

  @override
  Future<List<ExpiringItem>> expiring({int days = 7}) =>
      _answer('expiring', () => expiringItems);
}

/// Los pedidos en memoria. Cobra el precio de hoy de los productos de
/// [catalog], como el servidor.
class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository(this.catalog, {this.pageSize = 10});

  final FakeCatalogRepository catalog;
  final int pageSize;

  /// Los pedidos hechos, el más reciente primero.
  final orders = <Order>[];

  /// Si no es null, `place` falla con esto (p. ej. 409 sin stock).
  ApiFailure? failure;

  /// Los ID tokens con que se llamó a `place` y `mine`.
  final tokens = <String>[];

  /// Las líneas de cada pedido, como llegaron.
  final placed = <List<OrderLineRequest>>[];

  /// El tipo de entrega y la dirección de cada pedido, como llegaron.
  final deliveries = <(FulfillmentType, String?)>[];

  /// Los filtros con que se pidió cada página de "Mis pedidos".
  final filters = <MyOrdersFilter>[];

  /// Cada cotización pedida: las líneas y el token (null sin sesión).
  final quotes = <(List<QuoteLineRequest>, String?)>[];

  /// Lo que devuelve `quote` (p. ej. con un 2x1). Sin esto, cada línea al
  /// precio de hoy del catálogo, sin promociones ni descuentos.
  Quote Function(List<QuoteLineRequest> lines)? quoteWith;

  /// Si no es null, `quote` falla con esto.
  ApiFailure? quoteFailure;

  @override
  Future<Quote> quote(List<QuoteLineRequest> lines, {String? idToken}) async {
    quotes.add((lines, idToken));
    if (quoteFailure case final failure?) throw failure;
    if (quoteWith case final quoteWith?) return quoteWith(lines);
    final priced = [
      for (final line in lines)
        if (await catalog.product(line.productId) case final product)
          OrderLine(
            productId: product.id,
            name: product.name,
            quantity: line.quantity,
            unitPriceCents: product.finalPriceCents,
          ),
    ];
    final total = priced.fold(0, (sum, line) => sum + line.lineTotalCents);
    return Quote(
      lines: priced,
      subtotalCents: total,
      discountCents: 0,
      totalCents: total,
    );
  }

  @override
  Future<Order> place(
    String idToken, {
    FulfillmentType fulfillmentType = FulfillmentType.delivery,
    String? deliveryAddress,
    required List<OrderLineRequest> lines,
  }) async {
    tokens.add(idToken);
    if (failure case final failure?) throw failure;
    placed.add(lines);
    deliveries.add((fulfillmentType, deliveryAddress));
    final pickup = fulfillmentType == FulfillmentType.pickup;
    final changes = <PriceChange>[];
    final orderLines = [
      for (final line in lines)
        if (await catalog.product(line.productId) case final product)
          OrderLine(
            productId: product.id,
            name: product.name,
            quantity: line.quantity,
            unitPriceCents: product.finalPriceCents,
          ),
    ];
    // Como el servidor: cobra el precio de hoy y avisa si el carrito
    // mostraba otro.
    for (final line in lines) {
      final product = await catalog.product(line.productId);
      final charged = product.finalPriceCents * line.quantity;
      if (line.shownLineTotalCents case final shown?) {
        if (shown != charged) {
          changes.add(
            PriceChange(
              productId: product.id,
              name: product.name,
              shownLineTotalCents: shown,
              lineTotalCents: charged,
            ),
          );
        }
      } else if (line.shownUnitPriceCents case final shown?
          when shown != product.finalPriceCents) {
        changes.add(
          PriceChange(
            productId: product.id,
            name: product.name,
            shownUnitPriceCents: shown,
            unitPriceCents: product.finalPriceCents,
          ),
        );
      }
    }
    final order = Order(
      id: 'pedido-${orders.length + 1}',
      // Como el servidor: correlativo desde 1001.
      number: 1001 + orders.length,
      status: OrderStatus.pendingConfirmation,
      fulfillmentType: fulfillmentType,
      // Como el servidor: los códigos los genera él, según el tipo.
      pickupCode: pickup ? 'K7M2XQ' : null,
      deliveryCode: pickup ? null : 'P4R9TW',
      totalCents: orderLines.fold(0, (sum, line) => sum + line.lineTotalCents),
      deliveryAddress: pickup ? null : deliveryAddress,
      createdAt: DateTime.utc(2026, 10, 4, 15, 30),
      lines: orderLines,
      priceChanges: changes,
    );
    orders.insert(0, order);
    return order;
  }

  /// Filtra como el servidor: [MyOrdersFilter.search] es el N.º o un
  /// producto (sin mayúsculas); los días, en la hora del dispositivo.
  @override
  Future<PageList<Order>> mine(
    String idToken, {
    int page = 1,
    MyOrdersFilter filter = allMyOrders,
  }) async {
    tokens.add(idToken);
    filters.add(filter);
    final text = filter.search.trim().toLowerCase();
    final number = int.tryParse(text);
    bool matches(Order order) {
      final local = order.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final finished =
          order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled;
      final inProgress = switch (filter.progress) {
        OrderProgress.active => !finished,
        OrderProgress.delivered => order.status == OrderStatus.delivered,
        OrderProgress.cancelled => order.status == OrderStatus.cancelled,
        null => true,
      };
      return inProgress &&
          (filter.fulfillmentType == null ||
              order.fulfillmentType == filter.fulfillmentType) &&
          (text.isEmpty ||
              (number != null && order.number == number) ||
              order.lines.any((l) => l.name.toLowerCase().contains(text))) &&
          (filter.from == null || !day.isBefore(filter.from!)) &&
          (filter.to == null || !day.isAfter(filter.to!));
    }

    final matching = orders.where(matches).toList();
    return PageList(
      matching.skip((page - 1) * pageSize).take(pageSize).toList(),
      total: matching.length,
    );
  }

  /// Lo que haría el staff desde el panel.
  void setStatus(String id, OrderStatus status) {
    final i = orders.indexWhere((order) => order.id == id);
    final order = orders[i];
    orders[i] = Order(
      id: order.id,
      number: order.number,
      status: status,
      fulfillmentType: order.fulfillmentType,
      totalCents: order.totalCents,
      deliveryAddress: order.deliveryAddress,
      pickupCode: order.pickupCode,
      deliveryCode: order.deliveryCode,
      createdAt: order.createdAt,
      lines: order.lines,
    );
  }
}

/// El catálogo en memoria, paginado como el servidor.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    this.categoryList = const [groceries, dairy],
    this.productList = const [rice, oil, milk],
    this.pageSize = 20,
  });

  final List<Category> categoryList;
  final List<Product> productList;
  final int pageSize;

  /// Si no es null, `products` falla con esto.
  Object? failure;

  /// Cada pedido de productos: (categoría, página).
  final requests = <(String?, int)>[];

  /// Lo buscado en cada pedido de productos (null: nada).
  final searches = <String?>[];

  /// Si cada pedido de productos pidió solo los que están en promoción.
  final onSaleRequests = <bool>[];

  @override
  Future<List<Category>> categories() async => categoryList;

  @override
  Future<PageList<Product>> products({
    String? categoryId,
    String? search,
    bool onSale = false,
    int page = 1,
  }) async {
    requests.add((categoryId, page));
    searches.add(search);
    onSaleRequests.add(onSale);
    if (failure case final failure?) throw failure;
    final text = search?.toLowerCase();
    final matching = [
      for (final product in productList)
        if ((categoryId == null || product.category?.id == categoryId) &&
            (text == null || product.name.toLowerCase().contains(text)) &&
            (!onSale || product.onSale))
          product,
    ];
    return PageList(
      matching.skip((page - 1) * pageSize).take(pageSize).toList(),
      total: matching.length,
    );
  }

  @override
  Future<Product> product(String id) async =>
      productList.where((product) => product.id == id).firstOrNull ??
      (throw const ApiFailure('Producto no encontrado', status: 404));
}

/// Las ofertas exclusivas en memoria. [calls] cuenta cuántas veces se
/// pidieron: a quien no es VIP, la app no debe pedirlas nunca.
class FakeOffersRepository implements OffersRepository {
  FakeOffersRepository([this.offers = const []]);

  List<Offer> offers;

  /// Si no es null, `exclusive` falla con esto.
  Object? failure;

  int calls = 0;

  @override
  Future<List<Offer>> exclusive() async {
    calls++;
    if (failure case final failure?) throw failure;
    return offers;
  }
}

/// Firebase Auth en memoria: cuentas por email y una abierta a la vez.
class FakeAuthRepository implements AuthRepository {
  final _accounts = <String, FakeAccount>{};
  final _listeners = <StreamController<String?>>[];
  String? _current;

  /// El uid de la cuenta abierta.
  String? get current => _current;

  /// Cuántas veces se mandó el correo de verificación, y cuántas se volvió a
  /// preguntar a Firebase si está verificado.
  int verificationEmails = 0;
  int reloads = 0;

  /// A qué correos se mandó el enlace para crear una contraseña nueva.
  final passwordResets = <String>[];

  /// Si no es null, mandar el enlace falla con esto.
  AuthFailure? resetFailure;

  FakeAccount addAccount(
    String email,
    String password, {
    String? name,
    bool signedIn = false,
    bool emailVerified = true,
  }) {
    final account = FakeAccount(
      'uid-${_accounts.length + 1}',
      email,
      password,
      name,
    )..emailVerified = emailVerified;
    _accounts[email] = account;
    if (signedIn) _current = account.uid;
    return account;
  }

  FakeAccount accountOf(String uid) =>
      _accounts.values.firstWhere((account) => account.uid == uid);

  /// Como `authStateChanges` de Firebase: el estado actual al suscribirse y
  /// después cada cambio.
  @override
  Stream<String?> accountChanges() {
    late final StreamController<String?> controller;
    controller = StreamController(
      onListen: () {
        controller.add(_current);
        _listeners.add(controller);
      },
      onCancel: () => _listeners.remove(controller),
    );
    return controller.stream;
  }

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw const AuthFailure('El correo o la contraseña no son correctos.');
    }
    _open(account.uid);
    return account.uid;
  }

  /// Como Firebase: avisa del cambio de cuenta apenas la crea, antes de que
  /// el nombre quede guardado.
  @override
  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_accounts.containsKey(email)) {
      throw const AuthFailure('Ya hay una cuenta con ese correo.');
    }
    // Como Firebase: la cuenta nueva no tiene el correo confirmado, y el
    // registro manda el correo para confirmarlo.
    final account = addAccount(email, password, emailVerified: false)
      ..registered = true;
    _open(account.uid);
    await Future<void>.delayed(Duration.zero);
    account.name = name;
    verificationEmails++;
    return account.uid;
  }

  @override
  Future<void> signOut() async => _open(null);

  @override
  Future<String> idToken() async {
    final uid = _current;
    if (uid == null) throw const AuthFailure('Tu sesión terminó.');
    return 'token-$uid';
  }

  @override
  Future<bool> emailVerified({bool reload = false}) async {
    if (reload) reloads++;
    final uid = _current;
    return uid != null && accountOf(uid).emailVerified;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (_current == null) throw const AuthFailure('Tu sesión terminó.');
    verificationEmails++;
  }

  /// Como Firebase con la protección contra enumeración: con un correo sin
  /// cuenta, sale igual.
  @override
  Future<void> sendPasswordReset(String email) async {
    if (resetFailure case final failure?) throw failure;
    passwordResets.add(email.trim());
  }

  void _open(String? uid) {
    _current = uid;
    for (final listener in List.of(_listeners)) {
      listener.add(uid);
    }
  }
}

class FakeAccount {
  FakeAccount(this.uid, this.email, this.password, this.name);

  final String uid;
  final String email;
  final String password;
  String? name;

  /// Si confirmó su correo (lo cambia el test, como si abriera el enlace).
  bool emailVerified = true;

  /// Si se creó con `register`: como en el servidor, empieza sin celular ni
  /// términos (ver [FakeUserRepository.profileOf]).
  bool registered = false;
}

/// El perfil de una cuenta en el servidor en memoria: lo que pide un pedido
/// (el celular y los términos) y el DNI.
class FakeProfile {
  const FakeProfile({
    this.phone,
    this.dni,
    this.termsVersion,
    this.termsAcceptedAt,
  });

  /// Lo que tiene una cuenta de los tests si no se dice otra cosa.
  static final complete = FakeProfile(
    phone: '987654321',
    termsVersion: legal.termsVersion,
    termsAcceptedAt: DateTime.utc(2026, 10, 28, 15),
  );

  final String? phone;
  final String? dni;
  final String? termsVersion;
  final DateTime? termsAcceptedAt;

  bool get isComplete => phone != null && termsVersion == legal.termsVersion;
}

/// El servidor en memoria: la primera vez que ve un uid crea su perfil con el
/// nombre que tenga la cuenta en ese momento, como `GET /users/me`.
class FakeUserRepository implements UserRepository {
  FakeUserRepository(this.auth);

  final FakeAuthRepository auth;

  /// Roles que no son customer, por uid, con los permisos de
  /// `permissionsOf`.
  final roles = <String, UserRole>{};

  /// Los permisos justos de una cuenta del personal, por uid, y el nombre de
  /// su rol (gana sobre [roles]). Se pueden cambiar en cualquier momento: el
  /// próximo `me` ya los trae, como cuando un admin cambia un rol.
  final permissions = <String, Set<StaffPermission>>{};
  final roleNames = <String, String>{};

  /// Direcciones guardadas en el perfil, por uid.
  final addresses = <String, String>{};

  /// El celular, el DNI y los términos, por uid (ver [profileOf]).
  final profiles = <String, FakeProfile>{};

  /// Los DNI que ya tiene otra cuenta: guardarlos da 409, como el servidor.
  final takenDnis = <String>{};

  /// Cada `updateProfile`, con lo que se mandó.
  final profileUpdates =
      <({String? phone, String? dni, bool clearDni, bool acceptTerms})>[];

  /// El perfil de [uid]: el de [profiles] o, si no está, completo; una
  /// cuenta recién registrada empieza vacía, como en el servidor.
  FakeProfile profileOf(String uid) =>
      profiles[uid] ??
      (auth.accountOf(uid).registered
          ? const FakeProfile()
          : FakeProfile.complete);

  /// Los uid que el servidor responde como VIP (un admin los puede agregar
  /// o quitar en cualquier momento).
  final vips = <String>{};

  /// Si no es null, `me` falla con esto (p. ej. el servidor caído).
  AuthFailure? failure;

  /// Si no es null, `me` no responde hasta que se complete (un servidor
  /// lento, para ver los estados de carga).
  Completer<void>? hold;

  int calls = 0;

  @override
  Future<SessionUser> me(String idToken) async {
    calls++;
    if (hold case final hold?) await hold.future;
    if (failure case final failure?) throw failure;
    final uid = idToken.replaceFirst('token-', '');
    final account = auth.accountOf(uid);
    final granted =
        permissions[uid] ?? permissionsOf(roles[uid] ?? UserRole.customer);
    return SessionUser(
      id: 'user-$uid',
      name: account.name ?? account.email.split('@').first,
      email: account.email,
      role: permissions.containsKey(uid)
          ? roleOf(granted)
          : roles[uid] ?? UserRole.customer,
      address: addresses[uid],
      phone: profileOf(uid).phone,
      dni: profileOf(uid).dni,
      termsVersion: profileOf(uid).termsVersion,
      termsAcceptedAt: profileOf(uid).termsAcceptedAt,
      profileComplete: profileOf(uid).isComplete,
      isVip: vips.contains(uid),
      staffRoleName: roleNames[uid],
      permissions: granted,
    );
  }

  /// Como `PATCH /users/me`: guarda lo que viene y responde la cuenta. Un
  /// DNI de [takenDnis]: 409.
  @override
  Future<SessionUser> updateProfile(
    String idToken, {
    String? phone,
    String? dni,
    bool clearDni = false,
    bool acceptTerms = false,
  }) async {
    profileUpdates.add((
      phone: phone,
      dni: dni,
      clearDni: clearDni,
      acceptTerms: acceptTerms,
    ));
    if (dni != null && takenDnis.contains(dni)) {
      throw const ApiFailure(
        'Ese DNI ya está registrado en otra cuenta.',
        status: 409,
      );
    }
    final uid = idToken.replaceFirst('token-', '');
    final current = profileOf(uid);
    profiles[uid] = FakeProfile(
      phone: phone?.replaceAll(RegExp(r'\D'), '') ?? current.phone,
      dni: clearDni ? null : dni ?? current.dni,
      termsVersion: acceptTerms ? legal.termsVersion : current.termsVersion,
      termsAcceptedAt: acceptTerms
          ? DateTime.utc(2026, 10, 28, 15)
          : current.termsAcceptedAt,
    );
    return me(idToken);
  }
}

/// Deja correr los microtasks y eventos pendientes (los avisos de cuenta y
/// las respuestas de los repositorios falsos).
Future<void> flushEvents() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// El equipo y sus roles en memoria, con las reglas del servidor
/// (`StaffService` y `RolesService` en apps/server): nadie se cambia el rol
/// ni se desactiva a sí mismo ([me]); no se quita al último Administrador
/// activo; un rol inactivo no se asigna; un rol con personal (también dado
/// de baja) no se borra; el rol del sistema no se edita; los nombres no se
/// repiten.
class FakeStaffRepository implements StaffRepository {
  FakeStaffRepository({
    required List<StaffRole> roles,
    required List<StaffMember> members,
    this.me = 'admin@tienda.pe',
    this.registered = const {},
  }) : roleList = [...roles],
       memberList = [...members];

  final List<StaffRole> roleList;
  final List<StaffMember> memberList;

  /// El correo de quien usa el panel.
  final String me;

  /// Los correos que ya tienen cuenta (para los que se agregan).
  final Set<String> registered;

  /// Lo que se mandó al agregar: los correos y el rol.
  final sent = <(List<String>, String)>[];

  static ApiFailure _conflict(String message) =>
      ApiFailure(message, status: 409);

  StaffRole _role(String id) => roleList.firstWhere(
    (role) => role.id == id,
    orElse: () =>
        throw const ApiFailure('El rol indicado no existe', status: 400),
  );

  StaffRole _assignable(String id) {
    final role = _role(id);
    if (!role.active) {
      throw _conflict(
        'El rol ${role.name} está inactivo: actívalo antes de asignarlo',
      );
    }
    return role;
  }

  int _index(String id) => memberList.indexWhere((member) => member.id == id);

  StaffMember _with(StaffMember member, {StaffRole? role, bool? active}) =>
      StaffMember(
        id: member.id,
        email: member.email,
        active: active ?? member.active,
        hasAccount: member.hasAccount,
        createdAt: member.createdAt,
        roleId: role?.id ?? member.roleId,
        roleName: role?.name ?? member.roleName,
        addedByName: member.addedByName,
      );

  void _assertNotLastAdmin(StaffMember member) {
    final role = _role(member.roleId!);
    if (!role.isSystem) return;
    final others = memberList.where(
      (other) =>
          other.active && other.roleId == role.id && other.id != member.id,
    );
    if (others.isEmpty) {
      throw _conflict(
        '${member.email} es el último ${role.name} activo: agrega otro antes '
        'de quitarle el rol',
      );
    }
  }

  @override
  Future<PageList<StaffMember>> members({
    int page = 1,
    String search = '',
  }) async {
    final query = normalizeEmail(search);
    final matching = [
      for (final member in memberList)
        if (member.email.contains(query)) member,
    ]..sort((a, b) => a.email.compareTo(b.email));
    return PageList(
      matching.skip((page - 1) * 20).take(20).toList(),
      total: matching.length,
      page: page,
    );
  }

  @override
  Future<EmailAddSummary> addMembers(List<String> emails, String roleId) async {
    final role = _assignable(roleId);
    sent.add((emails, roleId));
    final added = <String>[];
    final duplicates = <String>[];
    final invalid = <String>[];
    final seen = <String>{};
    for (final raw in emails) {
      final email = normalizeEmail(raw);
      if (!isValidEmail(email)) {
        invalid.add(raw.trim());
        continue;
      }
      if (!seen.add(email)) {
        duplicates.add(email);
        continue;
      }
      final i = memberList.indexWhere((member) => member.email == email);
      if (i >= 0 && memberList[i].active) {
        duplicates.add(email);
        continue;
      }
      if (i >= 0) {
        memberList[i] = _with(memberList[i], role: role, active: true);
      } else {
        memberList.add(
          StaffMember(
            id: 'm-${memberList.length + 1}',
            email: email,
            active: true,
            hasAccount: registered.contains(email),
            createdAt: DateTime.utc(2026, 10, 11, 15),
            roleId: role.id,
            roleName: role.name,
            addedByName: 'Ana admin',
          ),
        );
      }
      added.add(email);
    }
    return EmailAddSummary(
      added: added,
      duplicates: duplicates,
      invalid: invalid,
    );
  }

  @override
  Future<StaffMember> changeRole(String memberId, String roleId) async {
    final i = _index(memberId);
    final member = memberList[i];
    if (member.email == me) throw _conflict('No puedes cambiar tu propio rol');
    final role = _assignable(roleId);
    if (member.roleId == role.id) return member;
    if (member.active) _assertNotLastAdmin(member);
    return memberList[i] = _with(member, role: role);
  }

  @override
  Future<StaffMember> deactivate(String memberId) async {
    final i = _index(memberId);
    final member = memberList[i];
    if (member.email == me) {
      throw _conflict('No puedes darte de baja a ti mismo');
    }
    if (!member.active) return member;
    _assertNotLastAdmin(member);
    return memberList[i] = _with(member, active: false);
  }

  /// Como los manda el servidor: con cuántas personas activas tiene cada uno.
  @override
  Future<List<StaffRole>> roles() async => [
    for (final role in roleList)
      StaffRole(
        id: role.id,
        name: role.name,
        permissions: role.isSystem
            ? StaffPermission.values.toSet()
            : role.permissions,
        isSystem: role.isSystem,
        active: role.active,
        members: memberList
            .where((member) => member.active && member.roleId == role.id)
            .length,
      ),
  ];

  void _assertNameFree(String name, {String? except}) {
    final taken = roleList.any(
      (role) =>
          role.id != except && role.name.toLowerCase() == name.toLowerCase(),
    );
    if (taken) throw _conflict('Ya existe un rol llamado $name');
  }

  void _assertNotSystem(StaffRole role) {
    if (role.isSystem) {
      throw _conflict(
        'El rol ${role.name} es del sistema: no se edita ni se borra',
      );
    }
  }

  @override
  Future<StaffRole> createRole({
    required String name,
    required Set<StaffPermission> permissions,
  }) async {
    _assertNameFree(name);
    final role = StaffRole(
      id: 'r-${roleList.length + 1}',
      name: name,
      permissions: permissions,
    );
    roleList.add(role);
    return role;
  }

  @override
  Future<StaffRole> updateRole(
    String id, {
    String? name,
    Set<StaffPermission>? permissions,
    bool? active,
  }) async {
    final role = _role(id);
    _assertNotSystem(role);
    if (name != null) _assertNameFree(name, except: id);
    final updated = StaffRole(
      id: id,
      name: name ?? role.name,
      permissions: permissions ?? role.permissions,
      active: active ?? role.active,
    );
    roleList[roleList.indexOf(role)] = updated;
    return updated;
  }

  @override
  Future<void> deleteRole(String id) async {
    final role = _role(id);
    _assertNotSystem(role);
    final members = memberList.where((member) => member.roleId == id).length;
    if (members > 0) {
      throw _conflict(
        'El rol ${role.name} tiene $members '
        '${members == 1 ? 'persona asignada' : 'personas asignadas'} '
        '(también cuentan las dadas de baja): cámbiales el rol antes',
      );
    }
    roleList.remove(role);
  }
}
