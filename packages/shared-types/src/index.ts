/**
 * Contrato JSON de /apps/api (la API lo verifica en
 * apps/api/src/shared-types.contract.spec.ts). Serverpod (/apps/server)
 * responde con la misma forma, y la app Flutter la lee.
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

/** Query de GET /orders (ADMIN/STAFF). */
export interface ListOrdersQuery extends PaginationQuery {
  status?: OrderStatus;
}

/** PATCH /orders/:id/status (ADMIN/STAFF). La API valida que el cambio esté permitido. */
export interface UpdateOrderStatusRequest {
  status: OrderStatus;
}

// ---------- Errores ----------

/** Error estándar de NestJS. `message` es una lista cuando falla la validación. */
export interface ApiError {
  statusCode: number;
  message: string | string[];
  error?: string;
}
