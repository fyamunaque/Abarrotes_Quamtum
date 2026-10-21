import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../catalog/product.dart';
import 'cart.dart';

/// Dónde queda el carrito entre una vez y otra que se abre la app.
abstract interface class CartStorage {
  /// El carrito guardado, o uno vacío si no hay o no se puede leer.
  Cart load();

  void save(Cart cart);
}

/// El de la app la reemplaza `main.dart` por [PrefsCartStorage]. Este, en
/// memoria, es el de los tests.
final cartStorageProvider = Provider<CartStorage>((ref) => MemoryCartStorage());

/// En memoria: se pierde al cerrar la app.
class MemoryCartStorage implements CartStorage {
  MemoryCartStorage([this._cart = const Cart()]);

  Cart _cart;

  @override
  Cart load() => _cart;

  @override
  void save(Cart cart) => _cart = cart;
}

/// En el dispositivo: SharedPreferences en Android, localStorage en la web.
class PrefsCartStorage implements CartStorage {
  PrefsCartStorage(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'neils.cart';

  @override
  Cart load() => decodeCart(_prefs.getString(key));

  @override
  void save(Cart cart) => unawaited(
    cart.isEmpty ? _prefs.remove(key) : _prefs.setString(key, encodeCart(cart)),
  );
}

const _version = 1;

/// El carrito como JSON, con lo que hace falta para mostrarlo. Los precios
/// son solo para mostrar: el servidor cobra los del momento del pedido.
String encodeCart(Cart cart) => jsonEncode({
  'v': _version,
  'lines': [
    for (final CartLine(:product, :quantity) in cart.lines)
      {
        'id': product.id,
        'name': product.name,
        'priceCents': product.priceCents,
        'promoPriceCents': product.promoPriceCents,
        if (product.vipPrice) 'vip': true,
        'stock': product.stock,
        'imageUrl': product.imageUrl,
        'quantity': quantity,
      },
  ],
});

/// Lo que guardó [encodeCart]. Si falta, está roto o es de otra versión, un
/// carrito vacío: nunca falla. Las líneas que no se entienden se saltan.
Cart decodeCart(String? json) {
  if (json == null) return const Cart();
  final Object? data;
  try {
    data = jsonDecode(json);
  } on FormatException {
    return const Cart();
  }
  if (data case {'v': _version, 'lines': final List<Object?> lines}) {
    return Cart(lines.map(_decodeLine).nonNulls.toList());
  }
  return const Cart();
}

CartLine? _decodeLine(Object? line) => switch (line) {
  {
        'id': final String id,
        'name': final String name,
        'priceCents': final int priceCents,
        'stock': final int stock,
        'quantity': final int quantity,
      } &&
      final Map<Object?, Object?> fields =>
    _line(
      Product(
        id: id,
        name: name,
        priceCents: priceCents,
        promoPriceCents: _optional<int>(fields['promoPriceCents']),
        vipPrice: fields['vip'] == true,
        stock: stock,
        imageUrl: _optional<String>(fields['imageUrl']),
      ),
      quantity,
    ),
  _ => null,
};

T? _optional<T>(Object? value) => value is T ? value : null;

/// La línea con la cantidad dentro del máximo del producto, o null si no
/// queda nada (sin stock o cantidad 0).
CartLine? _line(Product product, int quantity) {
  final clamped = quantity.clamp(0, product.maxQuantity);
  return clamped == 0 ? null : CartLine(product, clamped);
}
