'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState, useTransition } from 'react';
import { placeOrder } from '@/app/actions/orders';
import { cartTotalCents, lineTotalCents, toOrderItems } from '@/lib/cart';
import { formatCents } from '@/lib/money';
import { useCartHydrated, useCartStore } from '@/store/cart-store';

interface CheckoutFormProps {
  userName: string;
  defaultAddress: string;
}

export function CheckoutForm({ userName, defaultAddress }: CheckoutFormProps) {
  const router = useRouter();
  const hydrated = useCartHydrated();
  const lines = useCartStore((state) => state.lines);
  const clearCart = useCartStore((state) => state.clear);
  const [address, setAddress] = useState(defaultAddress);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  if (!hydrated) {
    return <div role="status" className="h-40 animate-pulse rounded-2xl bg-ink/10" />;
  }

  if (lines.length === 0) {
    return (
      <div className="rounded-2xl border-2 border-dashed border-ink/15 bg-cream p-10 text-center">
        <p className="text-lg font-medium">No hay productos en tu carrito.</p>
        <Link href="/" className="mt-3 inline-block font-semibold text-primary-dark hover:underline">
          Ver productos
        </Link>
      </div>
    );
  }

  function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    startTransition(async () => {
      const result = await placeOrder({ deliveryAddress: address, items: toOrderItems(lines) });
      if (result.ok) {
        clearCart();
        const params = new URLSearchParams({
          pedido: result.order.id,
          total: result.order.total,
          estado: result.order.status,
        });
        router.replace(`/checkout/confirmado?${params}`);
      } else if (result.sessionExpired) {
        router.push('/ingresar?next=/checkout');
      } else {
        // El carrito se conserva: el cliente puede ajustar cantidades y reintentar.
        setError(result.error);
      }
    });
  }

  return (
    <form onSubmit={submit} className="grid gap-6 lg:grid-cols-[1fr_20rem]">
      <section className="flex flex-col gap-4 rounded-2xl border-2 border-ink/10 bg-cream p-5">
        <h2 className="font-semibold">Entrega</h2>
        <p className="text-sm text-ink/70">Pedido a nombre de {userName}.</p>
        <label htmlFor="address" className="text-sm font-medium">
          Dirección de entrega
        </label>
        <textarea
          id="address"
          name="address"
          required
          maxLength={255}
          rows={3}
          value={address}
          onChange={(event) => setAddress(event.target.value)}
          className="rounded-xl border border-ink/20 px-4 py-2 outline-none focus:border-primary-dark focus:ring-2 focus:ring-primary-tint"
        />

        <h2 className="mt-2 font-semibold">Productos</h2>
        <ul className="divide-y divide-ink/5 text-sm">
          {lines.map((line) => (
            <li key={line.productId} className="flex justify-between gap-4 py-2">
              <span>
                {line.quantity} × {line.name}
              </span>
              <span className="tabular-nums">{formatCents(lineTotalCents(line))}</span>
            </li>
          ))}
        </ul>
        <Link href="/carrito" className="text-sm font-medium text-primary-dark hover:underline">
          Modificar carrito
        </Link>
      </section>

      <aside className="flex h-fit flex-col gap-4 rounded-2xl border-2 border-ink/10 bg-cream p-5">
        <div className="flex items-baseline justify-between">
          <span className="text-lg font-semibold">Total</span>
          <span className="text-2xl font-bold text-primary-dark">
            {formatCents(cartTotalCents(lines))}
          </span>
        </div>
        <p className="text-xs text-ink/60">
          La tienda confirma el pedido con los precios y el stock vigentes.
        </p>
        {error && (
          <p role="alert" className="whitespace-pre-line rounded-xl bg-red-50 p-3 text-sm text-red-800">
            {error}
          </p>
        )}
        <button
          type="submit"
          disabled={pending || !address.trim()}
          className="rounded-xl bg-primary px-5 py-3 font-semibold text-ink hover:bg-primary-dark hover:text-white disabled:cursor-not-allowed disabled:bg-ink/15 disabled:text-ink/50"
        >
          {pending ? 'Enviando pedido…' : 'Generar pedido'}
        </button>
      </aside>
    </form>
  );
}
