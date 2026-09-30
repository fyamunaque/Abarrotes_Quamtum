'use client';

import { useEffect } from 'react';
import { useCartStore } from '@/store/cart-store';

/** Carga el carrito guardado en localStorage una vez montada la página. */
export function CartHydrator() {
  useEffect(() => {
    void useCartStore.persist.rehydrate();
  }, []);
  return null;
}
