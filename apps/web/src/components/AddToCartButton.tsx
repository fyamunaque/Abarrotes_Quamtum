'use client';

import { useRef } from 'react';
import { type CartProduct, maxQuantityFor, quantityOf } from '@/lib/cart';
import { replayAnimation } from '@/lib/motion';
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
  // El rebote va en este contenedor, que no cambia: al presionar "Agregar" el botón se
  // convierte en el contador, y el rebote se ve sobre el control ya transformado.
  const control = useRef<HTMLDivElement>(null);
  const bounce = () => replayAnimation(control.current, 'animate-press-bounce');

  const padding = size === 'lg' ? 'px-6 py-3 text-base' : 'px-4 py-2 text-sm';

  if (product.stock <= 0) {
    return (
      <span className={`inline-block rounded-full bg-ink/5 font-medium text-ink/60 ${padding}`}>
        Agotado
      </span>
    );
  }

  return (
    <div ref={control} className="inline-flex motion-reduce:animate-none">
      {quantity === 0 ? (
        <button
          type="button"
          onClick={() => {
            add(product);
            bounce();
          }}
          // En la tarjeta el texto visible es solo "Agregar": el nombre accesible dice qué.
          aria-label={size === 'md' ? `Agregar ${product.name} al carrito` : undefined}
          // Texto ink sobre primary (5,9:1); el blanco solo daría 3,3:1.
          className={`rounded-full bg-primary font-semibold text-ink hover:bg-primary-dark hover:text-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink ${padding}`}
        >
          {size === 'md' ? 'Agregar' : 'Agregar al carrito'}
        </button>
      ) : (
        <QuantityStepper
          quantity={quantity}
          max={maxQuantityFor(product)}
          onChange={(next) => {
            setQuantity(product.productId, next);
            if (next > quantity) bounce();
          }}
          label={product.name}
        />
      )}
    </div>
  );
}
