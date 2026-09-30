import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { formatMoney } from '@/lib/money';
import { firstParam, isUuid } from '@/lib/navigation';
import { orderStatusLabel } from '@/lib/orders';

export const metadata: Metadata = { title: 'Pedido recibido' };

// Los datos llegan en la URL desde el checkout; solo se muestran, no autorizan nada.
export default async function OrderPlacedPage({
  searchParams,
}: PageProps<'/checkout/confirmado'>) {
  const params = await searchParams;
  const orderId = firstParam(params.pedido);
  const total = firstParam(params.total);
  const status = firstParam(params.estado) ?? 'PENDING_CONFIRMATION';
  if (!isUuid(orderId) || !total || !Number.isFinite(Number(total))) redirect('/');

  return (
    <div className="mx-auto flex max-w-lg flex-col items-center gap-3 rounded-2xl border border-stone-200 bg-white p-10 text-center">
      <span aria-hidden className="text-5xl">
        ✅
      </span>
      <h1 className="text-2xl font-bold">¡Pedido recibido!</h1>
      {/* Número corto para dictarlo por teléfono; el id completo queda en el dashboard. */}
      <p className="text-lg font-semibold">Pedido N.º {orderId.slice(0, 8).toUpperCase()}</p>
      <p>Total: {formatMoney(total)}</p>
      <p className="text-stone-600">Estado: {orderStatusLabel(status)}</p>
      <p className="text-sm text-stone-500">La tienda confirmará tu pedido antes de enviarlo.</p>
      <Link
        href="/"
        className="mt-4 rounded-xl bg-brand-600 px-5 py-2 font-semibold text-white hover:bg-brand-700"
      >
        Seguir comprando
      </Link>
    </div>
  );
}
