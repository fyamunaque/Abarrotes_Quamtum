import type { Metadata } from 'next';
import { createProduct } from '@/app/actions/admin';
import { getCategories } from '@/lib/api';
import { ProductForm } from '../ProductForm';

export const metadata: Metadata = { title: 'Nuevo producto' };

export default async function NewProductPage() {
  const categories = await getCategories();

  return (
    <div className="flex flex-col gap-5">
      <h1 className="text-2xl font-bold">Nuevo producto</h1>
      <ProductForm action={createProduct} categories={categories} />
    </div>
  );
}
