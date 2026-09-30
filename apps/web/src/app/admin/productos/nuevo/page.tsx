import type { Metadata } from 'next';
import { createProduct } from '@/app/actions/admin';
import { getStaffUser } from '@/lib/admin-api';
import { getCategories } from '@/lib/api';
import { ProductForm } from '../ProductForm';

export const metadata: Metadata = { title: 'Nuevo producto' };

export default async function NewProductPage() {
  if (!(await getStaffUser())) return null;
  const categories = await getCategories();

  return (
    <div className="flex flex-col gap-5">
      <h1 className="text-2xl font-bold">Nuevo producto</h1>
      <ProductForm action={createProduct} categories={categories} />
    </div>
  );
}
