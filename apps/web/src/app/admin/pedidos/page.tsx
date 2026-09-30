import type { AdminOrder, OrderStatus } from '@abarrotes/shared-types';
import type { Metadata } from 'next';
import Link from 'next/link';
import { changeOrderStatus } from '@/app/actions/admin';
import { ActionButton } from '@/components/admin/ActionButton';
import { listOrders } from '@/lib/admin-api';
import { formatDateTime } from '@/lib/dates';
import { formatMoney } from '@/lib/money';
import { firstParam, parsePage } from '@/lib/navigation';
import {
  isOrderStatus,
  nextOrderStatuses,
  ORDER_STATUS_ACTION_LABELS,
  ORDER_STATUS_LABELS,
  ORDER_STATUSES,
} from '@/lib/orders';

export const metadata: Metadata = { title: 'Pedidos' };

const PAGE_SIZE = 20;

const statusColors: Record<OrderStatus, string> = {
  PENDING_CONFIRMATION: 'bg-amber-100 text-amber-900',
  CONFIRMED: 'bg-sky-100 text-sky-900',
  OUT_FOR_DELIVERY: 'bg-violet-100 text-violet-900',
  DELIVERED: 'bg-brand-100 text-brand-900',
  CANCELLED: 'bg-stone-200 text-stone-700',
};

function ordersHref(status: OrderStatus | undefined, page = 1): string {
  const params = new URLSearchParams();
  if (status) params.set('estado', status);
  if (page > 1) params.set('pagina', String(page));
  const query = params.toString();
  return query ? `/admin/pedidos?${query}` : '/admin/pedidos';
}

export default async function AdminOrdersPage({ searchParams }: PageProps<'/admin/pedidos'>) {
  const params = await searchParams;
  const statusParam = firstParam(params.estado);
  const status = isOrderStatus(statusParam) ? statusParam : undefined;
  const page = parsePage(firstParam(params.pagina));

  const { data: orders, meta } = await listOrders({ status, page, limit: PAGE_SIZE });

  return (
    <div className="flex flex-col gap-5">
      <h1 className="text-2xl font-bold">Pedidos</h1>

      <nav aria-label="Filtrar por estado" className="-mx-4 overflow-x-auto px-4">
        <ul className="flex gap-2 pb-1">
          {[undefined, ...ORDER_STATUSES].map((value) => {
            const active = value === status;
            return (
              <li key={value ?? 'todos'}>
                <Link
                  href={ordersHref(value)}
                  aria-current={active ? 'page' : undefined}
                  className={`whitespace-nowrap rounded-full border px-4 py-1.5 text-sm font-medium ${
                    active
                      ? 'border-brand-600 bg-brand-600 text-white'
                      : 'border-stone-300 bg-white hover:border-brand-600'
                  }`}
                >
                  {value ? ORDER_STATUS_LABELS[value] : 'Todos'}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      {orders.length === 0 ? (
        <p className="rounded-2xl border border-dashed border-stone-300 bg-white p-10 text-center text-stone-600">
          {status ? `No hay pedidos en estado “${ORDER_STATUS_LABELS[status]}”.` : 'Todavía no hay pedidos.'}
        </p>
      ) : (
        <ul className="flex flex-col gap-4">
          {orders.map((order) => (
            <OrderCard key={order.id} order={order} />
          ))}
        </ul>
      )}

      {meta.totalPages > 1 && (
        <nav aria-label="Páginas" className="flex items-center justify-center gap-3 text-sm">
          {page > 1 && (
            <Link href={ordersHref(status, page - 1)} className="font-semibold text-brand-700">
              ← Anterior
            </Link>
          )}
          <span className="text-stone-600">
            Página {meta.page} de {meta.totalPages}
          </span>
          {page < meta.totalPages && (
            <Link href={ordersHref(status, page + 1)} className="font-semibold text-brand-700">
              Siguiente →
            </Link>
          )}
        </nav>
      )}
    </div>
  );
}

function OrderCard({ order }: { order: AdminOrder }) {
  const next = nextOrderStatuses(order.status);

  return (
    <li className="flex flex-col gap-4 rounded-2xl border border-stone-200 bg-white p-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <p className="text-lg font-bold">Pedido N.º {order.id.slice(0, 8).toUpperCase()}</p>
          <p className="text-sm text-stone-500">{formatDateTime(order.createdAt)}</p>
        </div>
        <span className={`rounded-full px-3 py-1 text-sm font-semibold ${statusColors[order.status]}`}>
          {ORDER_STATUS_LABELS[order.status]}
        </span>
      </div>

      <div className="grid gap-4 text-sm sm:grid-cols-2">
        <div>
          <p className="font-semibold">{order.customer.name}</p>
          <p className="text-stone-600">{order.customer.phone ?? 'Sin teléfono'}</p>
          <p className="text-stone-600">{order.customer.email}</p>
          <p className="mt-2">
            <span className="font-medium">Entrega:</span> {order.deliveryAddress}
          </p>
        </div>
        <div>
          <ul className="divide-y divide-stone-100">
            {order.items.map((item) => (
              <li key={item.id} className="flex justify-between gap-3 py-1">
                <span>
                  {item.quantity} × {item.product.name}
                </span>
                <span className="tabular-nums text-stone-600">{formatMoney(item.unitPrice)} c/u</span>
              </li>
            ))}
          </ul>
          <p className="mt-2 text-right text-base font-bold">Total: {formatMoney(order.total)}</p>
        </div>
      </div>

      {next.length > 0 && (
        <div className="flex flex-wrap items-start gap-3 border-t border-stone-100 pt-4">
          {next.map((to) => (
            <ActionButton
              key={to}
              label={ORDER_STATUS_ACTION_LABELS[to]}
              action={changeOrderStatus.bind(null, order.id, to)}
              tone={to === 'CANCELLED' ? 'danger' : 'primary'}
              confirmMessage={
                to === 'CANCELLED'
                  ? '¿Cancelar este pedido? Se devolverá el stock de sus productos.'
                  : undefined
              }
            />
          ))}
        </div>
      )}
    </li>
  );
}
