'use client';

import Link from 'next/link';
import { ProductImage } from '@/components/ProductImage';
import { QuantityStepper } from '@/components/QuantityStepper';
import { cartTotalCents, lineTotalCents, maxQuantityFor } from '@/lib/cart';
import { formatCents, formatMoney } from '@/lib/money';
import { useCartHydrated, useCartStore } from '@/store/cart-store';

export function CartView() {
  const hydrated = useCartHydrated();
  const lines = useCartStore((state) => state.lines);
  const setQuantity = useCartStore((state) => state.setQuantity);
  const remove = useCartStore((state) => state.remove);

  if (!hydrated) {
    return <div role="status" className="h-40 animate-pulse rounded-2xl bg-ink/10" />;
  }

  if (lines.length === 0) {
    return (
      <div className="rounded-2xl border-2 border-dashed border-ink/15 bg-cream p-10 text-center">
        <p className="text-lg font-medium">Tu carrito está vacío.</p>
        <Link href="/" className="mt-3 inline-block font-semibold text-primary-dark hover:underline">
          Ver productos
        </Link>
      </div>
    );
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_20rem]">
      <ul className="divide-y divide-ink/10 rounded-2xl border-2 border-ink/10 bg-cream">
        {lines.map((line) => (
          <li key={line.productId} className="flex flex-wrap items-center gap-4 p-4">
            <ProductImage src={line.imageUrl} alt={line.name} className="h-16 w-16 shrink-0" />
            <div className="min-w-40 flex-1">
              <Link
                href={`/productos/${line.productId}`}
                className="font-semibold hover:text-primary-dark"
              >
                {line.name}
              </Link>
              <p className="text-sm text-ink/60">{formatMoney(line.price)} c/u</p>
            </div>
            <QuantityStepper
              quantity={line.quantity}
              max={maxQuantityFor(line)}
              onChange={(quantity) => setQuantity(line.productId, quantity)}
              label={line.name}
            />
            <span className="w-24 text-right font-semibold tabular-nums">
              {formatCents(lineTotalCents(line))}
            </span>
            <button
              type="button"
              onClick={() => remove(line.productId)}
              className="text-sm font-medium text-red-700 hover:underline"
            >
              Quitar
            </button>
          </li>
        ))}
      </ul>

      <aside className="flex h-fit flex-col gap-4 rounded-2xl border-2 border-ink/10 bg-cream p-5">
        <div className="flex items-baseline justify-between">
          <span className="text-lg font-semibold">Total</span>
          <span className="text-2xl font-bold text-primary-dark">
            {formatCents(cartTotalCents(lines))}
          </span>
        </div>
        <p className="text-xs text-ink/60">
          Los precios y el stock se confirman al generar el pedido.
        </p>
        <Link
          href="/checkout"
          className="rounded-xl bg-primary px-5 py-3 text-center font-semibold text-ink hover:bg-primary-dark hover:text-white"
        >
          Continuar con el pedido
        </Link>
        <Link href="/" className="text-center text-sm font-medium text-primary-dark hover:underline">
          Seguir comprando
        </Link>
      </aside>
    </div>
  );
}
