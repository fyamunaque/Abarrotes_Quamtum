import type { Product } from '@abarrotes/shared-types';
import Link from 'next/link';
import { toCartProduct } from '@/lib/cart';
import { AddToCartButton } from './AddToCartButton';
import { Price } from './Price';
import { ProductImage } from './ProductImage';

/**
 * Tarjeta del catálogo: fondo crema con borde de tinta al 10 %, sin sombra. El precio
 * lleva el trazo del logo y "Agregar" rebota al sumar (ver AddToCartButton).
 */
export function ProductCard({ product }: { product: Product }) {
  return (
    <li className="flex flex-col gap-3 rounded-2xl border-2 border-ink/10 bg-cream p-3">
      <Link
        href={`/productos/${product.id}`}
        className="group flex flex-1 flex-col gap-2 rounded-xl focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink"
      >
        <ProductImage src={product.imageUrl} alt={product.name} className="aspect-square" />
        <span className="text-sm text-ink/60">{product.category.name}</span>
        <span className="line-clamp-2 leading-snug font-semibold group-hover:text-primary-dark">
          {product.name}
        </span>
      </Link>
      <div className="flex flex-wrap items-end justify-between gap-2">
        <Price amount={product.price} />
        <AddToCartButton product={toCartProduct(product)} />
      </div>
    </li>
  );
}
