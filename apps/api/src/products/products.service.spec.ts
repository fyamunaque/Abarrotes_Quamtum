import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { AuthUser } from '../auth/auth.types';
import { PrismaService } from '../prisma/prisma.service';
import { ListProductsQueryDto } from './dto/list-products-query.dto';
import { ProductsService } from './products.service';

const admin: AuthUser = {
  id: 'a',
  email: 'a@example.com',
  role: UserRole.ADMIN,
};
const staff: AuthUser = {
  id: 's',
  email: 's@example.com',
  role: UserRole.STAFF,
};
const customer: AuthUser = {
  id: 'c',
  email: 'c@example.com',
  role: UserRole.CUSTOMER,
};

function prismaError(code: string) {
  return new Prisma.PrismaClientKnownRequestError('error', {
    code,
    clientVersion: 'test',
  });
}

function query(overrides: Partial<ListProductsQueryDto> = {}) {
  return Object.assign(new ListProductsQueryDto(), overrides);
}

// 3 de octubre al mediodía en Lima.
const NOW = new Date('2026-10-03T17:00:00Z');

describe('ProductsService', () => {
  let service: ProductsService;
  let product: {
    findMany: jest.Mock;
    count: jest.Mock;
    findUnique: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };

  beforeEach(() => {
    product = {
      findMany: jest.fn().mockResolvedValue([]),
      count: jest.fn().mockResolvedValue(0),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    };
    service = new ProductsService({ product } as unknown as PrismaService, {
      now: () => NOW,
    });
  });

  describe('findAll', () => {
    it('para anónimos solo lista productos activos, paginados', async () => {
      product.count.mockResolvedValue(45);

      const result = await service.findAll(query({ page: 2, limit: 20 }));

      expect(product.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ active: true }),
          skip: 20,
          take: 20,
        }),
      );
      expect(result.meta).toEqual({
        total: 45,
        page: 2,
        limit: 20,
        totalPages: 3,
      });
    });

    it('ignora includeInactive si quien pide es CUSTOMER', async () => {
      await service.findAll(query({ includeInactive: true }), customer);

      expect(product.findMany.mock.calls[0][0].where.active).toBe(true);
    });

    it.each([admin, staff])(
      'con includeInactive, $role ve también los inactivos',
      async (user) => {
        await service.findAll(query({ includeInactive: true }), user);

        expect(product.findMany.mock.calls[0][0].where).not.toHaveProperty(
          'active',
        );
      },
    );

    it('filtra por categoría y busca por nombre o SKU', async () => {
      await service.findAll(query({ categoryId: 'cat-1', search: 'arroz' }));

      expect(product.findMany.mock.calls[0][0].where).toMatchObject({
        categoryId: 'cat-1',
        OR: [
          { name: { contains: 'arroz', mode: 'insensitive' } },
          { sku: { contains: 'arroz', mode: 'insensitive' } },
        ],
      });
    });
  });

  describe('findOne', () => {
    it('oculta un producto inactivo a los clientes', async () => {
      product.findUnique.mockResolvedValue({
        id: 'p1',
        active: false,
        promotions: [],
      });

      await expect(service.findOne('p1', customer)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('muestra un producto inactivo al staff', async () => {
      product.findUnique.mockResolvedValue({
        id: 'p1',
        active: false,
        promotions: [],
      });

      await expect(service.findOne('p1', staff)).resolves.toMatchObject({
        id: 'p1',
      });
    });

    it('responde 404 si no existe', async () => {
      product.findUnique.mockResolvedValue(null);

      await expect(service.findOne('p1', admin)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('create', () => {
    const dto = {
      name: 'Arroz 1kg',
      sku: 'ARZ-1KG',
      price: 4.5,
      categoryId: 'cat-1',
    };

    it('responde 409 si el SKU ya existe', async () => {
      product.create.mockRejectedValue(prismaError('P2002'));

      await expect(service.create(dto)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('responde 400 si la categoría no existe', async () => {
      product.create.mockRejectedValue(prismaError('P2003'));

      await expect(service.create(dto)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('deja pasar errores desconocidos', async () => {
      const unexpected = new Error('conexión caída');
      product.create.mockRejectedValue(unexpected);

      await expect(service.create(dto)).rejects.toBe(unexpected);
    });
  });

  describe('update / deactivate', () => {
    it('responde 404 al actualizar un producto inexistente', async () => {
      product.update.mockRejectedValue(prismaError('P2025'));

      await expect(
        service.update('p1', { name: 'Nuevo' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('desactivar hace baja lógica, no borrado', async () => {
      product.update.mockResolvedValue({
        id: 'p1',
        active: false,
        promotions: [],
      });

      await service.deactivate('p1');

      expect(product.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'p1' },
          data: { active: false },
        }),
      );
    });
  });

  describe('promoción vigente', () => {
    it('cada producto trae su promoción vigente (o null) en días de Lima', async () => {
      product.findMany.mockResolvedValue([
        {
          id: 'p1',
          name: 'Arroz',
          promotions: [
            {
              id: 'promo1',
              promoPrice: new Prisma.Decimal('3.90'),
              startDate: new Date('2026-10-01T05:00:00Z'),
              endDate: new Date('2026-10-08T05:00:00Z'),
            },
          ],
        },
        { id: 'p2', name: 'Leche', promotions: [] },
      ]);

      const { data } = await service.findAll(query());

      expect(data[0]).toEqual({
        id: 'p1',
        name: 'Arroz',
        promotion: {
          id: 'promo1',
          promoPrice: new Prisma.Decimal('3.90'),
          startDate: '2026-10-01',
          endDate: '2026-10-07',
        },
      });
      expect(data[1]).toEqual({ id: 'p2', name: 'Leche', promotion: null });
      // Solo la vigente a la hora actual.
      expect(product.findMany.mock.calls[0][0].include.promotions).toEqual(
        expect.objectContaining({
          where: {
            active: true,
            startDate: { lte: NOW },
            endDate: { gt: NOW },
          },
          take: 1,
        }),
      );
    });

    it('onSale deja solo los productos con una promoción vigente', async () => {
      await service.findAll(query({ onSale: true }));

      expect(product.findMany.mock.calls[0][0].where).toMatchObject({
        active: true,
        promotions: {
          some: { active: true, startDate: { lte: NOW }, endDate: { gt: NOW } },
        },
      });
    });
  });
});
