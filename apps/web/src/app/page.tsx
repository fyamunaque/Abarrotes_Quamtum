import type { Category } from '@abarrotes/shared-types';
import Form from 'next/form';
import Link from 'next/link';
import { ProductCard } from '@/components/ProductCard';
import { getCategories, getProducts } from '@/lib/api';
import { catalogHref, firstParam, isUuid, parsePage } from '@/lib/navigation';

const PAGE_SIZE = 24;

export default async function CatalogPage({ searchParams }: PageProps<'/'>) {
  const params = await searchParams;
  const categoryParam = firstParam(params.categoria);
  const categoryId = isUuid(categoryParam) ? categoryParam : undefined;
  const search = firstParam(params.q)?.trim().slice(0, 100) || undefined;
  const page = parsePage(firstParam(params.pagina));

  const [categories, { data: products, meta }] = await Promise.all([
    getCategories(),
    getProducts({ categoryId, search, page, limit: PAGE_SIZE }),
  ]);
  const categoryName = categories.find((c) => c.id === categoryId)?.name;

  return (
    <div className="flex flex-col gap-6">
      <section className="flex flex-col gap-4">
        <h1 className="text-2xl font-bold">
          {categoryName ?? 'Todos los productos'}
          {search && <span className="text-stone-500"> · “{search}”</span>}
        </h1>
        <SearchForm search={search} categoryId={categoryId} />
        <CategoryFilter categories={categories} selectedId={categoryId} search={search} />
      </section>

      {products.length === 0 ? (
        <EmptyResults search={search} hasFilters={Boolean(search || categoryId || page > 1)} />
      ) : (
        <ul className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {products.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </ul>
      )}

      <Pagination
        page={meta.page}
        totalPages={meta.totalPages}
        hrefFor={(p) => catalogHref({ categoryId, search, page: p })}
      />
    </div>
  );
}

function SearchForm({ search, categoryId }: { search?: string; categoryId?: string }) {
  return (
    // next/form: al enviar navega a /?q=... sin recargar la página.
    <Form action="/" className="flex gap-2" role="search">
      {categoryId && <input type="hidden" name="categoria" value={categoryId} />}
      <label htmlFor="q" className="sr-only">
        Buscar productos
      </label>
      <input
        id="q"
        name="q"
        type="search"
        defaultValue={search}
        placeholder="Buscar por nombre o código"
        maxLength={100}
        className="w-full rounded-xl border border-stone-300 bg-white px-4 py-2 outline-none focus:border-brand-600 focus:ring-2 focus:ring-brand-200"
      />
      <button
        type="submit"
        className="rounded-xl bg-brand-600 px-5 py-2 font-semibold text-white hover:bg-brand-700"
      >
        Buscar
      </button>
    </Form>
  );
}

function CategoryFilter({
  categories,
  selectedId,
  search,
}: {
  categories: Category[];
  selectedId?: string;
  search?: string;
}) {
  const chip = (active: boolean) =>
    `whitespace-nowrap rounded-full border px-4 py-1.5 text-sm font-medium ${
      active
        ? 'border-brand-600 bg-brand-600 text-white'
        : 'border-stone-300 bg-white hover:border-brand-600 hover:text-brand-700'
    }`;

  return (
    <nav aria-label="Categorías" className="-mx-4 overflow-x-auto px-4">
      <ul className="flex gap-2 pb-1">
        <li>
          <Link
            href={catalogHref({ search })}
            className={chip(!selectedId)}
            aria-current={!selectedId ? 'page' : undefined}
          >
            Todas
          </Link>
        </li>
        {categories.map((category) => {
          const active = category.id === selectedId;
          return (
            <li key={category.id}>
              <Link
                href={catalogHref({ categoryId: category.id, search })}
                className={chip(active)}
                aria-current={active ? 'page' : undefined}
              >
                {category.name}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

function EmptyResults({ search, hasFilters }: { search?: string; hasFilters: boolean }) {
  return (
    <div className="rounded-2xl border border-dashed border-stone-300 bg-white p-10 text-center">
      <p className="text-lg font-medium">
        {search ? `No encontramos productos para “${search}”.` : 'No hay productos para mostrar.'}
      </p>
      {hasFilters && (
        <Link href="/" className="mt-3 inline-block font-semibold text-brand-700 hover:underline">
          Ver todos los productos
        </Link>
      )}
    </div>
  );
}

function Pagination({
  page,
  totalPages,
  hrefFor,
}: {
  page: number;
  totalPages: number;
  hrefFor: (page: number) => string;
}) {
  if (totalPages <= 1) return null;
  const link = 'rounded-xl border border-stone-300 bg-white px-4 py-2 font-medium hover:border-brand-600';

  return (
    <nav aria-label="Páginas" className="flex items-center justify-center gap-3">
      {page > 1 && (
        <Link href={hrefFor(page - 1)} className={link}>
          ← Anterior
        </Link>
      )}
      <span className="text-sm text-stone-600">
        Página {page} de {totalPages}
      </span>
      {page < totalPages && (
        <Link href={hrefFor(page + 1)} className={link}>
          Siguiente →
        </Link>
      )}
    </nav>
  );
}
