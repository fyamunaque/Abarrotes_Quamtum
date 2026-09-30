import type { CreateOrderItem, Money, Product } from '@abarrotes/shared-types';
import { toCents } from './money';

/** Tope por producto que acepta POST /orders. */
export const MAX_QUANTITY_PER_PRODUCT = 999;

/** Lo que el carrito guarda de cada producto (copia al momento de agregarlo). */
export interface CartProduct {
  productId: string;
  name: string;
  price: Money;
  imageUrl: string | null;
  stock: number;
}

export interface CartLine extends CartProduct {
  quantity: number;
}

export function toCartProduct(product: Product): CartProduct {
  return {
    productId: product.id,
    name: product.name,
    price: product.price,
    imageUrl: product.imageUrl,
    stock: product.currentStock,
  };
}

export function maxQuantityFor(product: CartProduct): number {
  return Math.min(product.stock, MAX_QUANTITY_PER_PRODUCT);
}

export function quantityOf(lines: CartLine[], productId: string): number {
  return lines.find((line) => line.productId === productId)?.quantity ?? 0;
}

/** Ajusta la cantidad al stock conocido; 0 o menos quita el producto. */
export function setQuantity(
  lines: CartLine[],
  product: CartProduct,
  quantity: number,
): CartLine[] {
  const allowed = Math.min(Math.trunc(quantity), maxQuantityFor(product));
  if (!(allowed > 0)) return removeFromCart(lines, product.productId);

  const line: CartLine = { ...product, quantity: allowed };
  return lines.some((l) => l.productId === product.productId)
    ? lines.map((l) => (l.productId === product.productId ? line : l))
    : [...lines, line];
}

export function addToCart(
  lines: CartLine[],
  product: CartProduct,
  quantity = 1,
): CartLine[] {
  return setQuantity(lines, product, quantityOf(lines, product.productId) + quantity);
}

export function removeFromCart(lines: CartLine[], productId: string): CartLine[] {
  return lines.filter((line) => line.productId !== productId);
}

export function cartCount(lines: CartLine[]): number {
  return lines.reduce((sum, line) => sum + line.quantity, 0);
}

export function lineTotalCents(line: CartLine): number {
  return toCents(line.price) * line.quantity;
}

/** Total referencial: el que vale es el que calcula el servidor al crear el pedido. */
export function cartTotalCents(lines: CartLine[]): number {
  return lines.reduce((sum, line) => sum + lineTotalCents(line), 0);
}

export function toOrderItems(lines: CartLine[]): CreateOrderItem[] {
  return lines.map(({ productId, quantity }) => ({ productId, quantity }));
}
