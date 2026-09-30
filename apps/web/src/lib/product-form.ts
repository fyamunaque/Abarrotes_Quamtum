import type { CreateProductRequest, UpdateProductRequest } from '@abarrotes/shared-types';
import { isUuid } from './navigation';

// Mismos límites que CreateProductDto en la API. Validar aquí permite marcar cada campo;
// la API vuelve a validar todo.
const MAX_PRICE = 99_999_999.99;
const PRICE = /^\d+(?:[.,]\d{1,2})?$/;
const INTEGER = /^\d+$/;
const DATE = /^\d{4}-\d{2}-\d{2}$/;

export type ProductField =
  | 'name'
  | 'sku'
  | 'categoryId'
  | 'price'
  | 'description'
  | 'imageUrl'
  | 'currentStock'
  | 'minStock'
  | 'expirationDate';

export type ProductFormResult<T> =
  | { ok: true; data: T }
  | { ok: false; fieldErrors: Partial<Record<ProductField, string>> };

function text(formData: FormData, name: string): string {
  const value = formData.get(name);
  return typeof value === 'string' ? value.trim() : '';
}

function isHttpUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' || url.protocol === 'http:';
  } catch {
    return false;
  }
}

/** Valores tal como los escribió el usuario, para volver a mostrarlos tras un error. */
export function productFormValues(formData: FormData): Record<string, string> {
  const values: Record<string, string> = {};
  for (const [key, value] of formData.entries()) {
    if (typeof value === 'string' && !key.startsWith('$')) values[key] = value;
  }
  return values;
}

function parseCommon(formData: FormData, fieldErrors: Partial<Record<ProductField, string>>) {
  const name = text(formData, 'name');
  const sku = text(formData, 'sku');
  const categoryId = text(formData, 'categoryId');
  const priceText = text(formData, 'price');
  const description = text(formData, 'description');
  const imageUrl = text(formData, 'imageUrl');
  const minStockText = text(formData, 'minStock');
  const expirationDate = text(formData, 'expirationDate');

  if (!name) fieldErrors.name = 'Ingresa el nombre.';
  else if (name.length > 150) fieldErrors.name = 'Máximo 150 caracteres.';

  if (!sku) fieldErrors.sku = 'Ingresa el código (SKU).';
  else if (sku.length > 50) fieldErrors.sku = 'Máximo 50 caracteres.';

  if (!isUuid(categoryId)) fieldErrors.categoryId = 'Elige una categoría.';

  const price = Number(priceText.replace(',', '.'));
  if (!PRICE.test(priceText)) fieldErrors.price = 'Ingresa un precio como 4.50 (máximo 2 decimales).';
  else if (price > MAX_PRICE) fieldErrors.price = 'El precio es demasiado alto.';

  if (description.length > 1000) fieldErrors.description = 'Máximo 1000 caracteres.';
  if (imageUrl && !isHttpUrl(imageUrl)) fieldErrors.imageUrl = 'Debe ser una URL que empiece con https://';

  if (minStockText && !INTEGER.test(minStockText)) {
    fieldErrors.minStock = 'Debe ser un número entero, 0 o más.';
  }
  if (expirationDate && !DATE.test(expirationDate)) {
    fieldErrors.expirationDate = 'Fecha inválida.';
  }

  return {
    name,
    sku,
    categoryId,
    price,
    // Vacío → null: así la edición puede borrar un campo opcional.
    description: description || null,
    imageUrl: imageUrl || null,
    minStock: minStockText ? Number(minStockText) : 0,
    expirationDate: expirationDate || null,
    active: formData.get('active') === 'on',
  };
}

export function parseCreateProductForm(formData: FormData): ProductFormResult<CreateProductRequest> {
  const fieldErrors: Partial<Record<ProductField, string>> = {};
  const common = parseCommon(formData, fieldErrors);

  const stockText = text(formData, 'currentStock');
  if (stockText && !INTEGER.test(stockText)) {
    fieldErrors.currentStock = 'Debe ser un número entero, 0 o más.';
  }

  if (Object.keys(fieldErrors).length > 0) return { ok: false, fieldErrors };
  return { ok: true, data: { ...common, currentStock: stockText ? Number(stockText) : 0 } };
}

/** En la edición no se envía `currentStock`: el stock se ajusta desde inventario. */
export function parseUpdateProductForm(formData: FormData): ProductFormResult<UpdateProductRequest> {
  const fieldErrors: Partial<Record<ProductField, string>> = {};
  const common = parseCommon(formData, fieldErrors);

  if (Object.keys(fieldErrors).length > 0) return { ok: false, fieldErrors };
  return { ok: true, data: common };
}
