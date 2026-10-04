import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { paginate, toSkipTake } from '../common/pagination';
import { PrismaService } from '../prisma/prisma.service';
import { ListMovementsQueryDto } from './dto/list-movements-query.dto';

/** Lo que el dashboard muestra de cada movimiento: sin datos sensibles del usuario. */
const movementSelect = {
  id: true,
  type: true,
  quantity: true,
  reason: true,
  createdAt: true,
  product: { select: { id: true, name: true, sku: true } },
  user: { select: { id: true, name: true } },
} satisfies Prisma.InventoryMovementSelect;

@Injectable()
export class InventoryService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Historial de movimientos de stock, del más reciente al más antiguo. Con productId,
   * solo los de ese producto (404 si no existe).
   */
  async findMovements(query: ListMovementsQueryDto) {
    if (query.productId) {
      const product = await this.prisma.product.findUnique({
        where: { id: query.productId },
        select: { id: true },
      });
      if (!product) {
        throw new NotFoundException('Producto no encontrado');
      }
    }

    const where: Prisma.InventoryMovementWhereInput = {
      productId: query.productId,
    };
    const [data, total] = await Promise.all([
      this.prisma.inventoryMovement.findMany({
        where,
        select: movementSelect,
        // Un pedido registra todas sus salidas a la vez: el id desempata para que
        // la paginación no repita ni salte movimientos con la misma fecha.
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        ...toSkipTake(query),
      }),
      this.prisma.inventoryMovement.count({ where }),
    ]);
    return paginate(data, total, query);
  }
}
