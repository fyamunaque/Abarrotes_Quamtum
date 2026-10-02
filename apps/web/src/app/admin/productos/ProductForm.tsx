'use client';

import type { Category, Product } from '@abarrotes/shared-types';
import Link from 'next/link';
import { useActionState } from 'react';
import type { ProductFormState } from '@/app/actions/admin';
import { toDateInputValue } from '@/lib/dates';
import type { ProductField } from '@/lib/product-form';

type SaveAction = (state: ProductFormState, formData: FormData) => Promise<ProductFormState>;

interface ProductFormProps {
  action: SaveAction;
  categories: Category[];
  /** Sin producto = alta. */
  product?: Product;
}

const initialState: ProductFormState = { error: null, fieldErrors: {} };

const inputClass =
  'rounded-xl border border-ink/20 px-4 py-2 font-normal outline-none focus:border-primary-dark focus:ring-2 focus:ring-primary-tint aria-invalid:border-red-600';

export function ProductForm({ action, categories, product }: ProductFormProps) {
  const [state, formAction, pending] = useActionState(action, initialState);
  const isNew = !product;

  // Tras un error se muestran los valores enviados; si no, los del producto.
  const value = (name: string, fallback: string) => state.values?.[name] ?? fallback;
  const errorFor = (field: ProductField) => state.fieldErrors[field];
  const fieldProps = (field: ProductField) => ({
    id: field,
    name: field,
    'aria-invalid': errorFor(field) ? true : undefined,
    'aria-describedby': errorFor(field) ? `${field}-error` : undefined,
    className: inputClass,
  });

  const activeDefault = state.values ? state.values.active === 'on' : (product?.active ?? true);

  return (
    <form action={formAction} className="flex flex-col gap-5 rounded-2xl border-2 border-ink/10 bg-cream p-6">
      <div className="grid gap-5 sm:grid-cols-2">
        <Field label="Nombre" field="name" error={errorFor('name')} className="sm:col-span-2">
          <input {...fieldProps('name')} required maxLength={150} defaultValue={value('name', product?.name ?? '')} />
        </Field>

        <Field label="Código (SKU)" field="sku" error={errorFor('sku')}>
          <input {...fieldProps('sku')} required maxLength={50} defaultValue={value('sku', product?.sku ?? '')} />
        </Field>

        <Field label="Categoría" field="categoryId" error={errorFor('categoryId')}>
          <select
            {...fieldProps('categoryId')}
            required
            defaultValue={value('categoryId', product?.categoryId ?? '')}
          >
            <option value="" disabled>
              Elige una categoría
            </option>
            {categories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name}
              </option>
            ))}
          </select>
        </Field>

        <Field label="Precio (S/)" field="price" error={errorFor('price')}>
          <input
            {...fieldProps('price')}
            required
            inputMode="decimal"
            placeholder="4.50"
            defaultValue={value('price', product?.price ?? '')}
          />
        </Field>

        {isNew ? (
          <Field label="Stock inicial" field="currentStock" error={errorFor('currentStock')}>
            <input
              {...fieldProps('currentStock')}
              type="number"
              min={0}
              step={1}
              defaultValue={value('currentStock', '0')}
            />
          </Field>
        ) : (
          <div className="flex flex-col gap-1 text-sm font-medium">
            Stock actual
            <p className="rounded-xl bg-ink/3 px-4 py-2 font-normal">{product.currentStock}</p>
            <p className="text-xs font-normal text-ink/60">
              Se ajusta con movimientos de inventario (entradas, salidas, ajustes).
            </p>
          </div>
        )}

        <Field label="Stock mínimo" field="minStock" error={errorFor('minStock')}>
          <input
            {...fieldProps('minStock')}
            type="number"
            min={0}
            step={1}
            defaultValue={value('minStock', String(product?.minStock ?? 0))}
          />
        </Field>

        <Field label="Vencimiento (opcional)" field="expirationDate" error={errorFor('expirationDate')}>
          <input
            {...fieldProps('expirationDate')}
            type="date"
            defaultValue={value('expirationDate', toDateInputValue(product?.expirationDate ?? null))}
          />
        </Field>

        <Field label="URL de la imagen (opcional)" field="imageUrl" error={errorFor('imageUrl')} className="sm:col-span-2">
          <input
            {...fieldProps('imageUrl')}
            type="url"
            placeholder="https://…"
            defaultValue={value('imageUrl', product?.imageUrl ?? '')}
          />
        </Field>

        <Field label="Descripción (opcional)" field="description" error={errorFor('description')} className="sm:col-span-2">
          <textarea
            {...fieldProps('description')}
            rows={4}
            maxLength={1000}
            defaultValue={value('description', product?.description ?? '')}
          />
        </Field>

        <label className="flex items-center gap-3 text-sm font-medium sm:col-span-2">
          <input type="checkbox" name="active" defaultChecked={activeDefault} className="h-4 w-4 accent-primary-dark" />
          Visible en la tienda
        </label>
      </div>

      {state.error && (
        <p role="alert" className="whitespace-pre-line rounded-xl bg-red-50 p-3 text-sm text-red-800">
          {state.error}
        </p>
      )}

      <div className="flex flex-wrap items-center gap-3">
        <button
          type="submit"
          disabled={pending}
          className="rounded-xl bg-primary px-5 py-2.5 font-semibold text-ink hover:bg-primary-dark hover:text-white disabled:cursor-wait disabled:bg-ink/15 disabled:text-ink/50"
        >
          {pending ? 'Guardando…' : isNew ? 'Crear producto' : 'Guardar cambios'}
        </button>
        <Link href="/admin/productos" className="font-medium text-ink/70 hover:underline">
          Cancelar
        </Link>
      </div>
    </form>
  );
}

function Field({
  label,
  field,
  error,
  className = '',
  children,
}: {
  label: string;
  field: ProductField;
  error?: string;
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <div className={`flex flex-col gap-1 text-sm font-medium ${className}`}>
      <label htmlFor={field}>{label}</label>
      {children}
      {error && (
        <p id={`${field}-error`} className="text-xs font-normal text-red-700">
          {error}
        </p>
      )}
    </div>
  );
}
