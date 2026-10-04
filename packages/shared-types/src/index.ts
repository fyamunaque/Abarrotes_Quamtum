/**
 * Contrato JSON de /apps/api, compartido por /apps/web (y la API lo verifica en
 * apps/api/src/shared-types.contract.spec.ts).
 *
 * Solo tipos: importar siempre con `import type`.
 */

/** Monto `Decimal` serializado como string, sin ceros finales: `"4.5"`, `"12"`. */
export type Money = string;

/** Fecha ISO 8601: `"2026-09-29T18:00:00.000Z"`. */
export type ISODateString = string;

export type UserRole = 'CUSTOMER' | 'ADMIN' | 'STAFF';

/** Enum fijo (CLAUDE.md): no agregar estados sin actualizar los tres frontends. */
export type OrderStatus =
  | 'PENDING_CONFIRMATION'
  | 'CONFIRMED'
  | 'OUT_FOR_DELIVERY'
  | 'DELIVERED'
  | 'CANCELLED';

// ---------- Paginación ----------

export interface PageMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface Paginated<T> {
  data: T[];
  meta: PageMeta;
}

export interface PaginationQuery {
  page?: number;
  limit?: number;
}

// ---------- Catálogo ----------

export interface Category {
  id: string;
  name: string;
}

/**
 * POST /categories (ADMIN/STAFF). El nombre no puede repetirse, sin distinguir mayúsculas
 * (409). DELETE /categories/:id responde 204, o 409 si la categoría todavía tiene productos.
 */
export interface CreateCategoryRequest {
  name: string;
}

/** PATCH /categories/:id (ADMIN/STAFF). */
export type UpdateCategoryRequest = Partial<CreateCategoryRequest>;

export interface Product {
  id: string;
  name: string;
  description: string | null;
  sku: string;
  price: Money;
  imageUrl: string | null;
  active: boolean;
  currentStock: number;
  minStock: number;
  expirationDate: ISODateString | null;
  createdAt: ISODateString;
  categoryId: string;
  category: Category;
}

/** Query de GET /products. `includeInactive` solo tiene efecto para ADMIN/STAFF. */
export interface ListProductsQuery extends PaginationQuery {
  categoryId?: string;
  search?: string;
  includeInactive?: boolean;
}

/**
 * POST /products (ADMIN/STAFF). `null` en un campo opcional lo deja vacío.
 * `currentStock` es solo el stock inicial.
 */
export interface CreateProductRequest {
  name: string;
  description?: string | null;
  sku: string;
  price: number;
  imageUrl?: string | null;
  active?: boolean;
  currentStock?: number;
  minStock?: number;
  expirationDate?: ISODateString | null;
  categoryId: string;
}

/** PATCH /products/:id: campos parciales. El stock no se edita aquí (módulo inventory). */
export type UpdateProductRequest = Partial<Omit<CreateProductRequest, 'currentStock'>>;

// ---------- Auth ----------

export interface PublicUser {
  id: string;
  email: string;
  name: string;
  phone: string | null;
  role: UserRole;
  address: string | null;
  createdAt: ISODateString;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
  phone?: string;
  address?: string;
}

export interface RefreshTokenRequest {
  refreshToken: string;
}

/** Roles que solo un ADMIN puede asignar. */
export type StaffUserRole = Exclude<UserRole, 'CUSTOMER'>;

/** POST /users (solo ADMIN): única forma de crear cuentas ADMIN o STAFF. Responde un PublicUser. */
export interface CreateStaffUserRequest {
  email: string;
  password: string;
  name: string;
  phone?: string;
  role: StaffUserRole;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: PublicUser;
}

// ---------- Pedidos ----------

export interface CreateOrderItem {
  productId: string;
  quantity: number;
}

/** Sin precios: el servidor los toma de la base de datos. */
export interface CreateOrderRequest {
  deliveryAddress: string;
  items: CreateOrderItem[];
}

export interface OrderItem {
  id: string;
  quantity: number;
  unitPrice: Money;
  orderId: string;
  productId: string;
  product: Pick<Product, 'id' | 'name' | 'imageUrl'>;
}

export interface Order {
  id: string;
  status: OrderStatus;
  total: Money;
  deliveryAddress: string;
  createdAt: ISODateString;
  updatedAt: ISODateString;
  customerId: string;
  items: OrderItem[];
}

/** Pedido tal como lo ve el staff (GET /orders): incluye los datos del cliente. */
export interface AdminOrder extends Order {
  customer: Pick<PublicUser, 'id' | 'name' | 'email' | 'phone'>;
}

