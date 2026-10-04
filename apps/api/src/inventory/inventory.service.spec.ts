import { NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ListMovementsQueryDto } from './dto/list-movements-query.dto';
import { InventoryService } from './inventory.service';

const PRODUCT_ID = 'aaaaaaaa-0000-4000-8000-000000000001';

function query(values: Partial<ListMovementsQueryDto>): ListMovementsQueryDto {
  return Object.assign(new ListMovementsQueryDto(), values);
}

describe('InventoryService', () => {
  let prisma: {
    product: { findUnique: jest.Mock };
    inventoryMovement: { findMany: jest.Mock; count: jest.Mock };
  };
  let service: InventoryService;

  beforeEach(() => {
    prisma = {
      product: { findUnique: jest.fn().mockResolvedValue({ id: PRODUCT_ID }) },
      inventoryMovement: {
        findMany: jest.fn().mockResolvedValue([{ id: 'm1' }]),
        count: jest.fn().mockResolvedValue(25),
      },
    };
    service = new InventoryService(prisma as unknown as PrismaService);
  });

  it('pagina el historial de un producto, del más reciente al más antiguo', async () => {
    const result = await service.findMovements(
      query({ productId: PRODUCT_ID, page: 2, limit: 10 }),
    );

    expect(prisma.inventoryMovement.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { productId: PRODUCT_ID },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: 10,
        take: 10,
      }),
    );
    expect(prisma.inventoryMovement.count).toHaveBeenCalledWith({
      where: { productId: PRODUCT_ID },
    });
    expect(result).toEqual({
      data: [{ id: 'm1' }],
      meta: { total: 25, page: 2, limit: 10, totalPages: 3 },
    });
  });

  it('muestra quién y qué producto, sin datos sensibles del usuario', async () => {
    await service.findMovements(query({}));

    const { select } = prisma.inventoryMovement.findMany.mock.calls[0][0];
    expect(select.user).toEqual({ select: { id: true, name: true } });
    expect(select.product).toEqual({
      select: { id: true, name: true, sku: true },
    });
  });

  it('sin productId trae el historial de todos los productos', async () => {
    await service.findMovements(query({}));

    expect(prisma.product.findUnique).not.toHaveBeenCalled();
    expect(prisma.inventoryMovement.findMany.mock.calls[0][0].where).toEqual({
      productId: undefined,
    });
  });

  it('responde 404 si el producto no existe', async () => {
    prisma.product.findUnique.mockResolvedValue(null);

    await expect(
      service.findMovements(query({ productId: PRODUCT_ID })),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.inventoryMovement.findMany).not.toHaveBeenCalled();
  });
});
