import type { Promotion as PromotionResponse } from '@abarrotes/shared-types';
import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Clock, CLOCK } from '../common/clock';
import { paginate, toSkipTake } from '../common/pagination';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreatePromotionDto,
  ListPromotionsQueryDto,
  UpdatePromotionDto,
} from './dto/promotion.dto';
import {
  promotionStatus,
  promotionStatusWhere,
  toDayPeriod,
  toStoredPeriod,
} from './promotion-rules';

const promotionInclude = {
  product: { select: { id: true, name: true, sku: true, price: true } },
} satisfies Prisma.PromotionInclude;

type PromotionWithProduct = Prisma.PromotionGetPayload<{
  include: typeof promotionInclude;
}>;

@Injectable()
export class PromotionsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /** Promociones del dashboard, las de inicio más reciente primero. */
  async findAll(query: ListPromotionsQueryDto) {
    const now = this.clock.now();
    const where: Prisma.PromotionWhereInput = {
      productId: query.productId,
      ...(query.status && promotionStatusWhere(query.status, now)),
    };
    const [data, total] = await Promise.all([
      this.prisma.promotion.findMany({
        where,
        include: promotionInclude,
        orderBy: [{ startDate: 'desc' }, { id: 'desc' }],
        ...toSkipTake(query),
      }),
      this.prisma.promotion.count({ where }),
    ]);
    return paginate(
      data.map((promotion) => this.toResponse(promotion, now)),
      total,
      query,
    );
  }

  async findOne(id: string) {
    return this.toResponse(await this.getOrThrow(id), this.clock.now());
  }

  async create(dto: CreatePromotionDto) {
    const product = await this.prisma.product.findUnique({
      where: { id: dto.productId },
      select: { id: true, name: true, price: true },
    });
    if (!product) {
      throw new BadRequestException('El producto indicado no existe');
    }
    const period = { startDate: dto.startDate, endDate: dto.endDate };
    const active = dto.active ?? true;
    await this.validate(product, dto.promoPrice, period, active);

    const created = await this.prisma.promotion.create({
      data: {
        productId: product.id,
        promoPrice: dto.promoPrice,
        active,
        ...toStoredPeriod(period),
      },
      include: promotionInclude,
    });
    return this.toResponse(created, this.clock.now());
  }

  async update(id: string, dto: UpdatePromotionDto) {
    const current = await this.getOrThrow(id);
    // Se valida la promoción tal como quedaría con los cambios.
    const period = { ...toDayPeriod(current), ...pickPeriod(dto) };
    const promoPrice = dto.promoPrice ?? current.promoPrice.toNumber();
    const active = dto.active ?? current.active;
    await this.validate(current.product, promoPrice, period, active, id);

    const updated = await this.prisma.promotion.update({
      where: { id },
      data: { promoPrice, active, ...toStoredPeriod(period) },
      include: promotionInclude,
    });
    return this.toResponse(updated, this.clock.now());
  }

  /** Borra la promoción. Los pedidos guardan su precio, así que no se ven afectados. */
  async remove(id: string) {
    await this.getOrThrow(id);
    await this.prisma.promotion.delete({ where: { id } });
  }

  /**
   * Reglas de negocio:
   * - El último día no puede ser anterior al primero.
   * - El precio promocional tiene que ser menor al precio normal.
   * - Dos promociones encendidas del mismo producto no pueden cruzarse en el tiempo; si
   *   no, no habría un único precio vigente para cobrar.
   */
  private async validate(
    product: { id: string; name: string; price: Prisma.Decimal },
    promoPrice: number,
    period: { startDate: string; endDate: string },
    active: boolean,
    exceptId?: string,
  ) {
    if (period.endDate < period.startDate) {
      throw new BadRequestException(
        'endDate no puede ser anterior a startDate',
      );
    }
    if (new Prisma.Decimal(promoPrice).gte(product.price)) {
      throw new BadRequestException(
        `El precio promocional debe ser menor al precio normal (${product.price.toString()})`,
      );
    }
    if (!active) return;

    const { startDate, endDate } = toStoredPeriod(period);
    const overlapping = await this.prisma.promotion.findFirst({
      where: {
        productId: product.id,
        active: true,
        startDate: { lt: endDate },
        endDate: { gt: startDate },
        ...(exceptId && { id: { not: exceptId } }),
      },
      select: { startDate: true, endDate: true },
    });
    if (overlapping) {
      const days = toDayPeriod(overlapping);
      throw new ConflictException(
        `${product.name} ya tiene una promoción del ${days.startDate} al ${days.endDate} que se cruza con esas fechas`,
      );
    }
  }

  private async getOrThrow(id: string) {
    const promotion = await this.prisma.promotion.findUnique({
      where: { id },
      include: promotionInclude,
    });
    if (!promotion) {
      throw new NotFoundException('Promoción no encontrada');
    }
    return promotion;
  }

  private toResponse(
    promotion: PromotionWithProduct,
    now: Date,
  ): PromotionResponse {
    return {
      id: promotion.id,
      productId: promotion.productId,
      product: {
        id: promotion.product.id,
        name: promotion.product.name,
        sku: promotion.product.sku,
        price: promotion.product.price.toString(),
      },
      promoPrice: promotion.promoPrice.toString(),
      ...toDayPeriod(promotion),
      active: promotion.active,
      status: promotionStatus(promotion, now),
    };
  }
}

/** Solo las fechas que vienen en el PATCH. */
function pickPeriod(dto: UpdatePromotionDto) {
  return {
    ...(dto.startDate !== undefined && { startDate: dto.startDate }),
    ...(dto.endDate !== undefined && { endDate: dto.endDate }),
  };
}
