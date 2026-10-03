import type * as Shared from '@abarrotes/shared-types';
import { OrderStatus, UserRole } from '@prisma/client';
import { LoginDto } from './auth/dto/login.dto';
import { RefreshTokenDto } from './auth/dto/refresh-token.dto';
import { RegisterDto } from './auth/dto/register.dto';
import { CreateOrderDto } from './orders/dto/create-order.dto';
import { ListOrdersQueryDto } from './orders/dto/list-orders-query.dto';
import { UpdateOrderStatusDto } from './orders/dto/update-order-status.dto';
import { CreateProductDto } from './products/dto/create-product.dto';
import { ListProductsQueryDto } from './products/dto/list-products-query.dto';
import { UpdateProductDto } from './products/dto/update-product.dto';
import {
  DateRangeQueryDto,
  ExpiringQueryDto,
  TopProductsQueryDto,
} from './stats/dto/stats-query.dto';
import { CreateStaffUserDto } from './users/dto/create-staff-user.dto';

// Verificación en tiempo de compilación: si un DTO o un enum deja de coincidir con
// @abarrotes/shared-types, este archivo no compila y ts-jest hace fallar el test.
// Al tocar un DTO, actualiza también packages/shared-types.

/** true solo si A y B se asignan en ambos sentidos (mismos campos y opcionalidad). */
type SameShape<A, B> = [A] extends [B]
  ? [B] extends [A]
    ? true
    : false
  : false;
function expectTrue<T extends true>(): T | undefined {
  return undefined;
}

// Solo los campos de datos de la clase, sin métodos ni valores por defecto.
type Fields<T> = { [K in keyof T]: T[K] };

describe('Contrato con @abarrotes/shared-types', () => {
  it('los enums de Prisma coinciden con los tipos compartidos', () => {
    expectTrue<SameShape<OrderStatus, Shared.OrderStatus>>();
    expectTrue<SameShape<UserRole, Shared.UserRole>>();

    const statuses: Record<Shared.OrderStatus, true> = {
      PENDING_CONFIRMATION: true,
      CONFIRMED: true,
      OUT_FOR_DELIVERY: true,
      DELIVERED: true,
      CANCELLED: true,
    };
    expect(Object.keys(statuses).sort()).toEqual(
      Object.values(OrderStatus).sort(),
    );
  });

  it('los DTOs de entrada coinciden con los requests compartidos', () => {
    expectTrue<SameShape<Fields<LoginDto>, Shared.LoginRequest>>();
    expectTrue<
      SameShape<Fields<CreateStaffUserDto>, Shared.CreateStaffUserRequest>
    >();
    expectTrue<SameShape<Fields<RegisterDto>, Shared.RegisterRequest>>();
    expectTrue<
      SameShape<Fields<RefreshTokenDto>, Shared.RefreshTokenRequest>
    >();
    expectTrue<SameShape<Fields<CreateOrderDto>, Shared.CreateOrderRequest>>();
    expectTrue<
      SameShape<Partial<Fields<ListProductsQueryDto>>, Shared.ListProductsQuery>
    >();
    expectTrue<
      SameShape<Fields<UpdateOrderStatusDto>, Shared.UpdateOrderStatusRequest>
    >();
    expectTrue<
      SameShape<Partial<Fields<ListOrdersQueryDto>>, Shared.ListOrdersQuery>
    >();
  });

  it('los DTOs de productos coinciden (la fecha viaja como string ISO)', () => {
    // En el DTO, expirationDate ya es Date (lo convierte class-transformer).
    type WithoutDate<T> = Omit<T, 'expirationDate'>;
    expectTrue<
      SameShape<
        WithoutDate<Fields<CreateProductDto>>,
        WithoutDate<Shared.CreateProductRequest>
      >
    >();
    expectTrue<
      SameShape<
        WithoutDate<Fields<UpdateProductDto>>,
        WithoutDate<Shared.UpdateProductRequest>
      >
    >();
    expectTrue<
      SameShape<
        keyof CreateProductDto & 'expirationDate',
        keyof Shared.CreateProductRequest & 'expirationDate'
      >
    >();
  });

  it('los queries de estadísticas coinciden', () => {
    // Las respuestas de /stats ya usan los tipos compartidos directamente (providers).
    expectTrue<
      SameShape<Partial<Fields<DateRangeQueryDto>>, Shared.DateRangeQuery>
    >();
    expectTrue<
      SameShape<Partial<Fields<TopProductsQueryDto>>, Shared.TopProductsQuery>
    >();
    expectTrue<
      SameShape<Partial<Fields<ExpiringQueryDto>>, Shared.ExpiringProductsQuery>
    >();
  });
});
