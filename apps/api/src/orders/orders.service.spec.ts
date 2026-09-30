import { BadRequestException, ConflictException } from '@nestjs/common';
import { MovementType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { OrdersService } from './orders.service';

const ARROZ = 'aaaaaaaa-0000-4000-8000-000000000001';
const ACEITE = 'bbbbbbbb-0000-4000-8000-000000000002';

function product(id: string, name: string, price: string, currentStock = 50) {
  return { id, name, price: new Prisma.Decimal(price), currentStock };
}

describe('OrdersService', () => {
  let service: OrdersService;
  let tx: {
    product: { findMany: jest.Mock; updateMany: jest.Mock };
    order: { create: jest.Mock };
    inventoryMovement: { createMany: jest.Mock };
  };

  beforeEach(() => {
    tx = {
      product: {
        findMany: jest
          .fn()
          .mockResolvedValue([
            product(ARROZ, 'Arroz 1kg', '4.50'),
            product(ACEITE, 'Aceite 1L', '9.90'),
          ]),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      order: {
        create: jest
          .fn()
          .mockImplementation(({ data }) =>
            Promise.resolve({ id: 'order-1', ...data }),
          ),
      },
      inventoryMovement: { createMany: jest.fn() },
    };
    const prisma = {
      $transaction: jest.fn((fn: (client: typeof tx) => unknown) => fn(tx)),
    };
    service = new OrdersService(prisma as unknown as PrismaService);
  });

  it('calcula precios y total en el servidor y suma productos repetidos', async () => {
    await service.create('cliente-1', {
      deliveryAddress: 'Av. Siempre Viva 123',
      items: [
        { productId: ARROZ, quantity: 2 },
        { productId: ACEITE, quantity: 1 },
        { productId: ARROZ, quantity: 1 },
      ],
    });

    const { data } = tx.order.create.mock.calls[0][0];
    expect(data.customerId).toBe('cliente-1');
    expect(data.total.toString()).toBe('23.4'); // 3 × 4.50 + 1 × 9.90
    expect(data.items.create).toEqual([
      { productId: ARROZ, quantity: 3, unitPrice: new Prisma.Decimal('4.50') },
      { productId: ACEITE, quantity: 1, unitPrice: new Prisma.Decimal('9.90') },
    ]);
  });

  it('descuenta stock solo si alcanza y registra la salida de inventario', async () => {
    await service.create('cliente-1', {
      deliveryAddress: 'Av. Siempre Viva 123',
      items: [{ productId: ARROZ, quantity: 2 }],
    });

    expect(tx.product.updateMany).toHaveBeenCalledWith({
      where: { id: ARROZ, currentStock: { gte: 2 } },
      data: { currentStock: { decrement: 2 } },
    });
    expect(tx.inventoryMovement.createMany).toHaveBeenCalledWith({
      data: [
        {
          productId: ARROZ,
          userId: 'cliente-1',
          type: MovementType.OUT,
          quantity: 2,
          reason: 'Pedido order-1',
        },
      ],
    });
  });

  it('rechaza productos inexistentes o inactivos sin crear el pedido', async () => {
    tx.product.findMany.mockResolvedValue([
      product(ARROZ, 'Arroz 1kg', '4.50'),
    ]);

    await expect(
      service.create('cliente-1', {
        deliveryAddress: 'Av. Siempre Viva 123',
        items: [
          { productId: ARROZ, quantity: 1 },
          { productId: ACEITE, quantity: 1 },
        ],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);

    expect(tx.product.updateMany).not.toHaveBeenCalled();
    expect(tx.order.create).not.toHaveBeenCalled();
  });

  it('rechaza el pedido si no hay stock suficiente', async () => {
    tx.product.updateMany.mockResolvedValue({ count: 0 });

    await expect(
      service.create('cliente-1', {
        deliveryAddress: 'Av. Siempre Viva 123',
        items: [{ productId: ARROZ, quantity: 999 }],
      }),
    ).rejects.toBeInstanceOf(ConflictException);

    expect(tx.order.create).not.toHaveBeenCalled();
  });
});
