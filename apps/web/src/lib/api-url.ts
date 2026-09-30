/** URL de la API. Solo la usa código de servidor (páginas, Server Actions y proxy.ts). */
export const API_URL = (process.env.API_URL ?? 'http://localhost:3001').replace(/\/+$/, '');
