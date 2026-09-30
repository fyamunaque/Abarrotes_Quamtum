import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { AddToCartButton } from '@/components/AddToCartButton';
import { ProductImage } from '@/components/ProductImage';
import { getProduct } from '@/lib/api';
import { toCartProduct } from '@/lib/cart';
import { formatMoney } from '@/lib/money';
import { catalogHref } from '@/lib/navigation';

export async function generateMetadata({
  params,
}: PageProps<'/productos/[id]'>): Promise<Metadata> {
  const { id } = await params;
  const product = await getProduct(id);
  return product
    ? { title: product.name, description: product.description ?? undefined }
    : { title: 'Producto no encontrado' };
}

export default async function ProductPage({ params }: PageProps<'/productos/[id]'>) {
  const { id } = await params;
  // Misma petición que generateMetadata: Next.js la hace una sola vez.
  const product = await getProduct(id);
  if (!product) notFound();

  const inStock = product.currentStock > 0;

  return (
    <div className="flex flex-col gap-6">
      <nav aria-label="Ruta" className="text-sm text-stone-500">
        <Link href="/" className="hover:text-brand-700">
          Productos
        </Link>
        {' / '}
        <Link
          href={catalogHref({ categoryId: product.category.id })}
          className="hover:text-brand-700"
        >
          {product.category.name}
        </Link>
      </nav>

      <article className="grid gap-8 rounded-2xl border border-stone-200 bg-white p-5 md:grid-cols-2">
        <ProductImage src={product.imageUrl} alt={product.name} className="aspect-square" />
        <div className="flex flex-col gap-4">
          <h1 className="text-3xl font-bold">{product.name}</h1>
          <p className="text-3xl font-bold text-brand-700">{formatMoney(product.price)}</p>
          <p className={inStock ? 'text-stone-600' : 'font-medium text-red-700'}>
            {inStock ? `Disponibles: ${product.currentStock}` : 'Agotado'}
          </p>
          {product.description && (
            <p className="whitespace-pre-line leading-relaxed text-stone-700">
              {product.description}
            </p>
          )}
          <div className="flex flex-wrap items-center gap-3">
            <AddToCartButton product={toCartProduct(product)} size="lg" />
            <Link href="/carrito" className="font-semibold text-brand-700 hover:underline">
              Ver carrito
            </Link>
          </div>
          <p className="text-xs text-stone-500">Código: {product.sku}</p>
        </div>
      </article>
    </div>
  );
}
