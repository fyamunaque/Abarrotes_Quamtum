import { describe, expect, it } from 'vitest';
import { apiErrorMessage } from './api-errors';
import { secondsUntilExpiry } from './jwt';
import { orderStatusLabel, parseOrderRequest } from './orders';

const PRODUCT_ID = '3f1b6a8e-2c4d-4e5f-9a0b-1c2d3e4f5a6b';

describe('parseOrderRequest', () => {
  it('acepta un pedido válido y limpia la dirección', () => {
    expect(
      parseOrderRequest({
        deliveryAddress: '  Av. Siempre Viva 123 ',
        items: [{ productId: PRODUCT_ID, quantity: 2 }],
      }),
    ).toEqual({
      deliveryAddress: 'Av. Siempre Viva 123',
      items: [{ productId: PRODUCT_ID, quantity: 2 }],
    });
  });

  it.each([
    ['sin dirección', { deliveryAddress: '  ', items: [{ productId: PRODUCT_ID, quantity: 1 }] }],
    ['sin productos', { deliveryAddress: 'Calle 1', items: [] }],
    ['id inválido', { deliveryAddress: 'Calle 1', items: [{ productId: 'x', quantity: 1 }] }],
    ['cantidad decimal', { deliveryAddress: 'Calle 1', items: [{ productId: PRODUCT_ID, quantity: 1.5 }] }],
    ['cantidad excesiva', { deliveryAddress: 'Calle 1', items: [{ productId: PRODUCT_ID, quantity: 1000 }] }],
    ['no es un objeto', 'pedido'],
  ])('rechaza %s', (_case, input) => {
    expect(parseOrderRequest(input)).toBeNull();
  });

  it('descarta campos extra como precios enviados por el cliente', () => {
    const parsed = parseOrderRequest({
      deliveryAddress: 'Calle 1',
      total: '0.01',
      items: [{ productId: PRODUCT_ID, quantity: 1, unitPrice: '0.01' }],
    });

    expect(parsed).toEqual({
      deliveryAddress: 'Calle 1',
      items: [{ productId: PRODUCT_ID, quantity: 1 }],
    });
  });
});

describe('orderStatusLabel', () => {
  it('traduce los estados del enum', () => {
    expect(orderStatusLabel('PENDING_CONFIRMATION')).toBe('Pendiente de confirmación');
    expect(orderStatusLabel('DESCONOCIDO')).toBe('DESCONOCIDO');
  });
});

describe('apiErrorMessage', () => {
  it('toma el mensaje de NestJS, sea texto o lista', () => {
    expect(apiErrorMessage(409, { message: 'Stock insuficiente para "Arroz"' })).toBe(
      'Stock insuficiente para "Arroz"',
    );
    expect(apiErrorMessage(400, { message: ['email must be an email', 'otro'] })).toBe(
      'email must be an email\notro',
    );
  });

  it('usa un mensaje genérico si el cuerpo no sirve', () => {
    expect(apiErrorMessage(401, null)).toBe('Tu sesión expiró. Vuelve a ingresar.');
    expect(apiErrorMessage(502, '<html>')).toMatch(/No pudimos conectar/);
  });
});

describe('secondsUntilExpiry', () => {
  const token = (payload: object) =>
    `header.${Buffer.from(JSON.stringify(payload)).toString('base64url')}.firma`;

  it('calcula los segundos restantes según exp', () => {
    expect(secondsUntilExpiry(token({ exp: 1_000_900 }), 1_000_000)).toBe(900);
    expect(secondsUntilExpiry(token({ exp: 10 }), 1_000_000)).toBe(0);
  });

  it('devuelve null si el token no tiene exp legible', () => {
    expect(secondsUntilExpiry('no-es-un-jwt')).toBeNull();
    expect(secondsUntilExpiry(token({ sub: 'x' }))).toBeNull();
  });
});
