import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vitest/config';

// Tests de la lógica pura (src/lib). Los componentes y Server Actions se validan con
// `next build` y la prueba manual contra la API.
export default defineConfig({
  resolve: {
    alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
  },
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts'],
  },
});
