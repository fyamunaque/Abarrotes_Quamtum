import { describe, expect, it } from 'vitest';
import {
  addToCart,
  cartCount,
  cartTotalCents,
  type CartProduct,
  MAX_QUANTITY_PER_PRODUCT,
  removeFromCart,
  setQuantity,
  toOrderItems,
} from './cart';

const arroz: CartProduct = { productId: 'arroz', name: 'Arroz 1kg', price: '4.5', imageUrl: null, stock: 10 };
const aceite: CartProduct = { productId: 'aceite', name: 'Aceite 1L', price: '9.9', imageUrl: null, stock: 3 };

describe('carrito', () => {
  it('agregar el mismo producto suma en una sola línea', () => {
    const lines = addToCart(addToCart(addToCart([], arroz), arroz), aceite);

    expect(lines).toHaveLength(2);
    expect(lines[0].quantity).toBe(2);
    expect(cartCount(lines)).toBe(3);
  });

  it('calcula el total en céntimos sin errores de coma flotante', () => {
    // 3 × 4.50 + 1 × 9.90 = 23.40 (con floats: 23.400000000000002)
    const lines = addToCart(setQuantity([], arroz, 3), aceite);

    expect(cartTotalCents(lines)).toBe(2340);
  });

  it('no deja pasar del stock ni del tope de la API', () => {
    expect(setQuantity([], aceite, 50)[0].quantity).toBe(3);

    const sal = { ...arroz, productId: 'sal', stock: 5000 };
    expect(setQuantity([], sal, 2000)[0].quantity).toBe(MAX_QUANTITY_PER_PRODUCT);
  });

  it('bajar a cero o quitar elimina la línea', () => {
    const lines = addToCart([], arroz);

    expect(setQuantity(lines, arroz, 0)).toEqual([]);
    expect(removeFromCart(lines, 'arroz')).toEqual([]);
  });

  it('un producto agotado no entra', () => {
    expect(addToCart([], { ...arroz, stock: 0 })).toEqual([]);
  });

  it('el pedido solo lleva id y cantidad, nunca precios', () => {
    const lines = addToCart(setQuantity([], arroz, 2), aceite);

    expect(toOrderItems(lines)).toEqual([
      { productId: 'arroz', quantity: 2 },
      { productId: 'aceite', quantity: 1 },
    ]);
  });
});
