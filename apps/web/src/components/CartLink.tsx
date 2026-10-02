'use client';

import Link from 'next/link';
import { useEffect, useRef } from 'react';
import { cartCount } from '@/lib/cart';
import { replayAnimation } from '@/lib/motion';
import { useCartHydrated, useCartStore } from '@/store/cart-store';

export function CartLink() {
  const count = useCartStore((state) => cartCount(state.lines));
  const hydrated = useCartHydrated();
  const icon = useRef<HTMLSpanElement>(null);
  const previous = useRef({ count, hydrated });

  // Pulso cuando el contador sube por algo que hizo la persona. Al cargar el carrito
  // guardado (hidratación) también sube, pero entonces el render anterior aún no estaba
  // hidratado y no se anima.
  useEffect(() => {
    const before = previous.current;
    if (before.hydrated && count > before.count) {
      replayAnimation(icon.current, 'animate-cart-pulse');
    }
    previous.current = { count, hydrated };
  }, [count, hydrated]);

  return (
    <Link
      href="/carrito"
      className="inline-flex items-center gap-3 rounded-xl px-3 py-2 font-medium hover:bg-ink/5"
    >
      <span ref={icon} className="relative inline-flex motion-reduce:animate-none">
        <CartIcon />
        {count > 0 && (
          <span className="absolute -top-2 -right-2.5 min-w-5 rounded-full bg-accent px-1 text-center text-xs leading-5 font-bold text-cream tabular-nums">
            {count}
            <span className="sr-only"> productos</span>
          </span>
        )}
      </span>
      <span>Carrito</span>
    </Link>
  );
}

function CartIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      focusable="false"
      className="h-6 w-6 fill-none stroke-ink stroke-2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M3 4h2l2.4 10.2a1.5 1.5 0 0 0 1.5 1.1h8.4a1.5 1.5 0 0 0 1.4-1l2-6.3H6.2" />
      <circle cx="9.5" cy="19.5" r="1.3" />
      <circle cx="17" cy="19.5" r="1.3" />
    </svg>
  );
}
