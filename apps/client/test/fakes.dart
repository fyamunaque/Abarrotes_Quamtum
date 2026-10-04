import 'dart:async';

import 'package:neils/admin/orders/admin_order.dart';
import 'package:neils/admin/orders/admin_orders_repository.dart';
import 'package:neils/admin/stats/stats.dart';
import 'package:neils/admin/stats/stats_repository.dart';
import 'package:neils/auth/auth_repository.dart';
import 'package:neils/catalog/catalog_repository.dart';
import 'package:neils/catalog/category.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/common/page_list.dart';
import 'package:neils/orders/order.dart';
import 'package:neils/orders/order_repository.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/session/session.dart';
import 'package:neils/users/user_repository.dart';

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

/// Los pedidos del panel en memoria. Valida el cambio de estado como el
/// servidor (`nextStatuses`), con su mismo mensaje.
class FakeAdminOrdersRepository implements AdminOrdersRepository {
  FakeAdminOrdersRepository(this.orders, {this.pageSize = 20});

  final List<AdminOrder> orders;
  final int pageSize;

  /// Si no es null, el próximo cambio de estado falla con esto (p. ej. otra
  /// persona ya lo cambió).
  ApiFailure? failNext;

  final changes = <(String, OrderStatus)>[];

  @override
  Future<PageList<AdminOrder>> list({int page = 1, OrderStatus? status}) async {
    final matching = [
      for (final order in orders)
        if (status == null || order.order.status == status) order,
    ];
    return PageList(
      matching.skip((page - 1) * pageSize).take(pageSize).toList(),
      total: matching.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<AdminOrder> changeStatus(String id, OrderStatus status) async {
    if (failNext case final failure?) {
      failNext = null;
      throw failure;
    }
    final i = orders.indexWhere((order) => order.id == id);
    final current = orders[i];
    if (!current.order.status.nextStatuses.contains(status)) {
      throw ApiFailure(
        'Un pedido ${current.order.status.label.toLowerCase()} no puede '
        'pasar a ${status.label.toLowerCase()}',
        status: 400,
      );
    }
    changes.add((id, status));
    return orders[i] = withStatus(current, status);
  }

  static AdminOrder withStatus(AdminOrder order, OrderStatus status) =>
      AdminOrder(
        order: Order(
          id: order.order.id,
          status: status,
          totalCents: order.order.totalCents,
          deliveryAddress: order.order.deliveryAddress,
          createdAt: order.order.createdAt,
          lines: order.order.lines,
        ),
        customerName: order.customerName,
        customerEmail: order.customerEmail,
        customerPhone: order.customerPhone,
      );
}

/// Un pedido del panel para los tests.
AdminOrder adminOrder(
  String id,
  OrderStatus status, {
  String customer = 'Ana Quispe',
  int day = 4,
}) => AdminOrder(
  order: Order(
    id: id,
    status: status,
    totalCents: 3380,
    deliveryAddress: 'Av. Arequipa 123, Lince',
    createdAt: DateTime.utc(2026, 10, day, 15, 30),
    lines: const [
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
  customerName: customer,
  customerEmail: 'ana@tienda.pe',
  customerPhone: '987654321',
);

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

  @override
  Future<Order> place(
    String idToken, {
    required String deliveryAddress,
    required List<OrderLineRequest> lines,
  }) async {
    tokens.add(idToken);
    if (failure case final failure?) throw failure;
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
    final order = Order(
      id: 'pedido-${orders.length + 1}',
      status: OrderStatus.pendingConfirmation,
      totalCents: orderLines.fold(0, (sum, line) => sum + line.totalCents),
      deliveryAddress: deliveryAddress,
      createdAt: DateTime.utc(2026, 10, 4, 15, 30),
      lines: orderLines,
    );
    orders.insert(0, order);
    return order;
  }

  @override
  Future<PageList<Order>> mine(String idToken, {int page = 1}) async {
    tokens.add(idToken);
    return PageList(
      orders.skip((page - 1) * pageSize).take(pageSize).toList(),
      total: orders.length,
    );
  }

  /// Lo que haría el staff desde el panel.
  void setStatus(String id, OrderStatus status) {
    final i = orders.indexWhere((order) => order.id == id);
    final order = orders[i];
    orders[i] = Order(
      id: order.id,
      status: status,
      totalCents: order.totalCents,
      deliveryAddress: order.deliveryAddress,
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

  @override
  Future<List<Category>> categories() async => categoryList;

  @override
  Future<PageList<Product>> products({String? categoryId, int page = 1}) async {
    requests.add((categoryId, page));
    if (failure case final failure?) throw failure;
    final matching = [
      for (final product in productList)
        if (categoryId == null || product.category?.id == categoryId) product,
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

/// Firebase Auth en memoria: cuentas por email y una abierta a la vez.
class FakeAuthRepository implements AuthRepository {
  final _accounts = <String, FakeAccount>{};
  final _listeners = <StreamController<String?>>[];
  String? _current;

  /// El uid de la cuenta abierta.
  String? get current => _current;

  FakeAccount addAccount(
    String email,
    String password, {
    String? name,
    bool signedIn = false,
  }) {
    final account = FakeAccount(
      'uid-${_accounts.length + 1}',
      email,
      password,
      name,
    );
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
    final account = addAccount(email, password);
    _open(account.uid);
    await Future<void>.delayed(Duration.zero);
    account.name = name;
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
}

/// El servidor en memoria: la primera vez que ve un uid crea su perfil con el
/// nombre que tenga la cuenta en ese momento, como `GET /users/me`.
class FakeUserRepository implements UserRepository {
  FakeUserRepository(this.auth);

  final FakeAuthRepository auth;

  /// Roles que no son customer, por uid.
  final roles = <String, UserRole>{};

  /// Direcciones guardadas en el perfil, por uid.
  final addresses = <String, String>{};
  final _profiles = <String, SessionUser>{};

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
    return _profiles.putIfAbsent(uid, () {
      final account = auth.accountOf(uid);
      return SessionUser(
        id: 'user-$uid',
        name: account.name ?? account.email.split('@').first,
        email: account.email,
        role: roles[uid] ?? UserRole.customer,
        address: addresses[uid],
      );
    });
  }
}

/// Deja correr los microtasks y eventos pendientes (los avisos de cuenta y
/// las respuestas de los repositorios falsos).
Future<void> flushEvents() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
