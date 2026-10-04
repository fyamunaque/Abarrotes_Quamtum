/**
 * Tokens de inyección de los reportes. Las interfaces de TypeScript no existen en tiempo
 * de ejecución, así que Nest resuelve cada ReportProvider por su token.
 */
export const SALES_REPORT = Symbol('SALES_REPORT');
export const ORDER_STATUS_REPORT = Symbol('ORDER_STATUS_REPORT');
export const OVERVIEW_REPORT = Symbol('OVERVIEW_REPORT');
export const TOP_PRODUCTS_REPORT = Symbol('TOP_PRODUCTS_REPORT');
export const LOW_STOCK_REPORT = Symbol('LOW_STOCK_REPORT');
export const EXPIRING_PRODUCTS_REPORT = Symbol('EXPIRING_PRODUCTS_REPORT');
