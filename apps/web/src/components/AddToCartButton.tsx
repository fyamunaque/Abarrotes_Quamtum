'use client';

import { type CartProduct, maxQuantityFor, quantityOf } from '@/lib/cart';
import { useCartStore } from '@/store/cart-store';
import { QuantityStepper } from './QuantityStepper';

interface AddToCartButtonProps {
  product: CartProduct;
  size?: 'md' | 'lg';
}

export function AddToCartButton({ product, size = 'md' }: AddToCartButtonProps) {
  const quantity = useCartStore((state) => quantityOf(state.lines, product.productId));
  const add = useCartStore((state) => state.add);
  const setQuantity = useCartStore((state) => state.setQuantity);

  const padding = size === 'lg' ? 'px-6 py-3 text-base' : 'px-4 py-2 text-sm';

  if (product.stock <= 0) {
    return (
      <span className={`inline-block rounded-xl bg-stone-100 font-medium text-stone-500 ${padding}`}>
        Agotado
      </span>
    );
  }

  if (quantity === 0) {
    return (
      <button
        type="button"
        onClick={() => add(product)}
        className={`rounded-xl bg-brand-600 font-semibold text-white hover:bg-brand-700 ${padding}`}
      >
        Agregar al carrito
      </button>
    );
  }

  return (
    <QuantityStepper
      quantity={quantity}
      max={maxQuantityFor(product)}
      onChange={(next) => setQuantity(product.productId, next)}
      label={product.name}
    />
  );
}
