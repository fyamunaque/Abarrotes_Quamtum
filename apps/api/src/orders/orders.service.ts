import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { MovementType, OrderStatus, Prisma } from '@prisma/client';
import { Clock, CLOCK } from '../common/clock';
import { paginate, PaginationQueryDto, toSkipTake } from '../common/pagination';
import { addDays, storeDayStart } from '../common/store-time';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto, OrderItemDto } from './dto/create-order.dto';
import { ListOrdersQueryDto } from './dto/list-orders-query.dto';
import { activePromotionWhere } from '../promotions/promotion-rules';
import { orderStateOf } from './states';

const orderInclude = {
  items: {
    include: {
      product: { select: { id: true, name: true, imageUrl: true } },
    },
  },
} satisfies Prisma.OrderInclude;

/** Para el dashboard: además de las líneas, quién hizo el pedido. */
const adminOrderInclude = {
  ...orderInclude,
  customer: { select: { id: true, name: true, email: true, phone: true } },
} satisfies Prisma.OrderInclude;

@Injectable()
export class OrdersService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /**
   * Crea el pedido en PENDING_CONFIRMATION y descuenta el stock en la misma
   * transacción: si algún producto no alcanza, no se guarda nada.
   */
  create(customerId: string, dto: CreateOrderDto) {
    const quantities = mergeQuantities(dto.items);

    return this.prisma.$transaction(async (tx) => {
      // Con su promoción vigente, si tiene: el pedido se cobra a ese precio.
      const products = await tx.product.findMany({
        where: { id: { in: [...quantities.keys()] }, active: true },
        include: {
          promotions: {
            where: activePromotionWhere(this.clock.now()),
            select: { promoPrice: true },
            take: 1,
          },
        },
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
        .map(([productId, quantity]) => {
          const product = productsById.get(productId)!;
          // Precio de la promoción vigente o, si no hay, el precio normal.
          const unitPrice = product.promotions[0]?.promoPrice ?? product.price;
          return { product, quantity, unitPrice };
        });

      let total = new Prisma.Decimal(0);
      for (const { product, quantity, unitPrice } of lines) {
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
        total = total.add(unitPrice.mul(quantity));
      }

      const order = await tx.order.create({
        data: {
          customerId,
          deliveryAddress: dto.deliveryAddress,
          total,
          items: {
            create: lines.map(({ product, quantity, unitPrice }) => ({
              productId: product.id,
              quantity,
              unitPrice,
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

  /** Todos los pedidos (dashboard), opcionalmente filtrados por estado y por fecha. */
  async findAll(query: ListOrdersQueryDto) {
    const where: Prisma.OrderWhereInput = {
      status: query.status,
      createdAt: createdAtBetween(query.from, query.to),
    };
    const [data, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        include: adminOrderInclude,
        orderBy: { createdAt: 'desc' },
        ...toSkipTake(query),
      }),
      this.prisma.order.count({ where }),
    ]);
    return paginate(data, total, query);
  }

  /**
   * Cambia el estado si la transición está permitida. Al cancelar, devuelve el stock
   * que descontó el pedido y registra la entrada en el inventario, todo en una
   * transacción.
   */
  updateStatus(orderId: string, status: OrderStatus, staffUserId: string) {
    return this.prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({
        where: { id: orderId },
        include: { items: true },
      });
      if (!order) {
        throw new NotFoundException('Pedido no encontrado');
      }
      // El estado actual decide a qué estados puede pasar (patrón State, ver states/).
      const current = orderStateOf(order.status);
      if (!current.canTransitionTo(status)) {
        throw new BadRequestException(current.rejectionReason(status));
      }

      // Solo actualiza si sigue en el estado leído: si dos personas lo cambian a la
      // vez, la segunda recibe 409 en lugar de, por ejemplo, devolver stock dos veces.
      const { count } = await tx.order.updateMany({
        where: { id: orderId, status: order.status },
        data: { status },
      });
      if (count === 0) {
        throw new ConflictException(
          'El pedido cambió mientras tanto. Recarga la página.',
        );
      }

      if (status === OrderStatus.CANCELLED) {
        for (const item of order.items) {
          await tx.product.update({
            where: { id: item.productId },
            data: { currentStock: { increment: item.quantity } },
          });
        }
        await tx.inventoryMovement.createMany({
          data: order.items.map((item) => ({
            productId: item.productId,
            userId: staffUserId,
            type: MovementType.IN,
            quantity: item.quantity,
            reason: `Cancelación del pedido ${order.id}`,
          })),
        });
      }

      return tx.order.findUniqueOrThrow({
        where: { id: orderId },
        include: adminOrderInclude,
      });
    });
  }
}

/**
 * Filtro de createdAt para un rango de días de la tienda (hora de Lima), ambos incluidos.
 * Cualquiera de los dos puede faltar; sin ninguno, no filtra.
 */
function createdAtBetween(
  from?: string,
  to?: string,
): Prisma.DateTimeFilter | undefined {
  if (from && to && from > to) {
    throw new BadRequestException('from no puede ser posterior a to');
  }
  if (!from && !to) return undefined;
  return {
    ...(from && { gte: storeDayStart(from) }),
    ...(to && { lt: storeDayStart(addDays(to, 1)) }),
  };
}

/** Un mismo producto repetido en el carrito se suma en una sola línea. */
function mergeQuantities(items: OrderItemDto[]): Map<string, number> {
  const quantities = new Map<string, number>();
  for (const { productId, quantity } of items) {
    quantities.set(productId, (quantities.get(productId) ?? 0) + quantity);
  }
  return quantities;
}
