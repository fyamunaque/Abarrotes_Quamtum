import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { ProductStockRepository } from '../src/inventory/product-stock.repository';
import { PrismaService } from '../src/prisma/prisma.service';
import {
  EXPIRING_PRODUCTS_REPORT,
  LOW_STOCK_REPORT,
} from '../src/stats/stats.tokens';

// Sin base de datos: estos tests cubren HTTP, validación, autenticación y roles.
function createPrismaMock() {
  return {
    user: { findUnique: jest.fn(), create: jest.fn() },
    product: {
      findMany: jest.fn().mockResolvedValue([]),
      count: jest.fn().mockResolvedValue(0),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      fields: { minStock: { name: 'minStock' } },
    },
    category: {
      findMany: jest.fn().mockResolvedValue([{ id: 'c1', name: 'Abarrotes' }]),
    },
    order: {
      findMany: jest.fn().mockResolvedValue([]),
      count: jest.fn().mockResolvedValue(0),
      groupBy: jest.fn().mockResolvedValue([]),
    },
    inventoryMovement: {
      findMany: jest.fn().mockResolvedValue([]),
      count: jest.fn().mockResolvedValue(0),
    },
    $transaction: jest.fn(),
    $queryRaw: jest.fn().mockResolvedValue([]),
  };
}

