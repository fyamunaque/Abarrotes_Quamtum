import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { MovementType, OrderStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { OrdersService } from './orders.service';

const ORDER_ID = 'cccccccc-0000-4000-8000-000000000003';

describe('OrdersService: cambios de estado', () => {
  let service: OrdersService;
  let prisma: {
    $transaction: jest.Mock;
    order: { findMany: jest.Mock; count: jest.Mock };
  };
  let tx: {
    order: {
      findUnique: jest.Mock;
      updateMany: jest.Mock;
      findUniqueOrThrow: jest.Mock;
    };
    product: { update: jest.Mock };
    inventoryMovement: { createMany: jest.Mock };
  };

  function existingOrder(status: OrderStatus) {
    tx.order.findUnique.mockResolvedValue({
      id: ORDER_ID,
      status,
      items: [
        { productId: 'arroz', quantity: 2 },
        { productId: 'aceite', quantity: 1 },
      ],
    });
  }

  beforeEach(() => {
    tx = {
      order: {
        findUnique: jest.fn(),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        findUniqueOrThrow: jest.fn().mockResolvedValue({ id: ORDER_ID }),
      },
      product: { update: jest.fn() },
      inventoryMovement: { createMany: jest.fn() },
    };
    prisma = {
      $transaction: jest.fn((fn: (client: typeof tx) => unknown) => fn(tx)),
      order: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
      },
    };
    service = new OrdersService(prisma as unknown as PrismaService);
  });

  it('avanza por el flujo normal y solo si el pedido sigue en el estado leído', async () => {
    existingOrder(OrderStatus.PENDING_CONFIRMATION);

    await service.updateStatus(ORDER_ID, OrderStatus.CONFIRMED, 'staff-1');

    expect(tx.order.updateMany).toHaveBeenCalledWith({
      where: { id: ORDER_ID, status: OrderStatus.PENDING_CONFIRMATION },
      data: { status: OrderStatus.CONFIRMED },
    });
    expect(tx.product.update).not.toHaveBeenCalled();
  });

  it.each([
    [
      OrderStatus.PENDING_CONFIRMATION,
      OrderStatus.DELIVERED,
      'Un pedido pendiente de confirmación no puede pasar a entregado: solo puede pasar a confirmado o cancelado',
    ],
    [
      OrderStatus.CONFIRMED,
      OrderStatus.PENDING_CONFIRMATION,
      'Un pedido confirmado no puede pasar a pendiente de confirmación: solo puede pasar a en camino o cancelado',
    ],
    [
      OrderStatus.DELIVERED,
      OrderStatus.CANCELLED,
      'Un pedido entregado ya no puede cambiar de estado',
    ],
    [
      OrderStatus.CANCELLED,
      OrderStatus.CONFIRMED,
      'Un pedido cancelado ya no puede cambiar de estado',
    ],
    [
      OrderStatus.CONFIRMED,
      OrderStatus.CONFIRMED,
      'El pedido ya está confirmado',
    ],
  ])(
    'rechaza pasar de %s a %s con 400 y el motivo',
    async (from, to, reason) => {
      existingOrder(from);

      const error = await service
        .updateStatus(ORDER_ID, to, 'staff-1')
        .catch((e: unknown) => e);

      expect(error).toBeInstanceOf(BadRequestException);
      expect((error as BadRequestException).message).toBe(reason);
      expect(tx.order.updateMany).not.toHaveBeenCalled();
    },
  );

  it('al cancelar devuelve el stock y registra la entrada en inventario', async () => {
    existingOrder(OrderStatus.CONFIRMED);

    await service.updateStatus(ORDER_ID, OrderStatus.CANCELLED, 'staff-1');

    expect(tx.product.update).toHaveBeenCalledWith({
      where: { id: 'arroz' },
      data: { currentStock: { increment: 2 } },
    });
    expect(tx.product.update).toHaveBeenCalledWith({
      where: { id: 'aceite' },
      data: { currentStock: { increment: 1 } },
    });
    expect(tx.inventoryMovement.createMany).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({
          productId: 'arroz',
          userId: 'staff-1',
          type: MovementType.IN,
          quantity: 2,
        }),
        expect.objectContaining({ productId: 'aceite', quantity: 1 }),
      ],
    });
  });

  it('responde 409 si otra persona cambió el pedido al mismo tiempo', async () => {
    existingOrder(OrderStatus.CONFIRMED);
    tx.order.updateMany.mockResolvedValue({ count: 0 });

    await expect(
      service.updateStatus(ORDER_ID, OrderStatus.CANCELLED, 'staff-1'),
    ).rejects.toBeInstanceOf(ConflictException);
    // Si no se actualizó el pedido, tampoco se devuelve stock.
    expect(tx.product.update).not.toHaveBeenCalled();
  });

  it('responde 404 si el pedido no existe', async () => {
    tx.order.findUnique.mockResolvedValue(null);

    await expect(
      service.updateStatus(ORDER_ID, OrderStatus.CONFIRMED, 'staff-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('lista todos los pedidos filtrando por estado', async () => {
    await service.findAll(
      Object.assign(new (class {})(), {
        status: OrderStatus.OUT_FOR_DELIVERY,
        page: 1,
        limit: 20,
      }),
    );

    expect(prisma.order.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { status: OrderStatus.OUT_FOR_DELIVERY },
        orderBy: { createdAt: 'desc' },
      }),
    );
  });
});
