import type { Product } from '@abarrotes/shared-types';
import Link from 'next/link';
import { toCartProduct } from '@/lib/cart';
import { formatMoney } from '@/lib/money';
import { AddToCartButton } from './AddToCartButton';
import { ProductImage } from './ProductImage';

export function ProductCard({ product }: { product: Product }) {
  return (
    <li className="flex flex-col rounded-2xl border-2 border-ink/10 bg-cream p-3 shadow-sm">
      <Link href={`/productos/${product.id}`} className="group flex flex-1 flex-col gap-2">
        <ProductImage src={product.imageUrl} alt={product.name} className="aspect-square" />
        <span className="text-xs font-medium uppercase tracking-wide text-ink/60">
          {product.category.name}
        </span>
        <span className="line-clamp-2 font-semibold group-hover:text-primary-dark">
          {product.name}
        </span>
      </Link>
      <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
        <span className="text-lg font-bold text-primary-dark">{formatMoney(product.price)}</span>
        <AddToCartButton product={toCartProduct(product)} />
      </div>
    </li>
  );
}
