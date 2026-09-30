import { describe, expect, it } from 'vitest';
import { catalogHref, parsePage, safeRedirectPath } from './navigation';

describe('safeRedirectPath', () => {
  it('acepta rutas internas', () => {
    expect(safeRedirectPath('/checkout')).toBe('/checkout');
    expect(safeRedirectPath('/?categoria=abc')).toBe('/?categoria=abc');
  });

  it.each(['https://evil.com', '//evil.com', '/\\evil.com', 'checkout', '', null, undefined])(
    'descarta %s (evita redirigir fuera del sitio)',
    (value) => {
      expect(safeRedirectPath(value)).toBe('/');
    },
  );
});

describe('catalogHref', () => {
  it('arma la URL solo con los filtros presentes', () => {
    expect(catalogHref({})).toBe('/');
    expect(catalogHref({ search: 'arroz', page: 1 })).toBe('/?q=arroz');
    expect(catalogHref({ categoryId: 'c1', search: 'leche entera', page: 3 })).toBe(
      '/?categoria=c1&q=leche+entera&pagina=3',
    );
  });
});

describe('parsePage', () => {
  it('usa 1 para valores inválidos', () => {
    expect(parsePage(undefined)).toBe(1);
    expect(parsePage('abc')).toBe(1);
    expect(parsePage('-2')).toBe(1);
    expect(parsePage('2.5')).toBe(1);
    expect(parsePage('4')).toBe(4);
  });
});
