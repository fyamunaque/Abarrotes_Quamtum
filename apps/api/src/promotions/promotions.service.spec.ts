import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreatePromotionDto,
  ListPromotionsQueryDto,
} from './dto/promotion.dto';
import { PromotionsService } from './promotions.service';

const PRODUCT_ID = 'aaaaaaaa-0000-4000-8000-000000000001';
const PROMO_ID = 'bbbbbbbb-0000-4000-8000-000000000002';
const product = {
  id: PRODUCT_ID,
  name: 'Arroz extra 1 kg',
  sku: 'ARZ',
  price: new Prisma.Decimal('4.50'),
};

function storedPromotion(overrides: Record<string, unknown> = {}) {
  return {
    id: PROMO_ID,
    productId: PRODUCT_ID,
    product,
    promoPrice: new Prisma.Decimal('3.90'),
    startDate: new Date('2026-10-01T05:00:00Z'),
    endDate: new Date('2026-10-08T05:00:00Z'),
    active: true,
    ...overrides,
  };
}

describe('PromotionsService', () => {
  // 3 de octubre al mediodía en Lima.
  const now = new Date('2026-10-03T17:00:00Z');
  let prisma: {
    product: { findUnique: jest.Mock };
    promotion: {
      findMany: jest.Mock;
      count: jest.Mock;
      findUnique: jest.Mock;
      findFirst: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      delete: jest.Mock;
    };
  };
  let service: PromotionsService;

  const dto = (overrides: Partial<CreatePromotionDto> = {}) =>
    Object.assign(new CreatePromotionDto(), {
      productId: PRODUCT_ID,
      promoPrice: 3.9,
      startDate: '2026-10-01',
      endDate: '2026-10-07',
      ...overrides,
    });

  beforeEach(() => {
    prisma = {
      product: { findUnique: jest.fn().mockResolvedValue(product) },
      promotion: {
        findMany: jest.fn().mockResolvedValue([storedPromotion()]),
        count: jest.fn().mockResolvedValue(1),
        findUnique: jest.fn().mockResolvedValue(storedPromotion()),
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest
          .fn()
          .mockImplementation(({ data }) =>
            Promise.resolve(storedPromotion(data)),
          ),
        update: jest
          .fn()
          .mockImplementation(({ data }) =>
            Promise.resolve(storedPromotion(data)),
          ),
        delete: jest.fn(),
      },
    };
    service = new PromotionsService(prisma as unknown as PrismaService, {
      now: () => now,
    });
  });

  it('crea la promoción guardando los días de Lima y responde con su estado', async () => {
    const created = await service.create(dto());

    expect(prisma.promotion.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: {
          productId: PRODUCT_ID,
          promoPrice: 3.9,
          active: true,
          startDate: new Date('2026-10-01T05:00:00.000Z'),
          endDate: new Date('2026-10-08T05:00:00.000Z'),
        },
      }),
    );
    expect(created).toMatchObject({
      promoPrice: '3.9',
      startDate: '2026-10-01',
      endDate: '2026-10-07',
      status: 'ACTIVE',
      product: { name: 'Arroz extra 1 kg', price: '4.5' },
    });
  });

  it.each<[Partial<CreatePromotionDto>, string]>([
    [{ promoPrice: 4.5 }, 'igual al precio normal'],
    [{ promoPrice: 5 }, 'mayor al precio normal'],
    [{ startDate: '2026-10-07', endDate: '2026-10-01' }, 'fechas invertidas'],
  ])('rechaza con 400: %o (%s)', async (overrides) => {
    await expect(service.create(dto(overrides))).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(prisma.promotion.create).not.toHaveBeenCalled();
  });

  it('rechaza con 400 si el producto no existe', async () => {
    prisma.product.findUnique.mockResolvedValue(null);

    await expect(service.create(dto())).rejects.toThrow(
      new BadRequestException('El producto indicado no existe'),
    );
  });

  it('rechaza con 409 una promoción encendida que se cruza con otra del producto', async () => {
    prisma.promotion.findFirst.mockResolvedValue({
      startDate: new Date('2026-10-05T05:00:00Z'),
      endDate: new Date('2026-10-11T05:00:00Z'),
    });

    await expect(service.create(dto())).rejects.toThrow(
      new ConflictException(
        'Arroz extra 1 kg ya tiene una promoción del 2026-10-05 al 2026-10-10 que se cruza con esas fechas',
      ),
    );
    // Cruce: empieza antes de que termine la nueva y termina después de que empiece.
    expect(prisma.promotion.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          productId: PRODUCT_ID,
          active: true,
          startDate: { lt: new Date('2026-10-08T05:00:00.000Z') },
          endDate: { gt: new Date('2026-10-01T05:00:00.000Z') },
        },
      }),
    );
  });

  it('una promoción apagada no se compara con otras', async () => {
    await service.create(dto({ active: false }));

    expect(prisma.promotion.findFirst).not.toHaveBeenCalled();
    expect(prisma.promotion.create).toHaveBeenCalled();
  });

  it('al editar valida el resultado final y no choca consigo misma', async () => {
    await service.update(PROMO_ID, { endDate: '2026-10-10' });

    expect(prisma.promotion.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ id: { not: PROMO_ID } }),
      }),
    );
    expect(prisma.promotion.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: {
          promoPrice: 3.9,
          active: true,
          startDate: new Date('2026-10-01T05:00:00.000Z'),
          endDate: new Date('2026-10-11T05:00:00.000Z'),
        },
      }),
    );
  });

  it('al editar rechaza un precio que ya no es menor al normal', async () => {
    await expect(
      service.update(PROMO_ID, { promoPrice: 4.6 }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('lista filtrando por estado según la hora actual', async () => {
    await service.findAll(
      Object.assign(new ListPromotionsQueryDto(), {
        status: 'SCHEDULED' as const,
      }),
    );

    expect(prisma.promotion.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { productId: undefined, active: true, startDate: { gt: now } },
      }),
    );
  });

  it('responde 404 al buscar, editar o borrar una promoción que no existe', async () => {
    prisma.promotion.findUnique.mockResolvedValue(null);

    await expect(service.findOne(PROMO_ID)).rejects.toBeInstanceOf(
      NotFoundException,
    );
    await expect(service.update(PROMO_ID, {})).rejects.toBeInstanceOf(
      NotFoundException,
    );
    await expect(service.remove(PROMO_ID)).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(prisma.promotion.delete).not.toHaveBeenCalled();
  });
});
