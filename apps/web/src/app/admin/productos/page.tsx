import type { Metadata } from 'next';
import Form from 'next/form';
import Link from 'next/link';
import { setProductActive } from '@/app/actions/admin';
import { ActionButton } from '@/components/admin/ActionButton';
import { listProductsForAdmin } from '@/lib/admin-api';
import { formatMoney } from '@/lib/money';
import { firstParam, parsePage } from '@/lib/navigation';

export const metadata: Metadata = { title: 'Productos' };

const PAGE_SIZE = 25;

function productsHref(search: string | undefined, page: number): string {
  const params = new URLSearchParams();
  if (search) params.set('q', search);
  if (page > 1) params.set('pagina', String(page));
  const query = params.toString();
  return query ? `/admin/productos?${query}` : '/admin/productos';
}

export default async function AdminProductsPage({ searchParams }: PageProps<'/admin/productos'>) {
  const params = await searchParams;
  const search = firstParam(params.q)?.trim().slice(0, 100) || undefined;
  const page = parsePage(firstParam(params.pagina));
  const saved = firstParam(params.guardado) === '1';

  const { data: products, meta } = await listProductsForAdmin({ search, page, limit: PAGE_SIZE });

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">Productos</h1>
        <Link
          href="/admin/productos/nuevo"
          className="rounded-xl bg-brand-600 px-4 py-2 font-semibold text-white hover:bg-brand-700"
        >
          Nuevo producto
        </Link>
      </div>

      {saved && (
        <p role="status" className="rounded-xl bg-brand-50 p-3 text-sm text-brand-900">
          Producto guardado.
        </p>
      )}

      <Form action="/admin/productos" className="flex gap-2" role="search">
        <label htmlFor="q" className="sr-only">
          Buscar productos
        </label>
        <input
          id="q"
          name="q"
          type="search"
          defaultValue={search}
          placeholder="Buscar por nombre o SKU"
          className="w-full rounded-xl border border-stone-300 bg-white px-4 py-2"
        />
        <button type="submit" className="rounded-xl border border-stone-300 bg-white px-4 py-2 font-medium">
          Buscar
        </button>
      </Form>

      <div className="overflow-x-auto rounded-2xl border border-stone-200 bg-white">
        <table className="w-full text-left text-sm">
          <thead className="bg-stone-50 text-stone-600">
            <tr>
              <th className="px-4 py-3 font-medium">Producto</th>
              <th className="px-4 py-3 font-medium">Categoría</th>
              <th className="px-4 py-3 text-right font-medium">Precio</th>
              <th className="px-4 py-3 text-right font-medium">Stock</th>
              <th className="px-4 py-3 font-medium">Estado</th>
              <th className="px-4 py-3 font-medium">
                <span className="sr-only">Acciones</span>
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-stone-100">
            {products.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-10 text-center text-stone-600">
                  {search ? `Sin resultados para “${search}”.` : 'Todavía no hay productos.'}
                </td>
              </tr>
            )}
            {products.map((product) => {
              const lowStock = product.currentStock <= product.minStock;
              return (
                <tr key={product.id} className={product.active ? '' : 'bg-stone-50 text-stone-500'}>
                  <td className="px-4 py-3">
                    <p className="font-semibold">{product.name}</p>
                    <p className="text-xs text-stone-500">{product.sku}</p>
                  </td>
                  <td className="px-4 py-3">{product.category.name}</td>
                  <td className="px-4 py-3 text-right tabular-nums">{formatMoney(product.price)}</td>
                  <td className="px-4 py-3 text-right tabular-nums">
                    {product.currentStock}
                    {lowStock && (
                      <span className="ml-2 rounded bg-amber-100 px-1.5 py-0.5 text-xs font-semibold text-amber-900">
                        Bajo
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3">{product.active ? 'Activo' : 'Inactivo'}</td>
                  <td className="px-4 py-3">
                    <div className="flex items-start justify-end gap-2">
                      <Link
                        href={`/admin/productos/${product.id}`}
                        className="rounded-lg border border-stone-300 px-3 py-1.5 text-sm font-semibold hover:border-brand-600"
                      >
                        Editar
                      </Link>
                      <ActionButton
                        label={product.active ? 'Desactivar' : 'Reactivar'}
                        action={setProductActive.bind(null, product.id, !product.active)}
                        tone={product.active ? 'danger' : 'secondary'}
                      />
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {meta.totalPages > 1 && (
        <nav aria-label="Páginas" className="flex items-center justify-center gap-3 text-sm">
          {page > 1 && (
            <Link href={productsHref(search, page - 1)} className="font-semibold text-brand-700">
              ← Anterior
            </Link>
          )}
          <span className="text-stone-600">
            Página {meta.page} de {meta.totalPages}
          </span>
          {page < meta.totalPages && (
            <Link href={productsHref(search, page + 1)} className="font-semibold text-brand-700">
              Siguiente →
            </Link>
          )}
        </nav>
      )}
    </div>
  );
}
