import type { AuthResponse } from '@abarrotes/shared-types';
import { describe, expect, it } from 'vitest';
import { isOrderStatus, nextOrderStatuses, ORDER_STATUSES } from './orders';
import { parseCreateProductForm, parseUpdateProductForm, productFormValues } from './product-form';
import {
  decodeSessionUser,
  encodeSessionUser,
  isStaffRole,
  sessionCookies,
  USER_COOKIE,
} from './session-cookies';

const CATEGORY_ID = '3f1b6a8e-2c4d-4e5f-9a0b-1c2d3e4f5a6b';

function form(fields: Record<string, string>): FormData {
  const data = new FormData();
  for (const [key, value] of Object.entries(fields)) data.set(key, value);
  return data;
}

const validFields = {
  name: '  Arroz Costeño 1kg ',
  sku: 'ARZ-1KG',
  categoryId: CATEGORY_ID,
  price: '4,50',
  currentStock: '12',
  minStock: '3',
  description: '',
  imageUrl: '',
  expirationDate: '2026-12-31',
  active: 'on',
};

describe('formulario de producto', () => {
  it('convierte el formulario en el request de la API', () => {
    const result = parseCreateProductForm(form(validFields));

    expect(result).toEqual({
      ok: true,
      data: {
        name: 'Arroz Costeño 1kg',
        sku: 'ARZ-1KG',
        categoryId: CATEGORY_ID,
        price: 4.5,
        currentStock: 12,
        minStock: 3,
        description: null,
        imageUrl: null,
        expirationDate: '2026-12-31',
        active: true,
      },
    });
  });

  it('marca cada campo inválido', () => {
    const result = parseCreateProductForm(
      form({ ...validFields, name: '', price: '4.555', imageUrl: 'javascript:alert(1)', currentStock: '-1' }),
    );

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(Object.keys(result.fieldErrors).sort()).toEqual(['currentStock', 'imageUrl', 'name', 'price']);
    }
  });

  it('sin marcar "visible" el producto queda inactivo', () => {
    const { active, ...withoutActive } = validFields;
    const result = parseCreateProductForm(form(withoutActive));

    expect(active).toBe('on');
    expect(result.ok && result.data.active).toBe(false);
  });

  it('la edición no envía stock, aunque venga en el formulario', () => {
    const result = parseUpdateProductForm(form(validFields));

    expect(result.ok).toBe(true);
    expect(result.ok && 'currentStock' in result.data).toBe(false);
  });

  it('conserva lo escrito sin los campos internos de Next.js', () => {
    const data = form({ name: 'Arroz', $ACTION_ID_abc: 'x' });
    expect(productFormValues(data)).toEqual({ name: 'Arroz' });
  });
});

describe('estados de pedido', () => {
  it('sigue el flujo normal y permite cancelar hasta antes de entregar', () => {
    expect(nextOrderStatuses('PENDING_CONFIRMATION')).toEqual(['CONFIRMED', 'CANCELLED']);
    expect(nextOrderStatuses('CONFIRMED')).toEqual(['OUT_FOR_DELIVERY', 'CANCELLED']);
    expect(nextOrderStatuses('OUT_FOR_DELIVERY')).toEqual(['DELIVERED', 'CANCELLED']);
    expect(nextOrderStatuses('DELIVERED')).toEqual([]);
    expect(nextOrderStatuses('CANCELLED')).toEqual([]);
  });

  it('reconoce solo los estados del enum', () => {
    expect(ORDER_STATUSES).toHaveLength(5);
    expect(isOrderStatus('CONFIRMED')).toBe(true);
    expect(isOrderStatus('ENVIADO')).toBe(false);
    expect(isOrderStatus('toString')).toBe(false);
  });
});

describe('cookies de sesión', () => {
  const auth: AuthResponse = {
    accessToken: 'a.b.c',
    refreshToken: 'd.e.f',
    user: {
      id: 'u1',
      email: 'staff@example.com',
      name: 'José Núñez',
      phone: null,
      role: 'STAFF',
      address: 'Jr. Unión 123; Lima',
      createdAt: '2026-01-01T00:00:00.000Z',
    },
  };

  it('son httpOnly y guardan el rol para mostrar el menú de admin', () => {
    const cookies = sessionCookies(auth);

    expect(cookies.every((c) => c.options.httpOnly && c.options.sameSite === 'lax')).toBe(true);
    const user = decodeSessionUser(cookies.find((c) => c.name === USER_COOKIE)!.value);
    expect(user).toEqual({
      name: 'José Núñez',
      email: 'staff@example.com',
      address: 'Jr. Unión 123; Lima',
      role: 'STAFF',
    });
  });

  it('una cookie de usuario anterior, sin rol, cuenta como cliente', () => {
    const old = Buffer.from(JSON.stringify({ name: 'Ana', email: 'a@example.com', address: null })).toString(
      'base64url',
    );
    expect(decodeSessionUser(old)?.role).toBe('CUSTOMER');
    expect(decodeSessionUser('basura')).toBeNull();
  });

  it('solo ADMIN y STAFF son personal', () => {
    expect(isStaffRole('ADMIN')).toBe(true);
    expect(isStaffRole('STAFF')).toBe(true);
    expect(isStaffRole('CUSTOMER')).toBe(false);
    expect(decodeSessionUser(encodeSessionUser({ name: 'x', email: 'y', address: null, role: 'ADMIN' }))?.role).toBe(
      'ADMIN',
    );
  });
});