/**
 * Query de GET /orders (ADMIN/STAFF). `from` y `to` son días de la tienda (hora de Lima),
 * ambos incluidos; cualquiera puede faltar.
 */
export interface ListOrdersQuery extends PaginationQuery {
  status?: OrderStatus;
  from?: ISODay;
  to?: ISODay;
}

/** PATCH /orders/:id/status (ADMIN/STAFF). La API valida que el cambio esté permitido. */
export interface UpdateOrderStatusRequest {
  status: OrderStatus;
}

// ---------- Inventario (solo ADMIN/STAFF) ----------

/** IN: entra stock (p. ej. al cancelar un pedido). OUT: sale (al crear un pedido). */
export type MovementType = 'IN' | 'OUT' | 'ADJUSTMENT';

export interface InventoryMovement {
  id: string;
  type: MovementType;
  quantity: number;
  reason: string | null;
  createdAt: ISODateString;
  product: Pick<Product, 'id' | 'name' | 'sku'>;
  /** Quién lo originó: el cliente que hizo el pedido o el staff que lo canceló. */
  user: Pick<PublicUser, 'id' | 'name'>;
}

/** Query de GET /inventory/movements: del más reciente al más antiguo, paginado. */
export interface ListInventoryMovementsQuery extends PaginationQuery {
  productId?: string;
}

// ---------- Estadísticas (GET /stats/*, solo ADMIN/STAFF) ----------

/** Día de calendario en la hora de la tienda (America/Lima): `"2026-10-01"`. */
export type ISODay = string;

/**
 * Ventas de un periodo. Cuentan solo los pedidos que la tienda aceptó
 * (CONFIRMED, OUT_FOR_DELIVERY y DELIVERED): ni pendientes ni cancelados.
 */
export interface SalesSummary {
  from: ISODay;
  to: ISODay;
  total: Money;
  orders: number;
  /** total / orders, redondeado a céntimos; "0" si no hubo pedidos. */
  averageTicket: Money;
}

export interface SalesPoint {
  date: ISODay;
  total: Money;
  orders: number;
}

/** GET /stats/sales: el resumen del rango y un punto por día (los días sin ventas van en 0). */
export interface SalesReport extends SalesSummary {
  timeZone: string;
  daily: SalesPoint[];
}

/** Query de GET /stats/sales y GET /stats/top-products. Por defecto, los últimos 30 días. */
export interface DateRangeQuery {
  from?: ISODay;
  to?: ISODay;
}

/** GET /stats/overview. `ordersByStatus` cuenta todos los pedidos, de cualquier fecha. */
export interface StatsOverview {
  timeZone: string;
  generatedAt: ISODateString;
  today: SalesSummary;
  /** Semana de lunes a hoy. */
  week: SalesSummary;
  /** Mes calendario hasta hoy. */
  month: SalesSummary;
  ordersByStatus: Record<OrderStatus, number>;
}

export interface TopProductsQuery extends DateRangeQuery {
  /** 1 a 50; por defecto 5. */
  limit?: number;
}

export interface TopProduct {
  productId: string;
  name: string;
  sku: string;
  quantity: number;
  revenue: Money;
}

/** GET /stats/top-products: los más vendidos por unidades en el rango. */
export interface TopProductsReport {
  from: ISODay;
  to: ISODay;
  data: TopProduct[];
}

export interface LowStockProduct {
  id: string;
  name: string;
  sku: string;
  category: string;
  currentStock: number;
  minStock: number;
  /** Unidades que faltan para llegar al mínimo (0 si está justo en el mínimo). */
  shortage: number;
}

/** GET /stats/low-stock: productos activos con currentStock <= minStock, los más críticos primero. */
export interface LowStockReport {
  data: LowStockProduct[];
}

export interface ExpiringProductsQuery {
  /** 1 a 365; por defecto 7. */
  days?: number;
}

export interface ExpiringProduct {
  id: string;
  name: string;
  sku: string;
  currentStock: number;
  expirationDate: ISODay;
  /** Días hasta el vencimiento: 0 vence hoy, negativo ya venció. */
  daysLeft: number;
}

/**
 * GET /stats/expiring: productos activos con stock que vencen hasta `until`
 * (hoy + `days`), incluidos los ya vencidos, los más próximos primero.
 */
export interface ExpiringProductsReport {
  days: number;
  until: ISODay;
  data: ExpiringProduct[];
}

// ---------- Errores ----------

/** Error estándar de NestJS. `message` es una lista cuando falla la validación. */
export interface ApiError {
  statusCode: number;
  message: string | string[];
  error?: string;
}
