import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/cart/cart.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/cart/cart_storage.dart';
import 'package:neils/catalog/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const rice = Product(
    id: 'arroz',
    name: 'Arroz extra 5 kg',
    priceCents: 2490,
    stock: 40,
    imageUrl: 'https://tienda.pe/arroz.png',
  );
  const oil = Product(
    id: 'aceite',
    name: 'Aceite vegetal 1 L',
    priceCents: 1090,
    promoPriceCents: 890,
    stock: 3,
  );

  List<(String, int)> lines(Cart cart) => [
    for (final line in cart.lines) (line.product.id, line.quantity),
  ];

  group('JSON', () {
    test('ida y vuelta: precios, promoción, imagen, stock y cantidades', () {
      final cart = decodeCart(
        encodeCart(const Cart([CartLine(rice, 2), CartLine(oil, 3)])),
      );

      expect(lines(cart), [('arroz', 2), ('aceite', 3)]);
      final [saved, promo] = [for (final line in cart.lines) line.product];
      expect(saved.name, 'Arroz extra 5 kg');
      expect(saved.priceCents, 2490);
      expect(saved.imageUrl, 'https://tienda.pe/arroz.png');
      expect(promo.finalPriceCents, 890);
      expect(promo.stock, 3);
      expect(cart.totalCents, 2 * 2490 + 3 * 890);
    });

    test('nada guardado, JSON roto u otra versión: carrito vacío', () {
      for (final json in [
        null,
        '',
        '{no es json',
        '[]',
        jsonEncode({'v': 99, 'lines': []}),
        jsonEncode({'lines': []}),
      ]) {
        expect(decodeCart(json).isEmpty, isTrue, reason: '$json');
      }
    });

    test('se salta las líneas que no entiende o ya sin stock', () {
      final json = jsonEncode({
        'v': 1,
        'lines': [
          {'id': 'x'},
          {
            'id': 'arroz',
            'name': 'Arroz',
            'priceCents': 2490,
            'stock': 40,
            'quantity': 0,
          },
          {
            'id': 'agotado',
            'name': 'Azúcar',
            'priceCents': 450,
            'stock': 0,
            'quantity': 2,
          },
          {
            'id': 'aceite',
            'name': 'Aceite',
            'priceCents': 1090,
            'promoPriceCents': 'no es un número',
            'stock': 3,
            'quantity': 7,
          },
        ],
      });

      final cart = decodeCart(json);

      // La cantidad queda dentro del stock guardado.
      expect(lines(cart), [('aceite', 3)]);
      expect(cart.lines.single.product.promoPriceCents, isNull);
    });
  });

  group('el carrito', () {
    test('empieza con lo guardado y guarda cada cambio', () {
      final storage = MemoryCartStorage(const Cart([CartLine(rice, 1)]));
      final container = ProviderContainer.test(
        overrides: [cartStorageProvider.overrideWithValue(storage)],
      );

      expect(lines(container.read(cartProvider)), [('arroz', 1)]);

      container.read(cartProvider.notifier)
        ..add(oil, 2)
        ..setQuantity('arroz', 4);
      expect(lines(storage.load()), [('arroz', 4), ('aceite', 2)]);

      container.read(cartProvider.notifier).clear();
      expect(storage.load().isEmpty, isTrue);
    });

    test('sigue ahí al volver a abrir la app (un contenedor nuevo)', () {
      final storage = MemoryCartStorage();
      ProviderContainer.test(
        overrides: [cartStorageProvider.overrideWithValue(storage)],
      ).read(cartProvider.notifier).add(rice, 3);

      final reopened = ProviderContainer.test(
        overrides: [cartStorageProvider.overrideWithValue(storage)],
      );

      expect(lines(reopened.read(cartProvider)), [('arroz', 3)]);
    });
  });

  group('PrefsCartStorage', () {
    test('guarda en las preferencias y borra la clave al vaciarse', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = PrefsCartStorage(prefs);

      storage.save(const Cart([CartLine(oil, 1)]));
      expect(prefs.getString(PrefsCartStorage.key), isNotNull);
      expect(lines(PrefsCartStorage(prefs).load()), [('aceite', 1)]);

      storage.save(const Cart());
      expect(prefs.containsKey(PrefsCartStorage.key), isFalse);
    });
  });
}
