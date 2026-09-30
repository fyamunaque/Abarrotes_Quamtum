import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { updateProduct } from '@/app/actions/admin';
import { getProductForAdmin, getStaffUser } from '@/lib/admin-api';
import { getCategories } from '@/lib/api';
import { ProductForm } from '../ProductForm';

export const metadata: Metadata = { title: 'Editar producto' };

export default async function EditProductPage({ params }: PageProps<'/admin/productos/[id]'>) {
  if (!(await getStaffUser())) return null;
  const { id } = await params;
  // Con el token del staff: incluye productos inactivos.
  const [product, categories] = await Promise.all([getProductForAdmin(id), getCategories()]);
  if (!product) notFound();

  return (
    <div className="flex flex-col gap-5">
      <h1 className="text-2xl font-bold">Editar producto</h1>
      <ProductForm
        action={updateProduct.bind(null, product.id)}
        categories={categories}
        product={product}
      />
    </div>
  );
}