describe('API (e2e)', () => {
  let app: INestApplication;
  let prisma: ReturnType<typeof createPrismaMock>;
  const jwtService = new JwtService({});

  const bearer = async (role: UserRole) => {
    const token = await jwtService.signAsync(
      { sub: randomUUID(), email: 'usuario@example.com', role },
      { secret: process.env.JWT_ACCESS_SECRET },
    );
    return `Bearer ${token}`;
  };

  const validProduct = {
    name: 'Arroz Costeño 1kg',
    sku: 'ARZ-1KG',
    price: 4.5,
    categoryId: randomUUID(),
  };

  beforeEach(async () => {
    prisma = createPrismaMock();
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PrismaService)
      .useValue(prisma)
      .compile();

    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('GET /health es público', () => {
    return request(app.getHttpServer())
      .get('/health')
      .expect(200, { status: 'ok' });
  });

  describe('/products', () => {
    it('GET es público', async () => {
      const res = await request(app.getHttpServer())
        .get('/products')
        .expect(200);

      expect(res.body).toEqual({
        data: [],
        meta: { total: 0, page: 1, limit: 20, totalPages: 0 },
      });
    });

    it('GET ignora un token inválido en vez de responder 401', () => {
      return request(app.getHttpServer())
        .get('/products')
        .set('Authorization', 'Bearer no-es-un-jwt')
        .expect(200);
    });

    it('GET /:id valida que el id sea un UUID', () => {
      return request(app.getHttpServer()).get('/products/123').expect(400);
    });

    it('POST sin token responde 401', () => {
      return request(app.getHttpServer())
        .post('/products')
        .send(validProduct)
        .expect(401);
    });

    it('POST como CUSTOMER responde 403', async () => {
      await request(app.getHttpServer())
        .post('/products')
        .set('Authorization', await bearer(UserRole.CUSTOMER))
        .send(validProduct)
        .expect(403);

      expect(prisma.product.create).not.toHaveBeenCalled();
    });

    it.each([UserRole.ADMIN, UserRole.STAFF])(
      'POST como %s crea el producto',
      async (role) => {
        prisma.product.create.mockImplementation(({ data }) =>
          Promise.resolve({ id: randomUUID(), ...data }),
        );

        await request(app.getHttpServer())
          .post('/products')
          .set('Authorization', await bearer(role))
          .send(validProduct)
          .expect(201);

        expect(prisma.product.create).toHaveBeenCalledWith(
          expect.objectContaining({
            data: expect.objectContaining(validProduct),
          }),
        );
      },
    );

    it('POST con datos inválidos responde 400', async () => {
      await request(app.getHttpServer())
        .post('/products')
        .set('Authorization', await bearer(UserRole.ADMIN))
        .send({ ...validProduct, price: -1, categoryId: 'no-uuid' })
        .expect(400);

      expect(prisma.product.create).not.toHaveBeenCalled();
    });

    it('PATCH rechaza null en un campo obligatorio', async () => {
      await request(app.getHttpServer())
        .patch(`/products/${randomUUID()}`)
        .set('Authorization', await bearer(UserRole.ADMIN))
        .send({ name: null })
        .expect(400);
    });

    it('PATCH acepta null para borrar un campo opcional', async () => {
      prisma.product.update.mockResolvedValue({ id: 'p1' });

      await request(app.getHttpServer())
        .patch(`/products/${randomUUID()}`)
        .set('Authorization', await bearer(UserRole.STAFF))
        .send({ description: null })
        .expect(200);

      expect(prisma.product.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ description: null }),
        }),
      );
    });

    it('PATCH no permite tocar el stock', async () => {
      await request(app.getHttpServer())
        .patch(`/products/${randomUUID()}`)
        .set('Authorization', await bearer(UserRole.ADMIN))
        .send({ currentStock: 100 })
        .expect(400);
    });

    it('DELETE como CUSTOMER responde 403', async () => {
      await request(app.getHttpServer())
        .delete(`/products/${randomUUID()}`)
        .set('Authorization', await bearer(UserRole.CUSTOMER))
        .expect(403);
    });
  });

  it('GET /categories es público', () => {
    return request(app.getHttpServer())
      .get('/categories')
      .expect(200, [{ id: 'c1', name: 'Abarrotes' }]);
  });

  describe('/orders', () => {
    const validOrder = {
      deliveryAddress: 'Av. Siempre Viva 123',
      items: [{ productId: randomUUID(), quantity: 2 }],
    };

    it('POST sin token responde 401', () => {
      return request(app.getHttpServer())
        .post('/orders')
        .send(validOrder)
        .expect(401);
    });

    it('POST no acepta precios enviados por el cliente', async () => {
      await request(app.getHttpServer())
        .post('/orders')
        .set('Authorization', await bearer(UserRole.CUSTOMER))
        .send({
          ...validOrder,
          items: [{ ...validOrder.items[0], unitPrice: 0.01 }],
        })
        .expect(400);

      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('POST rechaza un pedido vacío', async () => {
      await request(app.getHttpServer())
        .post('/orders')
        .set('Authorization', await bearer(UserRole.CUSTOMER))
        .send({ ...validOrder, items: [] })
        .expect(400);
    });

    it('POST con token y datos válidos responde 201', async () => {
      prisma.$transaction.mockResolvedValue({ id: 'order-1' });

      await request(app.getHttpServer())
        .post('/orders')
        .set('Authorization', await bearer(UserRole.CUSTOMER))
        .send(validOrder)
        .expect(201, { id: 'order-1' });
    });
  });

  describe('/orders (staff)', () => {
    it('GET como CUSTOMER responde 403', async () => {
      await request(app.getHttpServer())
        .get('/orders')
        .set('Authorization', await bearer(UserRole.CUSTOMER))
        .expect(403);
    });

    it('GET como STAFF filtra por estado', async () => {
      await request(app.getHttpServer())
        .get('/orders?status=CONFIRMED')
        .set('Authorization', await bearer(UserRole.STAFF))
        .expect(200);

      expect(prisma.order.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { status: 'CONFIRMED' } }),
      );
    });

    it('GET con un estado inexistente responde 400', async () => {
      await request(app.getHttpServer())
        .get('/orders?status=ENVIADO')
        .set('Authorization', await bearer(UserRole.ADMIN))
        .expect(400);
    });

    it('PATCH status como CUSTOMER responde 403', async () => {
      await request(app.getHttpServer())
        .patch(`/orders/${randomUUID()}/status`)
        .set('Authorization', await bearer(UserRole.CUSTOMER))
        .send({ status: 'CANCELLED' })
        .expect(403);

      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('PATCH status valida el estado', async () => {
      await request(app.getHttpServer())
        .patch(`/orders/${randomUUID()}/status`)
        .set('Authorization', await bearer(UserRole.ADMIN))
        .send({ status: 'ENVIADO' })
        .expect(400);
    });

    it('PATCH status como ADMIN responde 200', async () => {
      prisma.$transaction.mockResolvedValue({ id: 'o1', status: 'CONFIRMED' });

      await request(app.getHttpServer())
        .patch(`/orders/${randomUUID()}/status`)
        .set('Authorization', await bearer(UserRole.ADMIN))
        .send({ status: 'CONFIRMED' })
        .expect(200, { id: 'o1', status: 'CONFIRMED' });
    });

    it('PATCH status rechaza una transición inválida con 400 y el motivo, sin guardar', async () => {
      const updateMany = jest.fn();
      const tx = {
        order: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ id: 'o1', status: 'DELIVERED', items: [] }),
          updateMany,
        },
      };
      prisma.$transaction.mockImplementation(
        (fn: (client: typeof tx) => unknown) => fn(tx),
      );

      const res = await request(app.getHttpServer())
        .patch(`/orders/${randomUUID()}/status`)
        .set('Authorization', await bearer(UserRole.STAFF))
        .send({ status: 'CANCELLED' })
        .expect(400);

      expect(res.body.message).toBe(
        'Un pedido entregado ya no puede cambiar de estado',
      );
      expect(updateMany).not.toHaveBeenCalled();
    });

    it('GET filtra por estado y por rango de fechas (días de Lima), paginado', async () => {
      const res = await request(app.getHttpServer())
        .get(
          '/orders?status=DELIVERED&from=2026-10-01&to=2026-10-31&page=2&limit=10',
        )
        .set('Authorization', await bearer(UserRole.STAFF))
        .expect(200);

      expect(prisma.order.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            status: 'DELIVERED',
            createdAt: {
              gte: new Date('2026-10-01T05:00:00.000Z'),
              lt: new Date('2026-11-01T05:00:00.000Z'),
            },
          },
          skip: 10,
          take: 10,
        }),
      );
      expect(res.body.meta).toEqual({
        total: 0,
        page: 2,
        limit: 10,
        totalPages: 0,
      });
    });

    it.each([
      ['/orders?from=2026-10-07&to=2026-10-01', 'rango invertido'],
      ['/orders?from=2026-02-30', 'fecha imposible'],
      ['/orders?to=31-10-2026', 'formato distinto de AAAA-MM-DD'],
    ])('GET %s responde 400 (%s)', async (path) => {
      await request(app.getHttpServer())
        .get(path)
        .set('Authorization', await bearer(UserRole.ADMIN))
        .expect(400);
      expect(prisma.order.findMany).not.toHaveBeenCalled();
    });
  });

  describe('tokens (Passport-JWT)', () => {
    const payload = {
      sub: randomUUID(),
      email: 'u@example.com',
      role: UserRole.ADMIN,
    };

    it('sin token responde 401 indicando que falta', async () => {
      const res = await request(app.getHttpServer())
        .get('/auth/me')
        .expect(401);
      expect(res.body.message).toBe('Falta el token de acceso');
    });

    it('rechaza un refresh token usado como access token', async () => {
      const refresh = await jwtService.signAsync(payload, {
        secret: process.env.JWT_REFRESH_SECRET,
      });
      await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', `Bearer ${refresh}`)
        .expect(401);
    });

    it('rechaza un token vencido', async () => {
      const expired = await jwtService.signAsync(
        { ...payload, exp: Math.floor(Date.now() / 1000) - 60 },
        { secret: process.env.JWT_ACCESS_SECRET },
      );
      const res = await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', `Bearer ${expired}`)
        .expect(401);
      expect(res.body.message).toBe('Token de acceso inválido o expirado');
    });

    it('rechaza un token sin firma (alg: none)', async () => {
      const b64 = (o: object) =>
        Buffer.from(JSON.stringify(o)).toString('base64url');
      const unsigned = `${b64({ alg: 'none', typ: 'JWT' })}.${b64(payload)}.`;
      await request(app.getHttpServer())
        .post('/users')
        .set('Authorization', `Bearer ${unsigned}`)
        .send({})
        .expect(401);
    });
  });

  describe('/users', () => {
    const staffUser = {
      email: 'Cajera@Example.com',
      password: 'clave-segura-123',
      name: 'Cajera',
      role: UserRole.STAFF,
    };

    it('POST sin token responde 401', () => {
      return request(app.getHttpServer())
        .post('/users')
        .send(staffUser)
        .expect(401);
    });

    it.each([UserRole.CUSTOMER, UserRole.STAFF])(
      'POST como %s responde 403',
      async (role) => {
        await request(app.getHttpServer())
          .post('/users')
          .set('Authorization', await bearer(role))
          .send(staffUser)
          .expect(403);
        expect(prisma.user.create).not.toHaveBeenCalled();
      },
    );

    it('POST como ADMIN no permite crear CUSTOMER', async () => {
      const res = await request(app.getHttpServer())
        .post('/users')
        .set('Authorization', await bearer(UserRole.ADMIN))
        .send({ ...staffUser, role: UserRole.CUSTOMER })
        .expect(400);
      expect(res.body.message).toContain('role debe ser ADMIN o STAFF');
    });

    it('POST como ADMIN crea un STAFF sin exponer el hash', async () => {
      prisma.user.create.mockImplementation(({ data }) =>
        Promise.resolve({
          id: randomUUID(),
          phone: null,
          address: null,
          createdAt: new Date(),
          ...data,
        }),
      );

      const res = await request(app.getHttpServer())
        .post('/users')
        .set('Authorization', await bearer(UserRole.ADMIN))
        .send(staffUser)
        .expect(201);

      const { data } = prisma.user.create.mock.calls[0][0];
      expect(data).toMatchObject({
        email: 'cajera@example.com',
        role: UserRole.STAFF,
      });
      expect(res.body.role).toBe(UserRole.STAFF);
      expect(res.body).not.toHaveProperty('passwordHash');
    });
  });

  describe('/auth', () => {
    const registration = {
      email: '  Cliente@Example.com ',
      password: 'contrasena-segura',
      name: 'Cliente',
    };

    it('POST /register ignora el rol enviado y crea un CUSTOMER', async () => {
      prisma.user.create.mockImplementation(({ data }) =>
        Promise.resolve({
          id: randomUUID(),
          phone: null,
          address: null,
          createdAt: new Date(),
          ...data,
        }),
      );

      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send({ ...registration, role: UserRole.ADMIN })
        .expect(201);

      expect(prisma.user.create.mock.calls[0][0].data.role).toBe(
        UserRole.CUSTOMER,
      );
      expect(res.body.user.role).toBe(UserRole.CUSTOMER);
    });

    it('POST /register sigue rechazando otros campos desconocidos', async () => {
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({ ...registration, isAdmin: true })
        .expect(400);
    });

    it('POST /register crea un CUSTOMER y devuelve tokens sin el hash', async () => {
      prisma.user.create.mockImplementation(({ data }) =>
        Promise.resolve({
          id: randomUUID(),
          role: UserRole.CUSTOMER,
          phone: null,
          address: null,
          createdAt: new Date(),
          ...data,
        }),
      );

      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send(registration)
        .expect(201);

      expect(prisma.user.create.mock.calls[0][0].data.email).toBe(
        'cliente@example.com',
      );
      expect(res.body.user.role).toBe(UserRole.CUSTOMER);
      expect(res.body.user).not.toHaveProperty('passwordHash');
      expect(res.body.accessToken).toEqual(expect.any(String));
      expect(res.body.refreshToken).toEqual(expect.any(String));
    });

    it('GET /me sin token responde 401', () => {
      return request(app.getHttpServer()).get('/auth/me').expect(401);
    });

    it('GET /me con token devuelve el perfil', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'u1',
        email: 'usuario@example.com',
        passwordHash: 'hash',
        name: 'Usuario',
        phone: null,
        role: UserRole.CUSTOMER,
        address: null,
        createdAt: new Date(),
      });

      const res = await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', await bearer(UserRole.CUSTOMER))
        .expect(200);

      expect(res.body.email).toBe('usuario@example.com');
      expect(res.body).not.toHaveProperty('passwordHash');
    });
  });

  describe('/inventory/movements', () => {
    const productId = randomUUID();

    it('pide token y rechaza a un CUSTOMER', async () => {
      await request(app.getHttpServer())
        .get('/inventory/movements')
        .expect(401);
      await request(app.getHttpServer())
        .get('/inventory/movements')
        .set('Authorization', await bearer(UserRole.CUSTOMER))
        .expect(403);
    });

    it('GET como STAFF pagina el historial de un producto', async () => {
      prisma.product.findUnique.mockResolvedValue({ id: productId });
      prisma.inventoryMovement.findMany.mockResolvedValue([
        {
          id: 'm1',
          type: 'OUT',
          quantity: 2,
          reason: 'Pedido o1',
          createdAt: new Date('2026-10-02T00:08:09Z'),
          product: { id: productId, name: 'Arroz extra 1 kg', sku: 'ARZ' },
          user: { id: 'u1', name: 'Cliente' },
        },
      ]);
      prisma.inventoryMovement.count.mockResolvedValue(1);

      const res = await request(app.getHttpServer())
        .get(`/inventory/movements?productId=${productId}&page=1&limit=5`)
        .set('Authorization', await bearer(UserRole.STAFF))
        .expect(200);

      expect(res.body.meta).toEqual({
        total: 1,
        page: 1,
        limit: 5,
        totalPages: 1,
      });
      expect(res.body.data[0]).toMatchObject({ type: 'OUT', quantity: 2 });
      expect(prisma.inventoryMovement.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { productId }, take: 5 }),
      );
    });

    it('responde 400 si productId no es un UUID y 404 si el producto no existe', async () => {
      const auth = await bearer(UserRole.ADMIN);
      await request(app.getHttpServer())
        .get('/inventory/movements?productId=arroz')
        .set('Authorization', auth)
        .expect(400);

      prisma.product.findUnique.mockResolvedValue(null);
      await request(app.getHttpServer())
        .get(`/inventory/movements?productId=${productId}`)
        .set('Authorization', auth)
        .expect(404);
    });

    it('stats usa la misma instancia de ProductStockRepository que inventory', () => {
      const repository = app.get(ProductStockRepository, { strict: false });
      const lowStock = app.get<{ stock: unknown }>(LOW_STOCK_REPORT, {
        strict: false,
      });
      const expiring = app.get<{ stock: unknown }>(EXPIRING_PRODUCTS_REPORT, {
        strict: false,
      });

      expect(lowStock.stock).toBe(repository);
      expect(expiring.stock).toBe(repository);
    });
  });

  describe('/stats', () => {
    const paths = [
      '/stats/overview',
      '/stats/sales',
      '/stats/top-products',
      '/stats/low-stock',
      '/stats/expiring',
    ];

    it('todas las rutas piden token', async () => {
      for (const path of paths) {
        await request(app.getHttpServer()).get(path).expect(401);
      }
    });

    it('un CUSTOMER recibe 403 en todas las rutas', async () => {
      const auth = await bearer(UserRole.CUSTOMER);
      for (const path of paths) {
        await request(app.getHttpServer())
          .get(path)
          .set('Authorization', auth)
          .expect(403);
      }
    });

    it('GET /overview como STAFF devuelve ventas por periodo y pedidos por estado', async () => {
      prisma.$queryRaw.mockResolvedValue([
        { day: '2026-10-01', orders: 2, total: '25.00' },
      ]);
      prisma.order.groupBy.mockResolvedValue([
        { status: 'CONFIRMED', _count: { _all: 2 } },
      ]);

      const res = await request(app.getHttpServer())
        .get('/stats/overview')
        .set('Authorization', await bearer(UserRole.STAFF))
        .expect(200);

      expect(res.body.timeZone).toBe('America/Lima');
      expect(Object.keys(res.body)).toEqual(
        expect.arrayContaining(['today', 'week', 'month', 'ordersByStatus']),
      );
      expect(res.body.ordersByStatus).toEqual({
        PENDING_CONFIRMATION: 0,
        CONFIRMED: 2,
        OUT_FOR_DELIVERY: 0,
        DELIVERED: 0,
        CANCELLED: 0,
      });
    });

    it('GET /sales como ADMIN devuelve la serie diaria del rango', async () => {
      prisma.$queryRaw.mockResolvedValue([
        { day: '2026-10-02', orders: 1, total: '13.20' },
      ]);

      const res = await request(app.getHttpServer())
        .get('/stats/sales?from=2026-10-01&to=2026-10-03')
        .set('Authorization', await bearer(UserRole.ADMIN))
        .expect(200);

      expect(res.body).toMatchObject({
        from: '2026-10-01',
        to: '2026-10-03',
        total: '13.2',
        orders: 1,
      });
      expect(res.body.daily).toHaveLength(3);
    });

    it.each([
      ['/stats/sales?from=2026-10-05&to=2026-10-01', 'rango invertido'],
      ['/stats/sales?from=2026-02-30', 'fecha imposible'],
      ['/stats/sales?from=01-10-2026', 'formato distinto de AAAA-MM-DD'],
      ['/stats/sales?from=2025-01-01&to=2026-10-01', 'más de 366 días'],
      ['/stats/top-products?limit=0', 'limit menor que 1'],
      ['/stats/top-products?limit=51', 'limit mayor que 50'],
      ['/stats/expiring?days=abc', 'days no numérico'],
      ['/stats/expiring?days=400', 'days mayor que 365'],
    ])('GET %s responde 400 (%s)', async (path) => {
      await request(app.getHttpServer())
        .get(path)
        .set('Authorization', await bearer(UserRole.ADMIN))
        .expect(400);
    });

    it('GET /low-stock y /expiring como ADMIN responden 200', async () => {
      const auth = await bearer(UserRole.ADMIN);
      const lowStock = await request(app.getHttpServer())
        .get('/stats/low-stock')
        .set('Authorization', auth)
        .expect(200);
      const expiring = await request(app.getHttpServer())
        .get('/stats/expiring?days=30')
        .set('Authorization', auth)
        .expect(200);

      expect(lowStock.body).toEqual({ data: [] });
      expect(expiring.body).toMatchObject({ days: 30, data: [] });
    });
  });
});
