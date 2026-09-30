import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';

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
    },
    category: {
      findMany: jest.fn().mockResolvedValue([{ id: 'c1', name: 'Abarrotes' }]),
    },
    $transaction: jest.fn(),
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

  describe('/auth', () => {
    const registration = {
      email: '  Cliente@Example.com ',
      password: 'contrasena-segura',
      name: 'Cliente',
    };

    it('POST /register no deja elegir el rol', async () => {
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({ ...registration, role: UserRole.ADMIN })
        .expect(400);

      expect(prisma.user.create).not.toHaveBeenCalled();
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
});
