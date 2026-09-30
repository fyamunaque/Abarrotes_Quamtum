import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { MovementType, Prisma } from '@prisma/client';
import { paginate, PaginationQueryDto, toSkipTake } from '../common/pagination';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto, OrderItemDto } from './dto/create-order.dto';

const orderInclude = {
  items: {
    include: {
      product: { select: { id: true, name: true, imageUrl: true } },
    },
  },
} satisfies Prisma.OrderInclude;

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Crea el pedido en PENDING_CONFIRMATION y descuenta el stock en la misma
   * transacción: si algún producto no alcanza, no se guarda nada.
   */
  create(customerId: string, dto: CreateOrderDto) {
    const quantities = mergeQuantities(dto.items);

    return this.prisma.$transaction(async (tx) => {
      const products = await tx.product.findMany({
        where: { id: { in: [...quantities.keys()] }, active: true },
      });
      const productsById = new Map(products.map((p) => [p.id, p]));

      const unavailable = [...quantities.keys()].filter(
        (id) => !productsById.has(id),
      );
      if (unavailable.length > 0) {
        throw new BadRequestException(
          `Productos no disponibles: ${unavailable.join(', ')}`,
        );
      }

      // Orden fijo por id: dos pedidos simultáneos bloquean las filas en el mismo
      // orden y no se interbloquean.
      const lines = [...quantities]
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([productId, quantity]) => ({
          product: productsById.get(productId)!,
          quantity,
        }));

      let total = new Prisma.Decimal(0);
      for (const { product, quantity } of lines) {
        // Descuento condicional: si otro pedido se llevó el stock entre la lectura
        // y esta escritura, no se actualiza ninguna fila.
        const { count } = await tx.product.updateMany({
          where: { id: product.id, currentStock: { gte: quantity } },
          data: { currentStock: { decrement: quantity } },
        });
        if (count === 0) {
          throw new ConflictException(
            `Stock insuficiente para "${product.name}"`,
          );
        }
        total = total.add(product.price.mul(quantity));
      }

      const order = await tx.order.create({
        data: {
          customerId,
          deliveryAddress: dto.deliveryAddress,
          total,
          items: {
            create: lines.map(({ product, quantity }) => ({
              productId: product.id,
              quantity,
              unitPrice: product.price,
            })),
          },
        },
        include: orderInclude,
      });

      // Registra la salida para el historial de inventario. Cuando exista el módulo
      // `inventory` (Fase 4), esto debería pasar por su servicio.
      await tx.inventoryMovement.createMany({
        data: lines.map(({ product, quantity }) => ({
          productId: product.id,
          userId: customerId,
          type: MovementType.OUT,
          quantity,
          reason: `Pedido ${order.id}`,
        })),
      });

      return order;
    });
  }

  async findMine(customerId: string, query: PaginationQueryDto) {
    const where = { customerId };
    const [data, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        include: orderInclude,
        orderBy: { createdAt: 'desc' },
        ...toSkipTake(query),
      }),
      this.prisma.order.count({ where }),
    ]);
    return paginate(data, total, query);
  }
}

/** Un mismo producto repetido en el carrito se suma en una sola línea. */
function mergeQuantities(items: OrderItemDto[]): Map<string, number> {
  const quantities = new Map<string, number>();
  for (const { productId, quantity } of items) {
    quantities.set(productId, (quantities.get(productId) ?? 0) + quantity);
  }
  return quantities;
}
