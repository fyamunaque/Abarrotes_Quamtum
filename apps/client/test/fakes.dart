import 'dart:async';

import 'package:neils/auth/auth_repository.dart';
import 'package:neils/catalog/catalog_repository.dart';
import 'package:neils/catalog/category.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
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
  Future<ProductPage> products({String? categoryId, int page = 1}) async {
    requests.add((categoryId, page));
    if (failure case final failure?) throw failure;
    final matching = [
      for (final product in productList)
        if (categoryId == null || product.category?.id == categoryId) product,
    ];
    return ProductPage(
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
