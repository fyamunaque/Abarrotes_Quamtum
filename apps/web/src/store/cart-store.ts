import { useSyncExternalStore } from 'react';
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import {
  addToCart,
  type CartLine,
  type CartProduct,
  removeFromCart,
  setQuantity,
} from '@/lib/cart';

interface CartState {
  lines: CartLine[];
  add: (product: CartProduct, quantity?: number) => void;
  setQuantity: (productId: string, quantity: number) => void;
  remove: (productId: string) => void;
  clear: () => void;
}

/**
 * Carrito del navegador, guardado en localStorage. `skipHydration`: el servidor no
 * conoce el carrito, así que se carga recién en el cliente (CartHydrator) para que el
 * primer render coincida con el HTML del servidor.
 */
export const useCartStore = create<CartState>()(
  persist(
    (set) => ({
      lines: [],
      add: (product, quantity = 1) =>
        set((state) => ({ lines: addToCart(state.lines, product, quantity) })),
      setQuantity: (productId, quantity) =>
        set((state) => {
          const line = state.lines.find((l) => l.productId === productId);
          return line ? { lines: setQuantity(state.lines, line, quantity) } : state;
        }),
      remove: (productId) =>
        set((state) => ({ lines: removeFromCart(state.lines, productId) })),
      clear: () => set({ lines: [] }),
    }),
    {
      name: 'abarrotes-cart',
      version: 1,
      skipHydration: true,
      partialize: (state) => ({ lines: state.lines }),
    },
  ),
);

/** `true` una vez cargado el carrito desde localStorage. */
export function useCartHydrated(): boolean {
  return useSyncExternalStore(
    (onChange) => useCartStore.persist.onFinishHydration(onChange),
    () => useCartStore.persist.hasHydrated(),
    () => false,
  );
}
