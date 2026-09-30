'use client';

import Link from 'next/link';
import { cartCount } from '@/lib/cart';
import { useCartStore } from '@/store/cart-store';

export function CartLink() {
  const count = useCartStore((state) => cartCount(state.lines));

  return (
    <Link
      href="/carrito"
      className="relative inline-flex items-center gap-2 rounded-xl px-3 py-2 font-medium hover:bg-brand-50"
    >
      <span aria-hidden>🛒</span>
      <span>Carrito</span>
      {count > 0 && (
        <span className="rounded-full bg-accent-600 px-2 py-0.5 text-xs font-bold text-white">
          {count}
          <span className="sr-only"> productos</span>
        </span>
      )}
    </Link>
  );
}
